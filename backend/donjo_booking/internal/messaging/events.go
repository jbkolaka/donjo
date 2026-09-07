package messaging

import "time"

// Routing keys this service consumes from the "donjo.events" topic exchange.
const (
	ExchangeDonjoEvents = "donjo.events"

	QueueBookingSales = "donjo.booking.sales"
)

// Routing keys consumed by this service.
const (
	// KeyTicketPurchased is the routing key for completed purchases.
	KeyTicketPurchased = "ticket.purchased"
	// KeyPaymentProcessed is the routing key for payment-side records.
	KeyPaymentProcessed = "payment.processed"
)

// Envelope is the standard message shape published to RabbitMQ. This service
// consumes envelopes produced by donjo_event; it publishes none.
type Envelope struct {
	ID        string      `json:"id"`
	Type      string      `json:"type"`
	Key       string      `json:"key"`
	Timestamp time.Time   `json:"timestamp"`
	Resource  string      `json:"resource"`
	EventID   string      `json:"event_id,omitempty"`
	Data      interface{} `json:"data,omitempty"`
}

// TicketPurchased is what donjo_event sends when a checkout completes. The
// booking service derives a booking + one ticket instance per seat from it.
type TicketPurchased struct {
	OrderID        string  `json:"order_id"`
	EventID        string  `json:"event_id"`
	EventSlug      string  `json:"event_slug,omitempty"`
	EventTitle     string  `json:"event_title,omitempty"`
	TicketID       string  `json:"ticket_id"`
	TicketType     string  `json:"ticket_type,omitempty"`
	TicketName     string  `json:"ticket_name,omitempty"`
	Quantity       int     `json:"quantity"`
	UserID         string  `json:"user_id"`
	UserEmail      string  `json:"user_email,omitempty"`
	UnitPrice      float64 `json:"unit_price"`
	ServiceFee     float64 `json:"service_fee"`
	ProcessingFee  float64 `json:"processing_fee"`
	Amount         float64 `json:"amount"`
	Currency       string  `json:"currency,omitempty"`
	CreatorID      string  `json:"creator_id"`
}

// PaymentProcessed is what donjo_payment sends after recording a purchase. The
// booking service matches it by order_number and backfills the booking's
// transaction_id / escrow_id and payment details.
type PaymentProcessed struct {
	OrderID           string  `json:"order_id"`
	TransactionID     string  `json:"transaction_id"`
	TransactionStatus string  `json:"transaction_status"`
	EscrowID          string  `json:"escrow_id"`
	EscrowStatus      string  `json:"escrow_status"`
	EscrowAmount      float64 `json:"escrow_amount"`
	PlatformFee       float64 `json:"platform_fee"`
	OrganizerAmount   float64 `json:"organizer_amount"`
	PaymentMethod     string  `json:"payment_method"`
	Currency          string  `json:"currency"`
}