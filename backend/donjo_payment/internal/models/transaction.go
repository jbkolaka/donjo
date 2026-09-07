package models

import "time"

// Card/domain constants.
const (
	TypePurchase       = "purchase"
	TypeRefund         = "refund"
	TypeWalletDeposit  = "wallet_deposit"
	TypeWalletWithdraw = "wallet_withdrawal"

	StatusPending  = "pending"
	StatusPaid     = "paid"
	StatusFailed   = "failed"
	StatusRefunded = "refunded"

	MethodMpesa  = "mpesa"
	MethodWallet = "wallet"

	ChannelMpesaExpress = "mpesa_express"
	ChannelWallet       = "wallet"
)

// PurchaseSnapshot holds the denormalized purchase context every checkout
// carries. It is derived from the published ticket.purchased event.
type PurchaseSnapshot struct {
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
	CreatorID     string
}

// Transaction is one money movement (purchase, refund, wallet top-up...).
type Transaction struct {
	ID                     string         `json:"id"`
	UserID                 string         `json:"user_id"`
	BookingID              string         `json:"booking_id,omitempty"`
	TransactionType        string         `json:"transaction_type"`
	Amount                 float64        `json:"amount"`
	Currency               string         `json:"currency"`
	PaymentMethod          string         `json:"payment_method"`
	PaymentChannel         string         `json:"payment_channel,omitempty"`
	Status                 string         `json:"status"`
	StatusReason           string         `json:"status_reason,omitempty"`
	MpesaReceipt           string         `json:"mpesa_receipt,omitempty"`
	MpesaRequestID         string         `json:"mpesa_request_id,omitempty"`
	MpesaCheckoutRequestID string         `json:"mpesa_checkout_request_id,omitempty"`
	MpesaPhoneNumber       string         `json:"mpesa_phone_number,omitempty"`
	WalletBefore           *float64       `json:"wallet_before,omitempty"`
	WalletAfter            *float64       `json:"wallet_after,omitempty"`
	PlatformFee            float64        `json:"platform_fee"`
	ProcessingFee          float64        `json:"processing_fee"`
	NetAmount              float64        `json:"net_amount"`
	Reference              string         `json:"reference,omitempty"`
	Metadata               map[string]any `json:"metadata,omitempty"`
	InitiatedAt            time.Time      `json:"initiated_at"`
	CompletedAt            *time.Time     `json:"completed_at,omitempty"`
	FailedAt               *time.Time     `json:"failed_at,omitempty"`
	CreatedAt              time.Time      `json:"created_at"`
	UpdatedAt              time.Time      `json:"updated_at"`

	Escrow *Escrow `json:"escrow,omitempty"`
}

// EscrowStatus values.
const (
	EscrowHeld     = "held"
	EscrowReleased = "released"
	EscrowDisputed = "disputed"
	EscrowRefunded = "refunded"
)

// Escrow holds the buyer's money until the event condition releases it.
type Escrow struct {
	ID                string     `json:"id"`
	BookingID         string     `json:"booking_id"`
	TotalAmount       float64    `json:"total_amount"`
	PlatformFee       float64    `json:"platform_fee"`
	OrganizerAmount   float64    `json:"organizer_amount"`
	RefundedAmount    float64    `json:"refunded_amount"`
	Status            string     `json:"status"`
	StatusReason      string     `json:"status_reason,omitempty"`
	ReleaseDate       *time.Time `json:"release_date,omitempty"`
	ReleaseCondition  string     `json:"release_condition,omitempty"`
	ReleasedBy        string     `json:"released_by,omitempty"`
	DisputeID         string     `json:"dispute_id,omitempty"`
	DisputedAt        *time.Time `json:"disputed_at,omitempty"`
	DisputeResolution string     `json:"dispute_resolution,omitempty"`
	RefundID          string     `json:"refund_id,omitempty"`
	RefundedAt        *time.Time `json:"refunded_at,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

// WalletEntryType values.
const (
	WalletCredit = "credit"
	WalletDebit  = "debit"
)

// WalletEntry is one line of the user's wallet ledger.
type WalletEntry struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	Type         string    `json:"type"`
	Amount       float64   `json:"amount"`
	BalanceAfter float64   `json:"balance_after"`
	SourceType   string    `json:"source_type,omitempty"`
	SourceID     string    `json:"source_id,omitempty"`
	Description  string    `json:"description,omitempty"`
	Reference    string    `json:"reference,omitempty"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
}
