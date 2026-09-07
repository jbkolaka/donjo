package searchcore

// Elasticsearch index names this service owns.
const (
	IndexEvents  = "donjo_events"
	IndexTickets = "donjo_tickets"
	IndexVenues  = "donjo_venues"
)

// EventDoc is the denormalised event document stored in the events index. It
// is a searchable projection of donjo_event's Event model, flattened so query
// filters and aggregations stay cheap, with the ticket list kept as a nested
// object for per-ticket filtering.
type EventDoc struct {
	Type             string         `json:"type"`
	ID               string         `json:"id"`
	CreatorID        string         `json:"creator_id"`
	Title            string         `json:"title"`
	Slug             string         `json:"slug"`
	Description      string         `json:"description,omitempty"`
	ShortDescription string         `json:"short_description,omitempty"`
	Category         string         `json:"category,omitempty"`
	SubCategory      string         `json:"sub_category,omitempty"`
	Tags             []string       `json:"tags,omitempty"`
	EventType        string         `json:"event_type"`
	IsVirtual        bool           `json:"is_virtual"`
	VirtualLink      string         `json:"virtual_link,omitempty"`
	VirtualPlatform  string         `json:"virtual_platform,omitempty"`
	VenueID          string         `json:"venue_id,omitempty"`
	VenueName        string         `json:"venue_name,omitempty"`
	Location         string         `json:"location,omitempty"`
	Address          string         `json:"address,omitempty"`
	City             string         `json:"city,omitempty"`
	County           string         `json:"county,omitempty"`
	Country          string         `json:"country,omitempty"`
	Coordinates      []float64      `json:"coordinates,omitempty"` // [lon, lat]
	StartTime        string         `json:"start_time,omitempty"`
	EndTime          string         `json:"end_time,omitempty"`
	Timezone         string         `json:"timezone,omitempty"`
	TotalCapacity    int            `json:"total_capacity"`
	AvailableTickets int            `json:"available_tickets,omitempty"`
	MinTicketPrice   float64        `json:"min_ticket_price"`
	MaxTicketPrice   float64        `json:"max_ticket_price"`
	IsFree           bool           `json:"is_free"`
	Status           string         `json:"status,omitempty"`
	IsPublished      bool           `json:"is_published"`
	IsPrivate        bool           `json:"is_private"`
	InviteOnly       bool           `json:"invite_only"`
	OrganizerName    string         `json:"organizer_name,omitempty"`
	Views            int            `json:"views"`
	Likes            int            `json:"likes"`
	TicketsSold      int            `json:"tickets_sold"`
	Revenue          float64        `json:"revenue"`
	Tickets          []TicketNested `json:"tickets,omitempty"`
	CreatedAt        string         `json:"created_at,omitempty"`
	UpdatedAt        string         `json:"updated_at,omitempty"`
}

// TicketNested is the nested per-ticket block inside an event document.
type TicketNested struct {
	ID            string  `json:"id"`
	Name          string  `json:"name"`
	Type          string  `json:"type,omitempty"`
	Tier          string  `json:"tier,omitempty"`
	Price         float64 `json:"price"`
	ServiceFee    float64 `json:"service_fee"`
	ProcessingFee float64 `json:"processing_fee"`
	Quantity      int     `json:"quantity"`
	Sold          int     `json:"sold"`
	Reserved      int     `json:"reserved"`
	Availability  int     `json:"availability"`
	IsActive      bool    `json:"is_active"`
	IsHidden      bool    `json:"is_hidden"`
	SalesStart    string  `json:"sales_start,omitempty"`
	SalesEnd      string  `json:"sales_end,omitempty"`
}

// TicketDoc is the denormalised ticket document stored in the tickets index,
// carrying the event context for cross-cut facets (category, city, date).
type TicketDoc struct {
	Type             string  `json:"type"`
	ID               string  `json:"id"`
	Name             string  `json:"name"`
	Description      string  `json:"description,omitempty"`
	TypeName         string  `json:"ticket_type,omitempty"`
	Tier             string  `json:"tier,omitempty"`
	Price            float64 `json:"price"`
	OriginalPrice    float64 `json:"original_price,omitempty"`
	ServiceFee       float64 `json:"service_fee"`
	ProcessingFee    float64 `json:"processing_fee"`
	Quantity         int     `json:"quantity"`
	Sold             int     `json:"sold"`
	Reserved         int     `json:"reserved"`
	Availability     int     `json:"availability"`
	IsActive         bool    `json:"is_active"`
	IsHidden         bool    `json:"is_hidden"`
	IsTransferable   bool    `json:"is_transferable"`
	IsRefundable     bool    `json:"is_refundable"`
	RequiresIDCheck  bool    `json:"requires_id_check"`
	EventID          string  `json:"event_id"`
	EventTitle       string  `json:"event_title,omitempty"`
	EventSlug        string  `json:"event_slug,omitempty"`
	EventCategory    string  `json:"event_category,omitempty"`
	EventCity        string  `json:"event_city,omitempty"`
	EventStartTime   string  `json:"event_start_time,omitempty"`
	EventIsPublished bool    `json:"event_is_published"`
	CreatedAt        string  `json:"created_at,omitempty"`
	UpdatedAt        string  `json:"updated_at,omitempty"`
}

// VenueDoc is the denormalised venue document stored in the venues index.
type VenueDoc struct {
	Type             string    `json:"type"`
	ID               string    `json:"id"`
	CreatorID        string    `json:"creator_id"`
	Name             string    `json:"name"`
	Slug             string    `json:"slug"`
	Description      string    `json:"description,omitempty"`
	ShortDescription string    `json:"short_description,omitempty"`
	VenueType        string    `json:"venue_type,omitempty"`
	VenueCategory    string    `json:"venue_category,omitempty"`
	Address          string    `json:"address"`
	City             string    `json:"city,omitempty"`
	County           string    `json:"county,omitempty"`
	Country          string    `json:"country,omitempty"`
	Coordinates      []float64 `json:"coordinates,omitempty"`
	Amenities        []string  `json:"amenities,omitempty"`
	Capacity         int       `json:"capacity"`
	BasePrice        float64   `json:"base_price"`
	PricingType      string    `json:"pricing_type,omitempty"`
	IsAvailable      bool      `json:"is_available"`
	Status           string    `json:"status,omitempty"`
	Rating           float64   `json:"rating"`
	ReviewCount      int       `json:"review_count"`
	EventsHosted     int       `json:"events_hosted"`
	CreatedAt        string    `json:"created_at,omitempty"`
	UpdatedAt        string    `json:"updated_at,omitempty"`
}

// TicketPurchaseIn is the purchase payload arriving on ticket.purchased.
type TicketPurchaseIn struct {
	OrderID   string  `json:"order_id"`
	EventID   string  `json:"event_id"`
	TicketID  string  `json:"ticket_id"`
	Quantity  int     `json:"quantity"`
	UnitPrice float64 `json:"unit_price"`
	UserID    string  `json:"user_id"`
	CreatorID string  `json:"creator_id"`
}

// TicketReleasedIn is the payload arriving on ticket.sale.released.
type TicketReleasedIn struct {
	TicketID string `json:"ticket_id"`
	EventID  string `json:"event_id"`
	Quantity int    `json:"quantity"`
}
