package models

import "time"

// TicketInstance is one issued seat: a unique admission code (the QR payload)
// with a named holder. Group purchases mint one instance per seat, each
// individually assignable to a person.
//
// Status machine:
//
//	active        holder owns a live code
//	pending_claim offered to holder_email; frozen until claimed
//	listed        on the resale marketplace
//	resold        sale executed; code handed to the buyer (becomes active)
//	used          scanned at the gate
//	void          invalidated by the organizer
type TicketInstance struct {
	ID        string `json:"id"`
	BookingID string `json:"booking_id"`
	TicketID  string `json:"ticket_id"`
	EventID   string `json:"event_id"`
	UserID    string `json:"user_id"`

	TicketCode string `json:"ticket_code,omitempty"`
	QRData     string `json:"qr_data,omitempty"`
	QRImageURL string `json:"qr_image_url,omitempty"`
	Barcode    string `json:"barcode,omitempty"`

	HolderName  string `json:"holder_name,omitempty"`
	HolderEmail string `json:"holder_email,omitempty"`
	HolderPhone string `json:"holder_phone,omitempty"`

	Status   string     `json:"status"`
	UsedAt   *time.Time `json:"used_at,omitempty"`
	UsedBy   string     `json:"used_by,omitempty"`

	TransferAllowed bool   `json:"transfer_allowed"`
	Transferred     bool   `json:"transferred"`
	TransferredFrom string `json:"transferred_from,omitempty"`
	TransferredTo   string `json:"transferred_to,omitempty"`
	TransferredAt   *time.Time `json:"transferred_at,omitempty"`
	TransferCode    string `json:"transfer_code,omitempty"`

	ListedPrice *float64   `json:"listed_price,omitempty"`
	ListedAt    *time.Time `json:"listed_at,omitempty"`
	UnlistedAt  *time.Time `json:"unlisted_at,omitempty"`
	ResoldPrice *float64   `json:"resold_price,omitempty"`
	ResoldAt    *time.Time `json:"resold_at,omitempty"`

	CheckedIn      bool       `json:"checked_in"`
	CheckedInAt    *time.Time `json:"checked_in_at,omitempty"`
	CheckedInBy    string     `json:"checked_in_by,omitempty"`
	ScanCount      int        `json:"scan_count"`
	LastScannedAt  *time.Time `json:"last_scanned_at,omitempty"`

	VIPAccess   bool   `json:"vip_access"`
	SpecialNotes string `json:"special_notes,omitempty"`
	IsValid     bool   `json:"is_valid"`
	InvalidationReason string `json:"invalidation_reason,omitempty"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Joined context for list responses.
	EventTitle    string `json:"event_title,omitempty"`
	EventSlug     string `json:"event_slug,omitempty"`
	TicketType    string `json:"ticket_type,omitempty"`
	TicketName    string `json:"ticket_name,omitempty"`
	BookingRef    string `json:"booking_reference,omitempty"`
}

const (
	InstanceActive       = "active"
	InstancePendingClaim = "pending_claim"
	InstanceListed       = "listed"
	InstanceResold       = "resold"
	InstanceUsed         = "used"
	InstanceVoid         = "void"
)