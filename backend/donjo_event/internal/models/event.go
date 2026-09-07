package models

import "time"

type Coordinates struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type Event struct {
	ID        string `json:"id"`
	CreatorID string `json:"creator_id"`

	Title           string `json:"title"`
	Slug            string `json:"slug"`
	Description     string `json:"description,omitempty"`
	ShortDescription string `json:"short_description,omitempty"`
	Category        string `json:"category"`
	SubCategory     string `json:"sub_category,omitempty"`
	Tags            []string `json:"tags,omitempty"`

	EventType   string `json:"event_type"`
	IsVirtual   bool   `json:"is_virtual"`
	VirtualLink string `json:"virtual_link,omitempty"`
	VirtualPlatform string `json:"virtual_platform,omitempty"`

	VenueID   string `json:"venue_id,omitempty"`
	Location  string `json:"location,omitempty"`
	Address   string `json:"address,omitempty"`
	City      string `json:"city,omitempty"`
	County    string `json:"county,omitempty"`
	Country   string `json:"country"`
	Coordinates *Coordinates `json:"coordinates,omitempty"`

	StartTime time.Time  `json:"start_time"`
	EndTime   time.Time  `json:"end_time"`
	Timezone  string    `json:"timezone"`
	SetupTime *time.Time `json:"setup_time,omitempty"`
	TeardownTime *time.Time `json:"teardown_time,omitempty"`

	TotalCapacity   int     `json:"total_capacity"`
	AvailableTickets *int   `json:"available_tickets,omitempty"`
	MinTicketPrice  float64 `json:"min_ticket_price"`
	MaxTicketPrice  float64 `json:"max_ticket_price"`
	IsFree          bool    `json:"is_free"`

	TicketSalesStart    *time.Time `json:"ticket_sales_start,omitempty"`
	TicketSalesEnd      *time.Time `json:"ticket_sales_end,omitempty"`
	TicketTransferAllowed bool    `json:"ticket_transfer_allowed"`
	RefundDeadline      *time.Time `json:"refund_deadline,omitempty"`

	Status      string `json:"status"`
	IsPublished bool   `json:"is_published"`
	PublishedAt *time.Time `json:"published_at,omitempty"`

	IsPrivate    bool   `json:"is_private"`
	InviteOnly   bool   `json:"invite_only"`
	EventPassword string `json:"event_password,omitempty"`

	IsVerified       bool       `json:"is_verified"`
	VerifiedBy       string     `json:"verified_by,omitempty"`
	VerifiedAt       *time.Time `json:"verified_at,omitempty"`
	VerificationNotes string    `json:"verification_notes,omitempty"`

	BannerImage   string   `json:"banner_image,omitempty"`
	GalleryImages []string `json:"gallery_images,omitempty"`
	VideoURL      string   `json:"video_url,omitempty"`

	OrganizerName  string `json:"organizer_name,omitempty"`
	OrganizerEmail string `json:"organizer_email,omitempty"`
	OrganizerPhone string `json:"organizer_phone,omitempty"`

	Views       int `json:"views"`
	Likes       int `json:"likes"`
	Shares      int `json:"shares"`
	TicketsSold int `json:"tickets_sold"`
	Revenue     float64 `json:"revenue"`

	AllowWaitlist          bool `json:"allow_waitlist"`
	RequiresAgeVerification bool `json:"requires_age_verification"`
	MinimumAge             *int `json:"minimum_age,omitempty"`

	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`

	Tickets []*Ticket `json:"tickets,omitempty"`
}

type Venue struct {
	ID             string `json:"id"`
	CreatorID      string `json:"creator_id"`

	Name            string `json:"name"`
	Slug            string `json:"slug"`
	Description     string `json:"description,omitempty"`
	ShortDescription string `json:"short_description,omitempty"`
	VenueType       string `json:"venue_type"`
	VenueCategory   string `json:"venue_category,omitempty"`

	Address       string `json:"address"`
	City          string `json:"city,omitempty"`
	County        string `json:"county,omitempty"`
	Country       string `json:"country"`
	Coordinates   *Coordinates `json:"coordinates,omitempty"`
	MapEmbedURL   string `json:"map_embed_url,omitempty"`
	Directions    string `json:"directions,omitempty"`

	Capacity    int `json:"capacity"`
	MaxCapacity int `json:"max_capacity,omitempty"`

	BasePrice       float64 `json:"base_price"`
	PricingType     string  `json:"pricing_type"`
	MinBookingHours int     `json:"min_booking_hours"`
	MaxBookingHours int     `json:"max_booking_hours"`
	SecurityDeposit float64 `json:"security_deposit"`
	CleaningFee     float64 `json:"cleaning_fee"`

	IsAvailable        bool                   `json:"is_available"`
	AvailabilitySchedule map[string]interface{} `json:"availability_schedule,omitempty"`
	UnavailableDates   []string               `json:"unavailable_dates,omitempty"`

	Amenities        []string               `json:"amenities,omitempty"`
	Equipment        []string               `json:"equipment,omitempty"`
	CapacityFeatures map[string]interface{} `json:"capacity_features,omitempty"`
	Restrictions     []string               `json:"restrictions,omitempty"`

	IsVerified         bool       `json:"is_verified"`
	VerifiedBy         string     `json:"verified_by,omitempty"`
	VerifiedAt         *time.Time `json:"verified_at,omitempty"`
	VerificationNotes  string     `json:"verification_notes,omitempty"`
	Status             string     `json:"status"`

	CoverImage    string   `json:"cover_image,omitempty"`
	GalleryImages []string `json:"gallery_images,omitempty"`
	VirtualTourURL string  `json:"virtual_tour_url,omitempty"`

	ContactName  string `json:"contact_name,omitempty"`
	ContactPhone string `json:"contact_phone,omitempty"`
	ContactEmail string `json:"contact_email,omitempty"`

	EventsHosted int     `json:"events_hosted"`
	Rating       float64 `json:"rating"`
	ReviewCount  int     `json:"review_count"`

	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}

type Ticket struct {
	ID      string `json:"id"`
	EventID string `json:"event_id"`

	Type        string `json:"type"`
	Tier        string `json:"tier,omitempty"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`

	Price         float64 `json:"price"`
	OriginalPrice float64 `json:"original_price,omitempty"`
	ServiceFee    float64 `json:"service_fee"`
	ProcessingFee float64 `json:"processing_fee"`

	Quantity int `json:"quantity"`
	Sold     int `json:"sold"`
	Reserved int `json:"reserved"`
	MaxPerUser int `json:"max_per_user"`
	MinPerUser int `json:"min_per_user"`

	SalesStart         *time.Time `json:"sales_start,omitempty"`
	SalesEnd           *time.Time `json:"sales_end,omitempty"`
	EarlyBirdDeadline  *time.Time `json:"early_bird_deadline,omitempty"`

	IsTransferable  bool                   `json:"is_transferable"`
	IsRefundable    bool                   `json:"is_refundable"`
	RequiresIDCheck bool                   `json:"requires_id_check"`
	CustomFields    map[string]interface{} `json:"custom_fields,omitempty"`
	Benefits        []string               `json:"benefits,omitempty"`

	IsActive bool `json:"is_active"`
	IsHidden bool `json:"is_hidden"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
