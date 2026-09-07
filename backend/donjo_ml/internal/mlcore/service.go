package mlcore

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math"
	"sort"
	"strings"
	"time"
)

// ModelVersion is stamped into every embedding row and recommendation cache
// entry; bump it any time EventSparse or the scoring weights change so stale
// rows are recomputed.
const ModelVersion = "v1"

// interaction weights drive how strongly each behaviour shapes the profile.
var interactionWeights = map[string]float64{
	"view":     1,
	"click":    1,
	"save":     4,
	"share":    3,
	"like":     3,
	"purchase": 5,
}

var (
	ErrEventNotFound = errors.New("event embedding not found")
	ErrUserNotFound  = errors.New("user profile not found")
	ErrInteracted    = errors.New("interaction could not be recorded")
)

// MLService owns the SQLite model database and implements every ML operation
// invoked by the message consumer and the HTTP API.
type MLService struct {
	db  *sql.DB
	log *log.Logger
}

// New wires an MLService onto an already-migrated SQLite handle.
func New(db *sql.DB) *MLService {
	return &MLService{db: db, log: log.New(log.Writer(), "[ml] ", log.LstdFlags)}
}

func (s *MLService) now() string { return time.Now().UTC().Format(time.RFC3339) }

func (s *MLService) logf(format string, args ...interface{}) {
	s.log.Printf(format, args...)
}

// ---------------------------------------------------------------------------
// Event catalogue ingestion (from donjo.events)
// ---------------------------------------------------------------------------

// UpsertEvent ingests event.created/updated. The full event document is stored
// so recommendations can render without calling donjo_event; the feature
// vector is (re)computed from the document and its venue.
func (s *MLService) UpsertEvent(in interface{}) error {
	ev, err := decodeEvent(in)
	if err != nil {
		return err
	}
	if ev.ID == "" {
		s.logf("upsert event: skipping message with empty event id")
		return nil
	}

	payload, err := json.Marshal(ev)
	if err != nil {
		return fmt.Errorf("encode event payload: %w", err)
	}

	venue, _ := s.Venue(ev.VenueID)
	sparse := EventSparse(ev, venue)
	embedding := Dense(sparse)
	embJSON, err := encodeDense(embedding)
	if err != nil {
		return err
	}
	sparseJSON, err := encodeSparse(sparse)
	if err != nil {
		return err
	}

	pop := Popularity(ev)
	_, err = s.db.Exec(`
		INSERT INTO event_embeddings
			(id, event_id, embedding_vector, feature_vector, similar_events,
			 feature_version, last_calculated_at, updated_at,
			 payload_json, popularity, is_published, status,
			 start_time, end_time, city, category)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(event_id) DO UPDATE SET
			embedding_vector = excluded.embedding_vector,
			feature_vector = excluded.feature_vector,
			feature_version = excluded.feature_version,
			payload_json = excluded.payload_json,
			popularity = excluded.popularity,
			is_published = excluded.is_published,
			status = excluded.status,
			start_time = excluded.start_time,
			end_time = excluded.end_time,
			city = excluded.city,
			category = excluded.category,
			last_calculated_at = excluded.last_calculated_at,
			updated_at = excluded.updated_at`,
		ev.ID, ev.ID, embJSON, sparseJSON, "[]",
		FeatureVersion, s.now(), s.now(),
		string(payload), pop, boolInt(ev.IsPublished), ev.Status,
		rfc3339(ev.StartTime), rfc3339(ev.EndTime), ev.City, ev.Category,
	)
	if err != nil {
		return fmt.Errorf("upsert event embedding: %w", err)
	}
	s.logf("event %s (%s) -> embedding updated", ev.ID, ev.Title)
	return nil
}

// DeleteEvent removes an event embedding and its interactions on event.deleted.
func (s *MLService) DeleteEvent(eventID string) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	for _, q := range []string{
		`DELETE FROM event_embeddings WHERE event_id = ?`,
		`UPDATE user_interactions SET event_id = NULL WHERE event_id = ?`,
	} {
		if _, err := tx.Exec(q, eventID); err != nil {
			return fmt.Errorf("delete event %s: %w", eventID, err)
		}
	}
	if err := tx.Commit(); err != nil {
		return err
	}
	s.logf("event %s deleted", eventID)
	return nil
}

// MarkEventPublished handles event.published (a light payload) by flipping the
// event's publish flag so it can begin appearing in recommendations.
func (s *MLService) MarkEventPublished(eventID string) error {
	since := s.now()
	res, err := s.db.Exec(`
		UPDATE event_embeddings
		SET is_published = 1, status = 'published', updated_at = ?
		WHERE event_id = ? AND is_published = 0`, since, eventID)
	if err != nil {
		return fmt.Errorf("mark event published: %w", err)
	}
	n, _ := res.RowsAffected()
	if n > 0 {
		s.logf("event %s marked published", eventID)
	}
	return nil
}

// UpsertVenue stores venue documents so events can be feature-augmented.
func (s *MLService) UpsertVenue(in interface{}) error {
	v, err := decodeVenue(in)
	if err != nil {
		return err
	}
	if v.ID == "" {
		s.logf("upsert venue: skipping message with empty venue id")
		return nil
	}
	payload, err := json.Marshal(v)
	if err != nil {
		return err
	}
	_, err = s.db.Exec(`
		INSERT INTO venue_docs
			(venue_id, name, slug, venue_type, venue_category, address, city,
			 county, country, capacity, status, payload_json, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(venue_id) DO UPDATE SET
			name = excluded.name, slug = excluded.slug,
			venue_type = excluded.venue_type, venue_category = excluded.venue_category,
			address = excluded.address, city = excluded.city, county = excluded.county,
			country = excluded.country, capacity = excluded.capacity,
			status = excluded.status, payload_json = excluded.payload_json,
			updated_at = excluded.updated_at`,
		v.ID, v.Name, v.Slug, v.VenueType, v.VenueCategory, v.Address, v.City,
		v.County, v.Country, v.Capacity, v.Status, string(payload), s.now(),
	)
	if err != nil {
		return fmt.Errorf("upsert venue doc: %w", err)
	}
	s.logf("venue %s (%s) stored", v.ID, v.Name)
	return nil
}

// UpsertTicket merges a flat ticket.type.created/updated payload into the
// stored event document and re-vectorises the event.
func (s *MLService) UpsertTicket(in interface{}) error {
	t, err := decodeTicket(in)
	if err != nil {
		return err
	}
	if t.ID == "" || t.EventID == "" {
		s.logf("upsert ticket: skipping malformed message (id=%q event_id=%q)", t.ID, t.EventID)
		return nil
	}

	ev, err := s.Event(t.EventID)
	if err != nil {
		s.logf("upsert ticket %s: event %s not seen yet (%v)", t.ID, t.EventID, err)
		return nil
	}

	merged := false
	for i, ot := range ev.Tickets {
		if ot != nil && ot.ID == t.ID {
			ev.Tickets[i] = t
			merged = true
			break
		}
	}
	if !merged {
		ev.Tickets = append(ev.Tickets, t)
	}
	return s.UpsertEvent(ev)
}

// ---------------------------------------------------------------------------
// Purchases -> training signal
// ---------------------------------------------------------------------------

// OnPurchase handles ticket.purchased. The buyer's profile is strengthened the
// same way a weighted interaction is, the event's popularity rises, and both
// embeddings are recalculated (incremental retrain).
func (s *MLService) OnPurchase(in interface{}) error {
	p, err := decodePurchase(in)
	if err != nil {
		return err
	}
	if p.UserID == "" {
		s.logf("purchase: user_id missing, skipping purchase signal")
		return nil
	}

	if p.Quantity < 1 {
		p.Quantity = 1
	}
	if err := s.RecordInteraction(p.UserID, InteractionIn{
		EventID:         p.EventID,
		InteractionType: "purchase",
		Weight:          int(interactionWeights["purchase"]) * p.Quantity,
		DeviceType:      "system",
	}); err != nil {
		return err
	}

	popBump := p.UnitPrice * float64(p.Quantity) / 1000.0
	_, err = s.db.Exec(`
		UPDATE event_embeddings SET popularity = popularity + ?, updated_at = ?
		WHERE event_id = ?`,
		popBump, s.now(), p.EventID)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return fmt.Errorf("bump event popularity: %w", err)
	}
	s.logf("purchase signal: user %s x%d of %s reinforced", p.UserID, p.Quantity, p.EventID)
	return nil
}

// ---------------------------------------------------------------------------
// Interactions
// ---------------------------------------------------------------------------

// RecordInteraction persists a user behaviour and rebuilds the user's profile
// from its full interaction history (cheap at dev scale, drift-free).
func (s *MLService) RecordInteraction(userID string, in InteractionIn) error {
	typ := strings.ToLower(strings.TrimSpace(in.InteractionType))
	if typ == "" {
		typ = "view"
	}
	base := interactionWeights[typ]
	weight := in.Weight
	if weight <= 0 || base == 0 {
		weight = 1
	}
	if base > 0 {
		weight = int(float64(weight) * base)
	}
	if weight < 1 {
		weight = 1
	}

	data, _ := json.Marshal(in)
	_, err := s.db.Exec(`
		INSERT INTO user_interactions
			(id, user_id, event_id, venue_id, interaction_type, interaction_weight,
			 interaction_data, session_id, timestamp, duration_seconds, position,
			 device_type, location, ip_address, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		newID(), userID, orNull(in.EventID), orNull(in.VenueID), typ, weight,
		string(data), orNull(in.SessionID), s.now(), orNullI(in.DurationSeconds),
		orNullI(in.Position), orNull(in.DeviceType), orNull(in.IPAddress),
		orNull(in.IPAddress), s.now(),
	)
	if err != nil {
		return fmt.Errorf("%w: %v", ErrInteracted, err)
	}
	return s.rebuildUser(userID)
}

// rebuildUser recomputes a user's profile from user_interactions. Event
// feature vectors are cached on event_embeddings, so this is a weighted sum.
func (s *MLService) rebuildUser(userID string) error {
	rows, err := s.db.Query(`
		SELECT event_id, venue_id, interaction_type, interaction_weight, duration_seconds
		FROM user_interactions WHERE user_id = ? AND event_id IS NOT NULL`, userID)
	if err != nil {
		return fmt.Errorf("load interactions: %w", err)
	}
	defer rows.Close()

	sparse := Sparse{}
	catWeights := map[string]float64{}
	venueWeights := map[string]float64{}
	timeWeights := map[string]float64{}
	count := 0

	for rows.Next() {
		var eventID, venueID, typ sql.NullString
		var weight int
		var dur sql.NullInt64
		if err := rows.Scan(&eventID, &venueID, &typ, &weight, &dur); err != nil {
			return err
		}
		if !eventID.Valid || eventID.String == "" {
			continue
		}
		count++
		w := float64(weight)
		ev, evErr := s.loadEventSparse(eventID.String)
		if evErr == nil && ev.sparse != nil {
			SparseAdd(sparse, ev.sparse, w)
		}
		if ev.payload != nil {
			if c := ev.payload.Category; c != "" {
				catWeights[c] += w
			}
			if v := ev.payload.VenueID; v != "" {
				venueWeights[v] += w
			}
			for _, tf := range timeTokens(ev.payload.StartTime) {
				timeWeights[tf] += w
			}
		}
	}
	if err := rows.Err(); err != nil {
		return err
	}

	profile := &UserProfile{
		UserID:              userID,
		Embedding:           Dense(sparse),
		FeatureVector:       sparse,
		CategoryWeights:     catWeights,
		PreferredVenues:     venueWeights,
		PreferredTimes:      timeWeights,
		PreferredCategories: topKeys(catWeights, 5),
		FeatureVersion:      FeatureVersion,
		InteractionCount:    count,
		LastCalculatedAt:    s.now(),
		LastUpdatedAt:       s.now(),
	}
	return s.storeUser(profile)
}

// storeUser upserts a completed user profile.
func (s *MLService) storeUser(p *UserProfile) error {
	emb, err := encodeDense(p.Embedding)
	if err != nil {
		return err
	}
	sparse, err := encodeSparse(p.FeatureVector)
	if err != nil {
		return err
	}
	cats, _ := json.Marshal(p.CategoryWeights)
	prefCats, _ := json.Marshal(p.PreferredCategories)
	prefVenues, _ := json.Marshal(p.PreferredVenues)
	prefTimes, _ := json.Marshal(p.PreferredTimes)

	_, err = s.db.Exec(`
		INSERT INTO user_embeddings
			(id, user_id, embedding_vector, category_weights, feature_vector,
			 feature_version, preferred_categories, preferred_venues, preferred_times,
			 interaction_count, last_updated_at, last_calculated_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(user_id) DO UPDATE SET
			embedding_vector = excluded.embedding_vector,
			category_weights = excluded.category_weights,
			feature_vector = excluded.feature_vector,
			feature_version = excluded.feature_version,
			preferred_categories = excluded.preferred_categories,
			preferred_venues = excluded.preferred_venues,
			preferred_times = excluded.preferred_times,
			interaction_count = excluded.interaction_count,
			last_updated_at = excluded.last_updated_at,
			last_calculated_at = excluded.last_calculated_at,
			updated_at = excluded.updated_at`,
		p.UserID, p.UserID, emb, string(cats), sparse,
		p.FeatureVersion, string(prefCats), string(prefVenues), string(prefTimes),
		p.InteractionCount, s.now(), s.now(), s.now(),
	)
	if err != nil {
		return fmt.Errorf("store user profile: %w", err)
	}
	return nil
}

// Profile returns the stored profile for a user.
func (s *MLService) Profile(userID string) (*UserProfile, error) {
	row := s.db.QueryRow(`SELECT user_id, embedding_vector, category_weights,
		feature_vector, preferred_categories, preferred_venues, preferred_times,
		feature_version, interaction_count, last_calculated_at, last_updated_at
		FROM user_embeddings WHERE user_id = ?`, userID)

	p := &UserProfile{PreferredVenues: map[string]float64{}, PreferredTimes: map[string]float64{}}
	var emb, cats, sparse, prefCats, prefVenues, prefTimes sql.NullString
	if err := row.Scan(&p.UserID, &emb, &cats, &sparse, &prefCats, &prefVenues,
		&prefTimes, &p.FeatureVersion, &p.InteractionCount,
		&p.LastCalculatedAt, &p.LastUpdatedAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	p.Embedding, _ = decodeDense(emb.String)
	p.FeatureVector, _ = decodeSparse(sparse.String)
	_ = json.Unmarshal([]byte(cats.String), &p.CategoryWeights)
	_ = json.Unmarshal([]byte(prefCats.String), &p.PreferredCategories)
	_ = json.Unmarshal([]byte(prefVenues.String), &p.PreferredVenues)
	_ = json.Unmarshal([]byte(prefTimes.String), &p.PreferredTimes)
	if p.PreferredVenues == nil {
		p.PreferredVenues = map[string]float64{}
	}
	if p.PreferredTimes == nil {
		p.PreferredTimes = map[string]float64{}
	}
	return p, nil
}

// ---------------------------------------------------------------------------
// Event reads
// ---------------------------------------------------------------------------

// Event returns the stored (denormalised) catalogue document for an event.
func (s *MLService) Event(eventID string) (*EventDoc, error) {
	var payload string
	err := s.db.QueryRow(
		`SELECT payload_json FROM event_embeddings WHERE event_id = ?`, eventID,
	).Scan(&payload)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrEventNotFound
		}
		return nil, fmt.Errorf("load event %s: %w", eventID, err)
	}
	var ev EventDoc
	if err := json.Unmarshal([]byte(payload), &ev); err != nil {
		return nil, err
	}
	return &ev, nil
}

// Venue returns a stored venue document (nil when unknown).
func (s *MLService) Venue(venueID string) (*VenueDoc, error) {
	if venueID == "" {
		return nil, ErrEventNotFound
	}
	var raw string
	err := s.db.QueryRow(
		`SELECT payload_json FROM venue_docs WHERE venue_id = ?`, venueID,
	).Scan(&raw)
	if err != nil {
		return nil, ErrEventNotFound
	}
	var v VenueDoc
	if err := json.Unmarshal([]byte(raw), &v); err != nil {
		return nil, err
	}
	return &v, nil
}

// eventModel is a loaded event embedding plus its decoded payload and sparse
// vector, used by rebuild/User recommendations.
type eventModel struct {
	eventID   string
	embedding []float64
	sparse    Sparse
	payload   *EventDoc
	pop       float64
	published bool
	startTime time.Time
	endTime   time.Time
}

func (s *MLService) loadEventSparse(eventID string) (*eventModel, error) {
	var emb, sparse, payload, startT string
	var pop float64
	var published int
	err := s.db.QueryRow(`
		SELECT event_id, embedding_vector, feature_vector, payload_json,
		       popularity, is_published, start_time
		FROM event_embeddings WHERE event_id = ?`, eventID,
	).Scan(&emb, &sparse, &payload, &pop, &published, &startT)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrEventNotFound
		}
		return nil, err
	}
	em := &eventModel{
		eventID:   eventID,
		embedding: mustDense(emb),
		sparse:    mustSparse(sparse),
		pop:       pop,
		published: published == 1,
		startTime: parseTime(startT),
	}
	_ = json.Unmarshal([]byte(payload), &em.payload)
	return em, nil
}

// SimilarEvents computes (and caches) the nearest neighbours of an event using
// cosine similarity on the embedding space.
func (s *MLService) SimilarEvents(eventID string, limit int) ([]SimilarEvent, error) {
	if limit <= 0 {
		limit = 8
	}
	if limit > 20 {
		limit = 20
	}
	target, err := s.loadEventSparse(eventID)
	if err != nil {
		return nil, err
	}
	if target.embedding == nil {
		return []SimilarEvent{}, nil
	}

	rows, err := s.db.Query(`
		SELECT event_id, embedding_vector, payload_json
		FROM event_embeddings WHERE event_id != ? AND is_published = 1`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	type cand struct {
		sim   SimilarEvent
		title string
	}
	var all []cand
	for rows.Next() {
		var id, emb, payload string
		if err := rows.Scan(&id, &emb, &payload); err != nil {
			return nil, err
		}
		d := mustDense(emb)
		score := Cosine(target.embedding, d)
		var ev EventDoc
		_ = json.Unmarshal([]byte(payload), &ev)
		all = append(all, cand{SimilarEvent{
			EventID: id, Title: ev.Title, Slug: ev.Slug, Score: score,
		}, ev.Title})
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	sort.Slice(all, func(i, j int) bool {
		if all[i].sim.Score == all[j].sim.Score {
			return all[i].title < all[j].title
		}
		return all[i].sim.Score > all[j].sim.Score
	})
	if len(all) > limit {
		all = all[:limit]
	}
	out := make([]SimilarEvent, 0, len(all))
	for _, c := range all {
		out = append(out, c.sim)
	}
	simJSON, _ := json.Marshal(out)
	_, err = s.db.Exec(`UPDATE event_embeddings SET similar_events = ?, updated_at = ? WHERE event_id = ?`,
		string(simJSON), s.now(), eventID)
	return out, err
}

// ---------------------------------------------------------------------------
// Recommendations
// ---------------------------------------------------------------------------

// RecommendationType is the feed flavour requested.
const (
	RecUpcoming = "upcoming"
	RecTrending = "trending"
)

// Recommendations serves a personalised feed for a user, reading from the
// recommendations_cache first. Cold-start users receive popular published
// events. Every call is logged to ai_queries.
func (s *MLService) Recommendations(userID, typ string, limit int) (*RecResult, error) {
	if typ == "" {
		typ = RecUpcoming
	}
	if typ != RecUpcoming && typ != RecTrending {
		typ = RecUpcoming
	}
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	started := time.Now()
	if cached, ok := s.cachedRecommendations(userID, typ, limit); ok {
		return cached, nil
	}

	profile, _ := s.Profile(userID)
	var items []RecItem

	if profile == nil || len(profile.Embedding) == 0 {
		items = s.coldStart(typ, limit)
	} else {
		items = s.scoreCandidates(userID, profile, typ, limit)
	}

	res := &RecResult{
		ModelVersion: ModelVersion,
		Type:         typ,
		UserID:       userID,
		Items:        items,
	}
	s.cacheRecommendations(userID, typ, res)
	s.logQuery(userID, "feed", typ, items, started)

	return res, nil
}

// coldStart: no profile yet -> most popular published events.
func (s *MLService) coldStart(typ string, limit int) []RecItem {
	q := `SELECT event_id, embedding_vector, payload_json, popularity, start_time
	      FROM event_embeddings WHERE is_published = 1`
	if typ == RecUpcoming {
		q += ` AND start_time >= ?`
	}
	q += ` ORDER BY popularity DESC`
	args := []interface{}{}
	if typ == RecUpcoming {
		args = append(args, s.now())
	}
	rows, err := s.db.Query(q, args...)
	if err != nil {
		s.logf("cold start query failed: %v", err)
		return []RecItem{}
	}
	defer rows.Close()

	var out []RecItem
	for rows.Next() {
		var id, emb, payload, startT string
		var pop float64
		if err := rows.Scan(&id, &emb, &payload, &pop, &startT); err != nil {
			continue
		}
		if startT == "" || parseTime(startT).Before(time.Now()) {
			continue
		}
		var ev EventDoc
		if err := json.Unmarshal([]byte(payload), &ev); err != nil {
			continue
		}
		out = append(out, RecItem{
			EventID: id,
			Score:   normalizeScore(pop),
			Reasons: []string{"Trending now"},
			Event:   &ev,
		})
		if len(out) >= limit {
			break
		}
	}
	return out
}

// scoreCandidates ranks published events against the user's embedding.
func (s *MLService) scoreCandidates(userID string, profile *UserProfile, typ string, limit int) []RecItem {
	excluded := s.interactedEvents(userID)

	q := `SELECT event_id, embedding_vector, payload_json, popularity, start_time, category
	      FROM event_embeddings WHERE is_published = 1`
	if typ == RecUpcoming {
		q += ` AND start_time >= ?`
	}
	args := []interface{}{}
	if typ == RecUpcoming {
		args = append(args, s.now())
	}
	rows, err := s.db.Query(q, args...)
	if err != nil {
		s.logf("score candidates query failed: %v", err)
		return []RecItem{}
	}
	defer rows.Close()

	type scored struct {
		item  RecItem
		title string
		start time.Time
	}
	var list []scored
	for rows.Next() {
		var id, emb, payload, startT, category string
		var pop float64
		if err := rows.Scan(&id, &emb, &payload, &pop, &startT, &category); err != nil {
			continue
		}
		if excluded[id] {
			continue
		}
		start := parseTime(startT)
		if start.IsZero() || start.Before(time.Now()) {
			continue
		}
		var ev EventDoc
		if err := json.Unmarshal([]byte(payload), &ev); err != nil {
			continue
		}
		cos := Cosine(profile.Embedding, mustDense(emb))
		score := cos
		if w, ok := profile.CategoryWeights[ev.Category]; ok && w > 0 && cos > 0 {
			score = cos * (1 + math.Min(0.5, w/10.0))
		}
		// slight popularity tie-break, never allowed to dominate content fit
		score += normalizeScore(pop) * 0.1
		list = append(list, scored{
			item: RecItem{
				EventID: id,
				Score:   score,
				Reasons: profile.ReasonsFor(&ev),
				Event:   &ev,
			},
			title: ev.Title,
			start: start,
		})
	}
	if err := rows.Err(); err != nil {
		s.logf("score candidates read failed: %v", err)
	}

	sort.Slice(list, func(i, j int) bool {
		if list[i].item.Score == list[j].item.Score {
			return list[i].title < list[j].title
		}
		return list[i].item.Score > list[j].item.Score
	})
	if len(list) > limit {
		list = list[:limit]
	}
	out := make([]RecItem, 0, len(list))
	for _, e := range list {
		out = append(out, e.item)
	}
	return out
}

// interactedEvents returns the set of events the user has already engaged with.
func (s *MLService) interactedEvents(userID string) map[string]bool {
	rows, err := s.db.Query(`SELECT DISTINCT event_id FROM user_interactions
		WHERE user_id = ? AND event_id IS NOT NULL AND event_id != ''`, userID)
	if err != nil {
		return map[string]bool{}
	}
	defer rows.Close()
	out := map[string]bool{}
	var id string
	for rows.Next() {
		if err := rows.Scan(&id); err == nil && id != "" {
			out[id] = true
		}
	}
	return out
}

// ReasonsFor maps the user's learned preferences onto a candidate event.
func (p *UserProfile) ReasonsFor(ev *EventDoc) []string {
	var out []string
	if w := p.CategoryWeights[ev.Category]; w > 0 {
		out = append(out, fmt.Sprintf("Matches your %s interest", ev.Category))
	}
	if w := p.PreferredVenues[ev.VenueID]; w > 0 {
		out = append(out, "At a venue you like")
	}
	if _, ok := p.PreferredTimes["time:weekend"]; ok && isWeekend(ev.StartTime) {
		out = append(out, "Happening on a weekend")
	}
	if len(out) == 0 {
		out = append(out, "Based on your activity")
	}
	if len(out) > 3 {
		out = out[:3]
	}
	return out
}

// ---------------------------------------------------------------------------
// Cache + query log
// ---------------------------------------------------------------------------

const cacheTTL = 5 * time.Minute

func (s *MLService) cachedRecommendations(userID, typ string, limit int) (*RecResult, bool) {
	var results, expires string
	err := s.db.QueryRow(`
		SELECT results, expires_at FROM recommendations_cache
		WHERE user_id = ? AND type = ? AND expires_at > ?`,
		userID, typ, s.now(),
	).Scan(&results, &expires)
	if err != nil {
		return nil, false
	}
	var res RecResult
	if err := json.Unmarshal([]byte(results), &res); err != nil {
		return nil, false
	}
	if len(res.Items) > limit {
		res.Items = res.Items[:limit]
	}
	// cache is empty -> still a hit, but never serve an empty personalised feed
	if len(res.Items) == 0 && typ == RecUpcoming {
		return nil, false
	}
	return &res, true
}

func (s *MLService) cacheRecommendations(userID, typ string, res *RecResult) {
	results, _ := json.Marshal(res)
	_, err := s.db.Exec(`
		INSERT INTO recommendations_cache
			(id, user_id, type, results, model_version, expires_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(user_id, type) DO UPDATE SET
			results = excluded.results,
			model_version = excluded.model_version,
			expires_at = excluded.expires_at,
			updated_at = excluded.updated_at`,
		newID(), userID, typ, string(results), ModelVersion,
		time.Now().UTC().Add(cacheTTL).Format(time.RFC3339), s.now(),
	)
	if err != nil {
		s.logf("cache recommendations: %v", err)
	}
}

func (s *MLService) logQuery(userID, queryType, queryText string, items []RecItem, started time.Time) {
	ms := time.Since(started).Milliseconds()
	ids := make([]string, 0, len(items))
	for _, it := range items {
		ids = append(ids, it.EventID)
	}
	results, _ := json.Marshal(ids)
	_, err := s.db.Exec(`
		INSERT INTO ai_queries
			(id, user_id, query_type, query_text, result_count, results,
			 response_time_ms, timestamp, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		newID(), orNull(userID), queryType, orNull(queryText), len(ids),
		string(results), ms, s.now(), s.now(),
	)
	if err != nil {
		s.logf("log query: %v", err)
	}
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

func Popularity(ev *EventDoc) float64 {
	if ev == nil {
		return 0
	}
	return 0.35*float64(ev.Views) +
		1.2*float64(ev.Likes) +
		1.8*float64(ev.Shares) +
		1.4*float64(ev.TicketsSold) +
		ev.Revenue/500.0
}

func normalizeScore(x float64) float64 {
	if x <= 0 {
		return 0
	}
	return math.Min(1, math.Log1p(x)/5.0)
}

func topKeys(m map[string]float64, n int) []string {
	if len(m) == 0 {
		return nil
	}
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Slice(keys, func(i, j int) bool {
		if m[keys[i]] == m[keys[j]] {
			return keys[i] < keys[j]
		}
		return m[keys[i]] > m[keys[j]]
	})
	if len(keys) > n {
		keys = keys[:n]
	}
	return keys
}

func isWeekend(t time.Time) bool {
	d := t.UTC().Weekday()
	return d == time.Saturday || d == time.Sunday
}

func boolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

func rfc3339(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.UTC().Format(time.RFC3339)
}

func parseTime(s string) time.Time {
	if s == "" {
		return time.Time{}
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		return time.Time{}
	}
	return t
}

func mustDense(raw string) []float64 {
	d, err := decodeDense(raw)
	if err != nil {
		return nil
	}
	return d
}

func mustSparse(raw string) Sparse {
	s, err := decodeSparse(raw)
	if err != nil {
		return nil
	}
	return s
}

func orNull(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

func orNullI(i int) interface{} {
	if i == 0 {
		return nil
	}
	return i
}

// decodeEvent tolerates both the flat Event model and an {event: ...} wrapper.
func decodeEvent(in interface{}) (*EventDoc, error) {
	switch v := in.(type) {
	case *EventDoc:
		return v, nil
	case EventDoc:
		c := v
		return &c, nil
	case []byte:
		ev := &EventDoc{}
		if err := json.Unmarshal(v, ev); err != nil {
			return nil, err
		}
		return ev, nil
	case string:
		return decodeEvent([]byte(v))
	default:
		b, err := json.Marshal(in)
		if err != nil {
			return nil, fmt.Errorf("encode event input: %w", err)
		}
		return decodeEvent(b)
	}
}

func decodeVenue(in interface{}) (*VenueDoc, error) {
	b, err := json.Marshal(in)
	if err != nil {
		return nil, err
	}
	v := &VenueDoc{}
	return v, json.Unmarshal(b, v)
}

func decodeTicket(in interface{}) (*TicketDoc, error) {
	b, err := json.Marshal(in)
	if err != nil {
		return nil, err
	}
	t := &TicketDoc{}
	return t, json.Unmarshal(b, t)
}

func decodePurchase(in interface{}) (*PurchaseIn, error) {
	b, err := json.Marshal(in)
	if err != nil {
		return nil, err
	}
	p := &PurchaseIn{}
	return p, json.Unmarshal(b, p)
}
