package mlcore

import (
	"encoding/json"
	"fmt"
	"hash/fnv"
	"math"
	"regexp"
	"strings"
	"time"
)

// EmbeddingDim matches the VECTOR(128) dimension of the original Postgres
// schema. Content vectors live in this fixed space via feature hashing, so
// events and users map to the same space without a shared dictionary.
const EmbeddingDim = 128

// Sparse is a sparse weight vector (index -> accumulated weight). It is what
// feature_vector stores: cheap to add (user profiles are weighted sums of
// event feature vectors) and cheap to re-normalise into a dense embedding.
type Sparse map[int]float64

var nonWord = regexp.MustCompile(`[^a-z0-9]+`)

func hashToken(tok string) uint64 {
	h := fnv.New64a()
	_, _ = h.Write([]byte(tok))
	return h.Sum64()
}

// addToken accumulates tok*weight into a sparse vector. The hash's high bit
// picks the sign, so token order never matters (stable across restarts).
func addToken(v Sparse, tok string, weight float64) {
	h := hashToken(tok)
	idx := int(h % EmbeddingDim)
	sign := 1.0
	if h&0x8000000000000000 != 0 {
		sign = -1.0
	}
	v[idx] += sign * weight
}

// Dense materialises a sparse vector into a fixed-size, L2-normalised array.
// An empty sparse vector becomes a zero vector.
func Dense(s Sparse) []float64 {
	out := make([]float64, EmbeddingDim)
	for i, w := range s {
		if i >= 0 && i < EmbeddingDim {
			out[i] = w
		}
	}
	Normalize(out)
	return out
}

// Normalize L2-normalises v in place.
func Normalize(v []float64) {
	var sum float64
	for _, x := range v {
		sum += x * x
	}
	if sum == 0 {
		return
	}
	inv := 1 / math.Sqrt(sum)
	for i := range v {
		v[i] *= inv
	}
}

// Cosine computes the cosine similarity of two vectors (both assumed
// normalised). Zero vectors score 0.
func Cosine(a, b []float64) float64 {
	if len(a) != len(b) || len(a) == 0 {
		return 0
	}
	var dot float64
	var na, nb float64
	for i := range a {
		dot += a[i] * b[i]
		na += a[i] * a[i]
		nb += b[i] * b[i]
	}
	if na == 0 || nb == 0 {
		return 0
	}
	return dot / (math.Sqrt(na) * math.Sqrt(nb))
}

// SparseAdd accumulates src*mult into dst (used to build user profiles as
// weighted sums of events).
func SparseAdd(dst Sparse, src Sparse, mult float64) {
	for i, w := range src {
		dst[i] += w * mult
	}
}

func priceBand(p float64) string {
	switch {
	case p <= 0:
		return "free"
	case p < 800:
		return "b1"
	case p < 1800:
		return "b2"
	case p < 4000:
		return "b3"
	default:
		return "b4"
	}
}

func timeTokens(t time.Time) []string {
	u := t.UTC()
	days := []string{"time:weekend"}
	if u.Weekday() != time.Saturday && u.Weekday() != time.Sunday {
		days = []string{"time:weekday"}
	}
	return []string{fmt.Sprintf("time:h%02d", u.Hour()), days[0]}
}

func titleTokens(s string) []string {
	var out []string
	seen := map[string]bool{}
	for _, w := range strings.Split(nonWord.ReplaceAllString(strings.ToLower(s), " "), " ") {
		w = strings.TrimSpace(w)
		if len(w) < 3 || seen[w] {
			continue
		}
		seen[w] = true
		out = append(out, w)
	}
	return out
}

// EventSparse builds the weighted feature bag of an event. Weights are chosen
// so category/venue dominate and free-text title contributes a minority.
func EventSparse(ev *EventDoc, venue *VenueDoc) Sparse {
	v := Sparse{}
	if ev == nil {
		return v
	}

	if cat := strings.ToLower(strings.TrimSpace(ev.Category)); cat != "" {
		addToken(v, "cat:"+cat, 5)
	}
	if scat := strings.ToLower(strings.TrimSpace(ev.SubCategory)); scat != "" {
		addToken(v, "scat:"+scat, 2)
	}
	if etype := strings.ToLower(strings.TrimSpace(ev.EventType)); etype != "" {
		addToken(v, "etype:"+etype, 2)
	}
	if city := strings.ToLower(strings.TrimSpace(ev.City)); city != "" {
		addToken(v, "city:"+city, 3)
	}
	if country := strings.ToLower(strings.TrimSpace(ev.Country)); country != "" {
		addToken(v, "country:"+country, 1)
	}
	if ev.IsFree {
		addToken(v, "price:free", 2)
	} else {
		addToken(v, "price:"+priceBand(ev.MinTicketPrice), 2)
	}
	for _, tf := range timeTokens(ev.StartTime) {
		addToken(v, tf, 1.5)
	}
	for _, w := range titleTokens(ev.Title) {
		addToken(v, "title:"+w, 0.8)
	}
	if ev.OrganizerName != "" {
		addToken(v, "org:"+strings.ToLower(nonWord.ReplaceAllString(ev.OrganizerName, "")), 0.5)
	}

	if venue != nil {
		if n := strings.ToLower(strings.TrimSpace(venue.Name)); n != "" {
			addToken(v, "venue:"+nonWord.ReplaceAllString(n, ""), 3)
		}
		if vt := strings.ToLower(strings.TrimSpace(venue.VenueType)); vt != "" {
			addToken(v, "vtype:"+vt, 1.5)
		}
		if vc := strings.ToLower(strings.TrimSpace(venue.City)); vc != "" {
			addToken(v, "venue-city:"+vc, 1.5)
		}
	}

	for _, t := range ev.Tickets {
		if t == nil {
			continue
		}
		if n := strings.ToLower(strings.TrimSpace(t.Name)); n != "" {
			addToken(v, "tix:"+nonWord.ReplaceAllString(n, ""), 0.6)
		}
	}
	return v
}

// encodeSparse / decodeSparse persist sparse vectors as JSON (feature_vector).
func encodeSparse(s Sparse) (string, error) {
	if s == nil {
		return "{}", nil
	}
	b, err := json.Marshal(s)
	return string(b), err
}

func decodeSparse(raw string) (Sparse, error) {
	out := Sparse{}
	if raw == "" {
		return out, nil
	}
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	return out, nil
}

func encodeDense(v []float64) (string, error) {
	b, err := json.Marshal(v)
	return string(b), err
}

func decodeDense(raw string) ([]float64, error) {
	if raw == "" {
		return nil, nil
	}
	var out []float64
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	return out, nil
}
