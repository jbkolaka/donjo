package notificationservice

import "time"

// Channel values supported by the service.
const (
	ChannelInApp = "in_app"
	ChannelEmail = "email"
	ChannelPush  = "push"
)

// Notification mirrors the notifications row.
type Notification struct {
	ID            string                 `json:"id"`
	UserID        string                 `json:"user_id"`
	Channel       string                 `json:"channel"`
	Type          string                 `json:"type"`
	Subject       string                 `json:"subject,omitempty"`
	Content       string                 `json:"content"`
	HTMLContent   string                 `json:"html_content,omitempty"`
	TemplateID    string                 `json:"template_id,omitempty"`
	TemplateData  map[string]interface{} `json:"template_data,omitempty"`
	Status        string                 `json:"status"`
	SentAt        *time.Time             `json:"sent_at,omitempty"`
	DeliveredAt   *time.Time             `json:"delivered_at,omitempty"`
	ReadAt        *time.Time             `json:"read_at,omitempty"`
	ClickedAt     *time.Time             `json:"clicked_at,omitempty"`
	ErrorMessage  string                 `json:"error_message,omitempty"`
	RetryCount    int                    `json:"retry_count"`
	Priority      string                 `json:"priority"`
	ReferenceID   string                 `json:"reference_id,omitempty"`
	ReferenceType string                 `json:"reference_type,omitempty"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt     time.Time              `json:"created_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
}

// FeedItem mirrors the user_feeds row.
type FeedItem struct {
	ID             string     `json:"id"`
	UserID         string     `json:"user_id"`
	NotificationID string     `json:"notification_id,omitempty"`
	FeedType       string     `json:"feed_type"`
	Priority       int        `json:"priority"`
	Position       int        `json:"position,omitempty"`
	Title          string     `json:"title,omitempty"`
	Message        string     `json:"message,omitempty"`
	ImageURL       string     `json:"image_url,omitempty"`
	Viewed         bool       `json:"viewed"`
	ViewedAt       *time.Time `json:"viewed_at,omitempty"`
	Clicked        bool       `json:"clicked"`
	ClickedAt      *time.Time `json:"clicked_at,omitempty"`
	Interacted     bool       `json:"interacted"`
	InteractedAt   *time.Time `json:"interacted_at,omitempty"`
	ExpiresAt      *time.Time `json:"expires_at,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}

// NotificationTemplate mirrors the notification_templates row.
type NotificationTemplate struct {
	ID                string    `json:"id"`
	Name              string    `json:"name"`
	Type              string    `json:"type"`
	SubjectTemplate   string    `json:"subject_template,omitempty"`
	ContentTemplate   string    `json:"content_template"`
	HTMLTemplate      string    `json:"html_template,omitempty"`
	RequiredVariables []string  `json:"required_variables,omitempty"`
	IsActive          bool      `json:"is_active"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// PushDevice mirrors the push_devices row.
type PushDevice struct {
	ID          string     `json:"id"`
	UserID      string     `json:"user_id"`
	DeviceToken string     `json:"device_token"`
	Platform    string     `json:"platform"`
	DeviceID    string     `json:"device_id,omitempty"`
	DeviceName  string     `json:"device_name,omitempty"`
	IsActive    bool       `json:"is_active"`
	LastUsedAt  *time.Time `json:"last_used_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

// NotifyIn is the request payload for creating a notification. Feed fields are
// optional: when feed_type is set, a user_feeds row is created too, so one
// call can notify the user and surface it in their feed.
type NotifyIn struct {
	Channel       string                 `json:"channel"`
	Type          string                 `json:"type"`
	Subject       string                 `json:"subject"`
	Content       string                 `json:"content"`
	HTMLContent   string                 `json:"html_content,omitempty"`
	TemplateID    string                 `json:"template_id,omitempty"`
	TemplateData  map[string]interface{} `json:"template_data,omitempty"`
	Status        string                 `json:"status,omitempty"`
	Priority      string                 `json:"priority,omitempty"`
	ReferenceID   string                 `json:"reference_id,omitempty"`
	ReferenceType string                 `json:"reference_type,omitempty"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`

	FeedType      string `json:"feed_type,omitempty"`
	FeedTitle     string `json:"feed_title,omitempty"`
	FeedMessage   string `json:"feed_message,omitempty"`
	FeedImageURL  string `json:"feed_image_url,omitempty"`
	FeedPriority  *int   `json:"feed_priority,omitempty"`
	TargetUserID  string `json:"user_id,omitempty"` // service-token only
}

// DeviceIn is the request payload for registering a push device.
type DeviceIn struct {
	DeviceToken string `json:"device_token"`
	Platform    string `json:"platform"`
	DeviceID    string `json:"device_id,omitempty"`
	DeviceName  string `json:"device_name,omitempty"`
}