package messaging

import "time"

// Routing keys on the "donjo.events" topic exchange. The ML service listens to
// the catalog and ticket-sales events so its embedding tables stay a live
// denormalised view of what the rest of the platform is doing.
const (
	ExchangeDonjoEvents = "donjo.events"

	KeyEventCreated   = "event.created"
	KeyEventUpdated   = "event.updated"
	KeyEventDeleted   = "event.deleted"
	KeyEventPublished = "event.published"

	KeyTicketTypeCreated  = "ticket.type.created"
	KeyTicketTypeUpdated  = "ticket.type.updated"
	KeyTicketPurchased    = "ticket.purchased"
	KeyTicketSaleReleased = "ticket.sale.released"

	KeyVenueCreated = "venue.created"
	KeyVenueUpdated = "venue.updated"
	KeyVenueDeleted = "venue.deleted"
)

// Exchange and queue names.
const (
	QueueMLSync = "donjo.ml.sync"
)

// Envelope is the standard message shape published to RabbitMQ.
type Envelope struct {
	ID        string      `json:"id"`
	Type      string      `json:"type"`
	Key       string      `json:"key"`
	Timestamp time.Time   `json:"timestamp"`
	Resource  string      `json:"resource"`
	EventID   string      `json:"event_id,omitempty"`
	Data      interface{} `json:"data,omitempty"`
}

// EventPublished mirrors donjo_event's published payload (id + slug + title).
type EventPublished struct {
	EventID string `json:"event_id"`
	Slug    string `json:"slug"`
	Title   string `json:"title"`
}

// TicketPurchased mirrors donjo_event's purchase payload. The ML service uses
// it to strengthen a buyer's preferences and to retrain event embeddings.
type TicketPurchased struct {
	OrderID       string  `json:"order_id"`
	EventID       string  `json:"event_id"`
	EventSlug     string  `json:"event_slug,omitempty"`
	EventTitle    string  `json:"event_title,omitempty"`
	TicketID      string  `json:"ticket_id"`
	TicketType    string  `json:"ticket_type,omitempty"`
	TicketName    string  `json:"ticket_name,omitempty"`
	Quantity      int     `json:"quantity"`
	UserID        string  `json:"user_id"`
	UserEmail     string  `json:"user_email,omitempty"`
	UnitPrice     float64 `json:"unit_price"`
	ServiceFee    float64 `json:"service_fee"`
	ProcessingFee float64 `json:"processing_fee"`
	Amount        float64 `json:"amount"`
	Currency      string  `json:"currency,omitempty"`
	CreatorID     string  `json:"creator_id"`
}

// TicketReserved mirrors the ticket.reserved payload.
type TicketReserved struct {
	TicketID  string    `json:"ticket_id"`
	EventID   string    `json:"event_id"`
	Quantity  int       `json:"quantity"`
	UserID    string    `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
}
