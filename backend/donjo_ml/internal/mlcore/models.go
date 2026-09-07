package mlcore

import (
	"crypto/rand"
	"encoding/hex"
	"time"
)

// FeatureVersion is stamped per vector; when the vectorizer changes bump it so
// the service can lazily detect stale rows. Kept in the same spirit as the
// schema's feature_version columns.
const FeatureVersion = 1

// PurchaseIn mirrors the ticket.purchased payload used to reinforce the buyer.
type PurchaseIn struct {
	OrderID     string  `json:"order_id,omitempty"`
	EventID     string  `json:"event_id,omitempty"`
	TicketID    string  `json:"ticket_id,omitempty"`
	Quantity    int     `json:"quantity,omitempty"`
	UnitPrice   float64 `json:"unit_price,omitempty"`
	UserID      string  `json:"user_id,omitempty"`
	UserEmail   string  `json:"user_email,omitempty"`
	CreatorID   string  `json:"creator_id,omitempty"`
	PurchasedAt string  `json:"purchased_at,omitempty"`
}

func newID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return hex.EncodeToString(b)
}

// EventDoc mirrors donjo_event's Event model (the fields the ML service uses
// to build embeddings and render recommendations). Unknown/extra fields are
// ignored on decode; the raw message is preserved in payload_json.
type EventDoc struct {
	ID               string       `json:"id"`
	CreatorID        string       `json:"creator_id"`
	Title            string       `json:"title"`
	Slug             string       `json:"slug"`
	Description      string       `json:"description,omitempty"`
	ShortDescription string       `json:"short_description,omitempty"`
	Category         string       `json:"category"`
	SubCategory      string       `json:"sub_category,omitempty"`
	Tags             []string     `json:"tags,omitempty"`
	EventType        string       `json:"event_type"`
	IsVirtual        bool         `json:"is_virtual"`
	VenueID          string       `json:"venue_id,omitempty"`
	Location         string       `json:"location,omitempty"`
	Address          string       `json:"address,omitempty"`
	City             string       `json:"city,omitempty"`
	County           string       `json:"county,omitempty"`
	Country          string       `json:"country"`
	StartTime        time.Time    `json:"start_time"`
	EndTime          time.Time    `json:"end_time"`
	Timezone         string       `json:"timezone"`
	TotalCapacity    int          `json:"total_capacity"`
	MinTicketPrice   float64      `json:"min_ticket_price"`
	MaxTicketPrice   float64      `json:"max_ticket_price"`
	IsFree           bool         `json:"is_free"`
	Status           string       `json:"status"`
	IsPublished      bool         `json:"is_published"`
	IsPrivate        bool         `json:"is_private"`
	BannerImage      string       `json:"banner_image,omitempty"`
	OrganizerName    string       `json:"organizer_name,omitempty"`
	Views            int          `json:"views"`
	Likes            int          `json:"likes"`
	Shares           int          `json:"shares"`
	TicketsSold      int          `json:"tickets_sold"`
	Revenue          float64      `json:"revenue"`
	CreatedAt        time.Time    `json:"created_at"`
	UpdatedAt        time.Time    `json:"updated_at"`
	Tickets          []*TicketDoc `json:"tickets,omitempty"`
}

// TicketDoc mirrors donjo_event's Ticket model (flat payloads arrive on
// ticket.type.created/updated; events may also carry nested tickets).
type TicketDoc struct {
	ID            string     `json:"id"`
	EventID       string     `json:"event_id"`
	Type          string     `json:"type"`
	Tier          string     `json:"tier,omitempty"`
	Name          string     `json:"name"`
	Description   string     `json:"description,omitempty"`
	Price         float64    `json:"price"`
	ServiceFee    float64    `json:"service_fee"`
	ProcessingFee float64    `json:"processing_fee"`
	Quantity      int        `json:"quantity"`
	Sold          int        `json:"sold"`
	Reserved      int        `json:"reserved"`
	IsActive      bool       `json:"is_active"`
	IsHidden      bool       `json:"is_hidden"`
	SalesStart    *time.Time `json:"sales_start,omitempty"`
	SalesEnd      *time.Time `json:"sales_end,omitempty"`
	CreatedAt     time.Time  `json:"created_at,omitempty"`
	UpdatedAt     time.Time  `json:"updated_at,omitempty"`
}

// VenueDoc mirrors donjo_event's Venue model, stored in venue_docs so events
// can be feature-augmented by their venue.
type VenueDoc struct {
	ID            string `json:"id"`
	CreatorID     string `json:"creator_id"`
	Name          string `json:"name"`
	Slug          string `json:"slug"`
	Description   string `json:"description,omitempty"`
	VenueType     string `json:"venue_type"`
	VenueCategory string `json:"venue_category,omitempty"`
	Address       string `json:"address"`
	City          string `json:"city,omitempty"`
	County        string `json:"county,omitempty"`
	Country       string `json:"country"`
	Capacity      int    `json:"capacity"`
	Status        string `json:"status"`

	// EventHits and friends are intentionally ignored; the embedding only
	// cares about identity + geography + type.
}

// SimilarEvent is one entry in an event's similar_events payload.
type SimilarEvent struct {
	EventID string  `json:"event_id"`
	Title   string  `json:"title"`
	Slug    string  `json:"slug,omitempty"`
	Score   float64 `json:"score"`
}

// InteractionIn is the authenticated request body for recording user behaviour.
type InteractionIn struct {
	EventID         string `json:"event_id"`
	VenueID         string `json:"venue_id"`
	InteractionType string `json:"interaction_type"`
	Weight          int    `json:"weight,omitempty"`
	SessionID       string `json:"session_id,omitempty"`
	DurationSeconds int    `json:"duration_seconds,omitempty"`
	Position        int    `json:"position,omitempty"`
	DeviceType      string `json:"device_type,omitempty"`
	IPAddress       string `json:"ip_address,omitempty"`
}

// UserProfile is the decoded user_embeddings row plus helpers for rendering
// recommendation reasons.
type UserProfile struct {
	UserID              string             `json:"user_id"`
	Embedding           []float64          `json:"embedding"`
	CategoryWeights     map[string]float64 `json:"category_weights"`
	FeatureVector       Sparse             `json:"feature_vector"`
	PreferredCategories []string           `json:"preferred_categories"`
	PreferredVenues     map[string]float64 `json:"preferred_venues"`
	PreferredTimes      map[string]float64 `json:"preferred_times"`
	FeatureVersion      int                `json:"feature_version"`
	InteractionCount    int                `json:"interaction_count"`
	LastCalculatedAt    string             `json:"last_calculated_at,omitempty"`
	LastUpdatedAt       string             `json:"last_updated_at,omitempty"`
}

// RecItem is one recommendation in a feed result.
type RecItem struct {
	EventID string    `json:"event_id"`
	Score   float64   `json:"score"`
	Reasons []string  `json:"reasons"`
	Event   *EventDoc `json:"event"`
}

// RecResult is the response of the recommendations endpoint, cached per user+type.
type RecResult struct {
	ModelVersion string    `json:"model_version"`
	Type         string    `json:"type"`
	UserID       string    `json:"user_id"`
	Items        []RecItem `json:"items"`
}
