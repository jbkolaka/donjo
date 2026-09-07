-- =============================================
-- EVENT SERVICE DATABASE (SQLite)
-- =============================================

-- EVENTS TABLE
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    creator_id TEXT NOT NULL,

    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    short_description TEXT,
    category TEXT NOT NULL,
    sub_category TEXT,
    tags TEXT,

    event_type TEXT DEFAULT 'in_person',
    is_virtual INTEGER DEFAULT 0,
    virtual_link TEXT,
    virtual_platform TEXT,

    venue_id TEXT,
    location TEXT,
    address TEXT,
    city TEXT,
    county TEXT,
    country TEXT DEFAULT 'Kenya',
    coordinates TEXT,

    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    timezone TEXT DEFAULT 'Africa/Nairobi',
    setup_time TEXT,
    teardown_time TEXT,

    total_capacity INTEGER NOT NULL CHECK (total_capacity > 0),
    available_tickets INTEGER,
    min_ticket_price REAL DEFAULT 0,
    max_ticket_price REAL DEFAULT 0,
    is_free INTEGER DEFAULT 0,

    ticket_sales_start TEXT,
    ticket_sales_end TEXT,
    ticket_transfer_allowed INTEGER DEFAULT 1,
    refund_deadline TEXT,

    status TEXT DEFAULT 'draft',
    is_published INTEGER DEFAULT 0,
    published_at TEXT,

    is_private INTEGER DEFAULT 0,
    invite_only INTEGER DEFAULT 0,
    event_password TEXT,

    is_verified INTEGER DEFAULT 0,
    verified_by TEXT,
    verified_at TEXT,
    verification_notes TEXT,

    banner_image TEXT,
    gallery_images TEXT,
    video_url TEXT,

    organizer_name TEXT,
    organizer_email TEXT,
    organizer_phone TEXT,

    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    tickets_sold INTEGER DEFAULT 0,
    revenue REAL DEFAULT 0,

    allow_waitlist INTEGER DEFAULT 1,
    requires_age_verification INTEGER DEFAULT 0,
    minimum_age INTEGER,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    deleted_at TEXT
);

-- VENUES TABLE
CREATE TABLE IF NOT EXISTS venues (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    creator_id TEXT NOT NULL,

    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    short_description TEXT,
    venue_type TEXT NOT NULL,
    venue_category TEXT,

    address TEXT NOT NULL,
    city TEXT,
    county TEXT,
    country TEXT DEFAULT 'Kenya',
    coordinates TEXT,
    map_embed_url TEXT,
    directions TEXT,

    capacity INTEGER NOT NULL CHECK (capacity > 0),
    max_capacity INTEGER,

    base_price REAL NOT NULL CHECK (base_price >= 0),
    pricing_type TEXT DEFAULT 'hourly',
    min_booking_hours INTEGER DEFAULT 2,
    max_booking_hours INTEGER DEFAULT 12,
    security_deposit REAL DEFAULT 0,
    cleaning_fee REAL DEFAULT 0,

    is_available INTEGER DEFAULT 1,
    availability_schedule TEXT,
    unavailable_dates TEXT,

    amenities TEXT,
    equipment TEXT,
    capacity_features TEXT,
    restrictions TEXT,

    is_verified INTEGER DEFAULT 0,
    verified_by TEXT,
    verified_at TEXT,
    verification_notes TEXT,
    status TEXT DEFAULT 'pending_verification',

    cover_image TEXT,
    gallery_images TEXT,
    virtual_tour_url TEXT,

    contact_name TEXT,
    contact_phone TEXT,
    contact_email TEXT,

    events_hosted INTEGER DEFAULT 0,
    rating REAL DEFAULT 0,
    review_count INTEGER DEFAULT 0,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    deleted_at TEXT
);

-- TICKETS TABLE
CREATE TABLE IF NOT EXISTS tickets (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,

    type TEXT NOT NULL,
    tier TEXT,
    name TEXT NOT NULL,
    description TEXT,

    price REAL NOT NULL CHECK (price >= 0),
    original_price REAL,
    service_fee REAL DEFAULT 0,
    processing_fee REAL DEFAULT 0,

    quantity INTEGER NOT NULL CHECK (quantity > 0),
    sold INTEGER DEFAULT 0,
    reserved INTEGER DEFAULT 0,
    max_per_user INTEGER DEFAULT 10,
    min_per_user INTEGER DEFAULT 1,

    sales_start TEXT,
    sales_end TEXT,
    early_bird_deadline TEXT,

    is_transferable INTEGER DEFAULT 1,
    is_refundable INTEGER DEFAULT 0,
    requires_id_check INTEGER DEFAULT 0,
    custom_fields TEXT,
    benefits TEXT,

    is_active INTEGER DEFAULT 1,
    is_hidden INTEGER DEFAULT 0,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES
CREATE INDEX idx_events_creator ON events(creator_id);
CREATE INDEX idx_events_venue ON events(venue_id);
CREATE INDEX idx_events_slug ON events(slug);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_category ON events(category);

CREATE INDEX idx_venues_creator ON venues(creator_id);
CREATE INDEX idx_venues_slug ON venues(slug);

CREATE INDEX idx_tickets_event ON tickets(event_id);
CREATE INDEX idx_tickets_active ON tickets(is_active);

-- TRIGGERS
CREATE TRIGGER update_events_updated_at
AFTER UPDATE ON events
FOR EACH ROW
BEGIN
    UPDATE events SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_venues_updated_at
AFTER UPDATE ON venues
FOR EACH ROW
BEGIN
    UPDATE venues SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_tickets_updated_at
AFTER UPDATE ON tickets
FOR EACH ROW
BEGIN
    UPDATE tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- EVENT-WITH-VENUE VIEW
CREATE VIEW IF NOT EXISTS event_with_venue AS
SELECT
    e.*,
    v.name as venue_name,
    v.address as venue_address,
    v.city as venue_city,
    v.coordinates as venue_coordinates,
    v.rating as venue_rating
FROM events e
LEFT JOIN venues v ON e.venue_id = v.id
WHERE e.deleted_at IS NULL;
