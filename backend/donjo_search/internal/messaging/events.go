package messaging

import "time"

// Routing keys on the "donjo.events" topic exchange. The search service
// listens for the full catalog of event, ticket, venue and purchase events so
// its indices stay a live denormalised view of the source services.
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
	QueueSearchSync = "donjo.search.sync"
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

// EventPublished mirrors donjo_event's published payload.
type EventPublished struct {
	EventID string `json:"event_id"`
	Slug    string `json:"slug"`
	Title   string `json:"title"`
}

// TicketPurchased mirrors donjo_event's purchase payload. The search index
// uses it to refresh an event's ticket availability.
type TicketPurchased struct {
	OrderID   string  `json:"order_id"`
	EventID   string  `json:"event_id"`
	TicketID  string  `json:"ticket_id"`
	Quantity  int     `json:"quantity"`
	UnitPrice float64 `json:"unit_price"`
	UserID    string  `json:"user_id"`
	UserEmail string  `json:"user_email,omitempty"`
	CreatorID string  `json:"creator_id"`
}

// TicketSaleReleased is emitted by donjo_event when released ticket stock
// becomes available again.
type TicketSaleReleased struct {
	TicketID   string    `json:"ticket_id"`
	EventID    string    `json:"event_id"`
	Quantity   int       `json:"quantity"`
	ReleasedAt time.Time `json:"released_at"`
}
