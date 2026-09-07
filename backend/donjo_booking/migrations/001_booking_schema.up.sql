-- =============================================
-- DONJO BOOKING SERVICE — SQLite schema
-- Bookings, per-seat ticket instances (QR), scan
-- logs, gate locations, and the event waitlist.
-- =============================================

-- BOOKINGS ------------------------------------------------------------------
-- One row per checkout. Every purchased quantity has exactly one booking.
CREATE TABLE IF NOT EXISTS bookings (
    id               TEXT PRIMARY KEY,
    user_id          TEXT NOT NULL,
    event_id         TEXT NOT NULL,
    ticket_id        TEXT NOT NULL,

    booking_reference TEXT UNIQUE NOT NULL,
    order_number     TEXT UNIQUE,

    -- Denormalized ticket context (snapshot at purchase time).
    event_title      TEXT NOT NULL,
    event_slug       TEXT,
    ticket_type      TEXT NOT NULL,
    ticket_name      TEXT NOT NULL,
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    unit_price       REAL NOT NULL CHECK (unit_price >= 0),
    total_amount     REAL NOT NULL CHECK (total_amount >= 0),

    -- Fees
    service_fee      REAL NOT NULL DEFAULT 0,
    processing_fee   REAL NOT NULL DEFAULT 0,
    platform_fee     REAL NOT NULL DEFAULT 0,
    net_amount       REAL,

    -- Payment
    payment_method   TEXT,
    payment_status   TEXT NOT NULL DEFAULT 'paid',
    payment_date     TEXT,
    transaction_id   TEXT,
    escrow_id        TEXT,
    escrow_status    TEXT,

    -- Status
    status           TEXT NOT NULL DEFAULT 'confirmed',
    status_reason    TEXT,

    -- Attendee (buyer snapshot; per-ticket holders live on ticket_instances)
    attendee_name    TEXT,
    attendee_email   TEXT,
    attendee_phone   TEXT,
    attendee_notes   TEXT,
    custom_answers   TEXT,

    -- Metadata
    booking_ip       TEXT,
    booking_user_agent TEXT,
    referral_source  TEXT,

    created_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at     TEXT,
    completed_at     TEXT,
    deleted_at       TEXT
);

-- TICKET INSTANCES -----------------------------------------------------------
-- One row per seat, with a unique admission code (QR payload). Group tickets
-- are individual instances each assigned to a named holder.
CREATE TABLE IF NOT EXISTS ticket_instances (
    id               TEXT PRIMARY KEY,
    booking_id       TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    ticket_id        TEXT NOT NULL,
    event_id         TEXT NOT NULL,
    user_id          TEXT NOT NULL,          -- current holder (owner account)

    -- Unique identifiers
    ticket_code      TEXT UNIQUE NOT NULL,   -- rotates on every ownership change
    qr_code_data     TEXT NOT NULL,
    qr_code_image_url TEXT,
    qr_code_asset_id TEXT,
    barcode          TEXT,

    -- Named ticket holder (group assignment)
    holder_name      TEXT,
    holder_email     TEXT,
    holder_phone     TEXT,

    -- Status machine: active|pending_claim|listed|resold|used|void
    status           TEXT NOT NULL DEFAULT 'active',
    used_at          TEXT,
    used_by          TEXT,

    -- Transfer / share
    transfer_allowed INTEGER NOT NULL DEFAULT 1,
    transferred      INTEGER NOT NULL DEFAULT 0,
    transferred_from TEXT,
    transferred_to   TEXT,
    transferred_at   TEXT,
    transfer_code    TEXT UNIQUE,

    -- Resale
    listed_price     REAL,
    listed_at        TEXT,
    unlisted_at      TEXT,
    resold_price     REAL,
    resold_at        TEXT,

    -- Check-in
    check_in_code    TEXT UNIQUE,
    checked_in       INTEGER NOT NULL DEFAULT 0,
    checked_in_at    TEXT,
    checked_in_by    TEXT,
    check_in_location TEXT,
    check_in_ip      TEXT,
    scan_count       INTEGER NOT NULL DEFAULT 0,
    last_scanned_at  TEXT,

    -- Special access
    vip_access       INTEGER NOT NULL DEFAULT 0,
    special_notes    TEXT,
    is_valid         INTEGER NOT NULL DEFAULT 1,
    invalidation_reason TEXT,

    created_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- QR SCAN LOGS ---------------------------------------------------------------
-- Every gate scan attempt, success or failure.
CREATE TABLE IF NOT EXISTS qr_scan_logs (
    id               TEXT PRIMARY KEY,
    ticket_instance_id TEXT NOT NULL REFERENCES ticket_instances(id) ON DELETE CASCADE,
    event_id         TEXT NOT NULL,
    booking_id       TEXT NOT NULL,
    scanner_id       TEXT NOT NULL,
    user_id          TEXT NOT NULL,

    scan_type        TEXT NOT NULL DEFAULT 'entry',
    scan_result      TEXT NOT NULL DEFAULT 'success',
    qr_code_scanned  TEXT,
    scan_location    TEXT,
    scan_location_name TEXT,
    scan_ip          TEXT,
    scan_device_info TEXT,

    scanner_device_id TEXT,
    scanner_app_version TEXT,

    response_message TEXT,
    response_code    TEXT,
    ticket_status_before TEXT,
    ticket_status_after TEXT,

    metadata         TEXT,
    created_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- SCAN LOCATIONS ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scan_locations (
    id               TEXT PRIMARY KEY,
    event_id         TEXT NOT NULL,

    name             TEXT NOT NULL,
    description      TEXT,
    address          TEXT,
    coordinates      TEXT,
    radius           INTEGER NOT NULL DEFAULT 50,
    opens_at         TEXT,
    closes_at        TEXT,
    allowed_ticket_types TEXT,
    requires_extra_verification INTEGER NOT NULL DEFAULT 0,
    assigned_staff   TEXT,
    is_active        INTEGER NOT NULL DEFAULT 1,
    is_primary       INTEGER NOT NULL DEFAULT 0,

    total_scans      INTEGER NOT NULL DEFAULT 0,
    success_scans    INTEGER NOT NULL DEFAULT 0,
    failed_scans     INTEGER NOT NULL DEFAULT 0,

    created_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- WAITLIST ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS waitlist (
    id               TEXT PRIMARY KEY,
    event_id         TEXT NOT NULL,
    user_id          TEXT NOT NULL,
    ticket_type      TEXT,
    quantity         INTEGER NOT NULL DEFAULT 1,
    status           TEXT NOT NULL DEFAULT 'active',
    offer_sent       INTEGER NOT NULL DEFAULT 0,
    offer_sent_at    TEXT,
    offer_expires_at TEXT,
    booking_id       TEXT,
    converted_at     TEXT,
    created_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(event_id, user_id)
);

-- INDEXES -----------------------------------------------------------------------
CREATE INDEX idx_bookings_user      ON bookings(user_id);
CREATE INDEX idx_bookings_event     ON bookings(event_id);
CREATE INDEX idx_bookings_reference ON bookings(booking_reference);
CREATE INDEX idx_bookings_status    ON bookings(status);

CREATE INDEX idx_instances_booking  ON ticket_instances(booking_id);
CREATE INDEX idx_instances_code     ON ticket_instances(ticket_code);
CREATE INDEX idx_instances_check_in ON ticket_instances(check_in_code);
CREATE INDEX idx_instances_event    ON ticket_instances(event_id);
CREATE INDEX idx_instances_user     ON ticket_instances(user_id);
CREATE INDEX idx_instances_status   ON ticket_instances(status);
CREATE INDEX idx_instances_listed   ON ticket_instances(status, listed_price);

CREATE INDEX idx_scan_logs_ticket   ON qr_scan_logs(ticket_instance_id);
CREATE INDEX idx_scan_logs_event    ON qr_scan_logs(event_id);
CREATE INDEX idx_scan_logs_scanner  ON qr_scan_logs(scanner_id);

CREATE INDEX idx_scan_locations_event ON scan_locations(event_id);
CREATE INDEX idx_waitlist_event     ON waitlist(event_id);
CREATE INDEX idx_waitlist_user      ON waitlist(user_id);

-- TRIGGERS ----------------------------------------------------------------------
CREATE TRIGGER update_bookings_updated_at
AFTER UPDATE ON bookings FOR EACH ROW
BEGIN
    UPDATE bookings SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_instances_updated_at
AFTER UPDATE ON ticket_instances FOR EACH ROW
BEGIN
    UPDATE ticket_instances SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_scan_locations_updated_at
AFTER UPDATE ON scan_locations FOR EACH ROW
BEGIN
    UPDATE scan_locations SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_waitlist_updated_at
AFTER UPDATE ON waitlist FOR EACH ROW
BEGIN
    UPDATE waitlist SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;