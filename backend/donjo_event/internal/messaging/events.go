package messaging

import "time"

// Routing keys on the "donjo.events" topic exchange.
const (
	KeyEventCreated   = "event.created"
	KeyEventUpdated   = "event.updated"
	KeyEventDeleted   = "event.deleted"
	KeyEventPublished = "event.published"

	KeyTicketTypeCreated  = "ticket.type.created"
	KeyTicketTypeUpdated  = "ticket.type.updated"
	KeyTicketReserved     = "ticket.reserved"
	KeyTicketPurchased    = "ticket.purchased"
	KeyTicketSaleReleased = "ticket.sale.released"

	KeyVenueCreated = "venue.created"
	KeyVenueUpdated = "venue.updated"
	KeyVenueDeleted = "venue.deleted"
)

// Exchange and queue names.
const (
	ExchangeDonjoEvents = "donjo.events"

	QueueEventCatalog = "donjo.event.catalog"
	QueueTicketSales  = "donjo.ticket.sales"
	QueueAuthSync     = "donjo.auth.sync"
	QueueFanout       = "donjo.event.fanout"
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

type EventPublished struct {
	EventID string `json:"event_id"`
	Slug    string `json:"slug"`
	Title   string `json:"title"`
}

// TicketPurchased is published when a checkout completes. It carries the full
// purchase context because the booking service now owns admission codes and
// mints one ticket instance per seat from this event.
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

	// Stats used by the auth service to keep users counters fresh.
	CreatorID string `json:"creator_id"`
}

type TicketReserved struct {
	TicketID  string    `json:"ticket_id"`
	EventID   string    `json:"event_id"`
	Quantity  int       `json:"quantity"`
	UserID    string    `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
}

type AuthUserInfo struct {
	UserID   string `json:"user_id"`
	Email    string `json:"email"`
	FullName string `json:"full_name"`
}
