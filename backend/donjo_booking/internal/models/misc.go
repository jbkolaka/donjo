package models

import "time"

// QRScanLog records every gate scan attempt, success or failure.
type QRScanLog struct {
	ID               string    `json:"id"`
	TicketInstanceID string    `json:"ticket_instance_id"`
	EventID          string    `json:"event_id"`
	BookingID        string    `json:"booking_id"`
	ScannerID        string    `json:"scanner_id"`
	UserID           string    `json:"user_id"`

	ScanType         string `json:"scan_type"`
	ScanResult       string `json:"scan_result"`
	QRCodeScanned    string `json:"qr_code_scanned,omitempty"`
	ScanLocation     string `json:"scan_location,omitempty"`
	ScanLocationName string `json:"scan_location_name,omitempty"`
	ScanIP           string `json:"scan_ip,omitempty"`
	ScanDeviceInfo   string `json:"scan_device_info,omitempty"`
	ScannerDeviceID  string `json:"scanner_device_id,omitempty"`
	ScannerAppVersion string `json:"scanner_app_version,omitempty"`

	ResponseMessage  string `json:"response_message,omitempty"`
	ResponseCode     string `json:"response_code,omitempty"`
	TicketStatusBefore string `json:"ticket_status_before,omitempty"`
	TicketStatusAfter  string `json:"ticket_status_after,omitempty"`

	Metadata  string    `json:"metadata,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// ScanLocation is a gate/entrance configuration for an event.
type ScanLocation struct {
	ID      string `json:"id"`
	EventID string `json:"event_id"`

	Name    string `json:"name"`
	Description string `json:"description,omitempty"`
	Address string `json:"address,omitempty"`
	Coordinates string `json:"coordinates,omitempty"`
	Radius  int    `json:"radius"`
	OpensAt string `json:"opens_at,omitempty"`
	ClosesAt string `json:"closes_at,omitempty"`
	AllowedTicketTypes string `json:"allowed_ticket_types,omitempty"`
	RequiresExtraVerification bool `json:"requires_extra_verification"`
	AssignedStaff string `json:"assigned_staff,omitempty"`
	IsActive bool `json:"is_active"`
	IsPrimary bool `json:"is_primary"`

	TotalScans  int `json:"total_scans"`
	SuccessScans int `json:"success_scans"`
	FailedScans int `json:"failed_scans"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// WaitlistEntry is a caller's interest in an event past its ticket cap.
type WaitlistEntry struct {
	ID        string    `json:"id"`
	EventID   string    `json:"event_id"`
	UserID    string    `json:"user_id"`
	TicketType string   `json:"ticket_type,omitempty"`
	Quantity  int       `json:"quantity"`
	Status    string    `json:"status"`
	OfferSent bool      `json:"offer_sent"`
	OfferSentAt *time.Time `json:"offer_sent_at,omitempty"`
	OfferExpiresAt *time.Time `json:"offer_expires_at,omitempty"`
	BookingID string    `json:"booking_id,omitempty"`
	ConvertedAt *time.Time `json:"converted_at,omitempty"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}