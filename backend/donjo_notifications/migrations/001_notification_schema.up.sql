-- =============================================
-- NOTIFICATION SERVICE DATABASE (SQLite)
-- Ported from the Postgres schema. Storage-aware substitutions:
--   * UUID          -> TEXT, ids minted by the application as canonical
--                      hex UUIDs (same ids used across the microservices)
--   * JSONB         -> JSON (TEXT)
--   * TEXT[]        -> JSON array (TEXT)
--   * BOOLEAN       -> 0/1 INTEGER
--   * TIMESTAMP     -> TEXT (RFC3339 from the application, or
--                      CURRENT_TIMESTAMP as a harmless default)
--   * DEFAULT uuid_generate_v4() / CURRENT_TIMESTAMP -> application-provided
--                      ids/timestamps; CURRENT_TIMESTAMP kept where a DB
--                      default is harmless
-- =============================================

-- NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,

    channel TEXT NOT NULL,

    type TEXT NOT NULL,
    subject TEXT,
    content TEXT NOT NULL,
    html_content TEXT,

    template_id TEXT,
    template_data TEXT,

    status TEXT NOT NULL DEFAULT 'pending',
    sent_at TEXT,
    delivered_at TEXT,
    read_at TEXT,
    clicked_at TEXT,

    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    priority TEXT NOT NULL DEFAULT 'medium',

    reference_id TEXT,
    reference_type TEXT,
    metadata TEXT,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- USER FEED TABLE
CREATE TABLE IF NOT EXISTS user_feeds (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    notification_id TEXT REFERENCES notifications(id) ON DELETE CASCADE,

    feed_type TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 0,
    position INTEGER,

    title TEXT,
    message TEXT,
    image_url TEXT,

    viewed INTEGER NOT NULL DEFAULT 0,
    viewed_at TEXT,
    clicked INTEGER NOT NULL DEFAULT 0,
    clicked_at TEXT,
    interacted INTEGER NOT NULL DEFAULT 0,
    interacted_at TEXT,

    expires_at TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- NOTIFICATION TEMPLATES
CREATE TABLE IF NOT EXISTS notification_templates (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL,
    subject_template TEXT,
    content_template TEXT NOT NULL,
    html_template TEXT,
    required_variables TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- PUSH DEVICES
CREATE TABLE IF NOT EXISTS push_devices (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,

    device_token TEXT NOT NULL,
    platform TEXT NOT NULL,
    device_id TEXT,
    device_name TEXT,

    is_active INTEGER NOT NULL DEFAULT 1,
    last_used_at TEXT,

    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, device_token)
);

-- INDEXES
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

CREATE INDEX IF NOT EXISTS idx_user_feeds_user ON user_feeds(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feeds_created ON user_feeds(created_at);
CREATE INDEX IF NOT EXISTS idx_user_feeds_viewed ON user_feeds(user_id, viewed);

CREATE INDEX IF NOT EXISTS idx_push_devices_user ON push_devices(user_id);

-- =============================================
-- DEFAULT TEMPLATES
-- Simple {{variable}} placeholders rendered at send time.
-- =============================================

INSERT OR IGNORE INTO notification_templates
    (id, name, type, subject_template, content_template, required_variables)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'purchase_confirmation', 'notification',
     'Your tickets are confirmed',
     'You''re going to {{event_title}}! {{quantity}} x {{ticket_name}} (order {{order_id}}).',
     '["event_title", "quantity", "ticket_name", "order_id"]'),
    ('00000000-0000-0000-0000-000000000002', 'sale_alert', 'notification',
     'New sale!',
     '{{quantity}} x {{ticket_name}} sold for {{event_title}}.',
     '["quantity", "ticket_name", "event_title"]'),
    ('00000000-0000-0000-0000-000000000003', 'event_discovery', 'feed',
     NULL,
     '{{title}} is coming up on Donjo — reserve your spot.',
     '["title"]'),
    ('00000000-0000-0000-0000-000000000004', 'welcome', 'notification',
     'Welcome to Donjo',
     'Thanks for joining, {{full_name}} — discover events near you.',
     '["full_name"]');