package models

import "time"

// BookingSnapshot holds the denormalized purchase context every checkout
// carries. It is derived from the published ticket.purchased event.
type BookingSnapshot struct {
	OrderID       string
	EventID       string
	EventSlug     string
	EventTitle    string
	TicketID      string
	TicketType    string
	TicketName    string
	Quantity      int
	UnitPrice     float64
	ServiceFee    float64
	ProcessingFee float64
	Amount        float64
	Currency      string
	UserID        string
	UserEmail     string
}

// Booking is one checkout order: N seats of a ticket type.
type Booking struct {
	ID              string `json:"id"`
	UserID          string `json:"user_id"`
	EventID         string `json:"event_id"`
	EventTitle      string `json:"event_title"`
	EventSlug       string `json:"event_slug,omitempty"`
	TicketID        string `json:"ticket_id"`
	BookingReference string `json:"booking_reference"`
	OrderNumber     string `json:"order_number,omitempty"`
	TicketType      string `json:"ticket_type"`
	TicketName      string `json:"ticket_name"`
	Quantity        int    `json:"quantity"`
	UnitPrice       float64 `json:"unit_price"`
	TotalAmount     float64 `json:"total_amount"`
	ServiceFee      float64 `json:"service_fee"`
	ProcessingFee   float64 `json:"processing_fee"`
	PlatformFee     float64 `json:"platform_fee"`
	NetAmount       float64 `json:"net_amount"`

	PaymentMethod  string     `json:"payment_method,omitempty"`
	PaymentStatus  string     `json:"payment_status"`
	PaymentDate    *time.Time `json:"payment_date,omitempty"`
	TransactionID  string     `json:"transaction_id,omitempty"`
	EscrowID       string     `json:"escrow_id,omitempty"`
	EscrowStatus   string     `json:"escrow_status,omitempty"`

	Status       string `json:"status"`
	StatusReason string `json:"status_reason,omitempty"`

	AttendeeName   string `json:"attendee_name,omitempty"`
	AttendeeEmail  string `json:"attendee_email,omitempty"`
	AttendeePhone  string `json:"attendee_phone,omitempty"`
	AttendeeNotes  string `json:"attendee_notes,omitempty"`
	CustomAnswers  string `json:"custom_answers,omitempty"`

	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`
	CancelledAt *time.Time `json:"cancelled_at,omitempty"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`

	Instances []*TicketInstance `json:"instances,omitempty"`
}