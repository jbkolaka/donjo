-- DONJO AUTHENTICATION DATABASE SCHEMA
-- SQLite
-- =============================================
-- 1. USERS TABLE (Core authentication)
-- =============================================
CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),

    -- Authentication credentials
    -- Plaintext email/phone are stored encrypted; the *_hash columns carry
    -- keyed fingerprints for unique lookups without ever matching on ciphertext.
    email TEXT UNIQUE NOT NULL,
    email_hash TEXT UNIQUE,
    password_hash TEXT NOT NULL,

    -- Personal information
    full_name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    date_of_birth TEXT,
    age INTEGER DEFAULT 18 CHECK (age >= 13 AND age <= 150),
    phone_number TEXT UNIQUE NOT NULL,
    phone_hash TEXT UNIQUE,
    mpesa_phone_number TEXT UNIQUE,
    mpesa_hash TEXT UNIQUE,

    -- Profile
    profile_image TEXT,
    bio TEXT,
    interests TEXT, -- JSON array of interests
    social_links TEXT, -- JSON object {twitter: "", linkedin: "", instagram: ""}

    -- Verification flags
    email_verified INTEGER DEFAULT 0,
    phone_verified INTEGER DEFAULT 0,
    identity_verified INTEGER DEFAULT 0,
    email_verified_at TEXT,
    phone_verified_at TEXT,
    identity_verified_at TEXT,

    -- Account status
    account_status TEXT DEFAULT 'active',
    suspension_reason TEXT,
    suspended_at TEXT,

    -- Admin flag
    is_admin INTEGER DEFAULT 0,

    -- Trust & reputation
    trust_score INTEGER DEFAULT 0,
    trust_level TEXT DEFAULT 'new',
    trust_score_components TEXT, -- JSON object
    trust_score_updated_at TEXT,

    -- Security
    two_factor_enabled INTEGER DEFAULT 0,
    two_factor_secret TEXT,
    backup_codes TEXT, -- JSON array of hashed backup codes

    -- Failed login tracking
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login TEXT,
    locked_until TEXT,

    -- Session tracking
    last_login_at TEXT,
    last_login_ip TEXT,
    last_login_device TEXT,

    -- Account statistics
    events_created INTEGER DEFAULT 0,
    tickets_sold INTEGER DEFAULT 0,
    venues_listed INTEGER DEFAULT 0,
    total_spent REAL DEFAULT 0,
    total_earned REAL DEFAULT 0,

    -- M-Pesa wallet
    wallet_balance REAL DEFAULT 0,
    wallet_currency TEXT DEFAULT 'KES',

    -- Referral system
    referral_code TEXT UNIQUE,
    referred_by TEXT REFERENCES users(id) ON DELETE SET NULL,

    -- Timestamps
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    deleted_at TEXT
);

-- =============================================
-- 2. SESSIONS / REFRESH TOKENS
-- =============================================
CREATE TABLE refresh_tokens (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    token_hash TEXT NOT NULL UNIQUE,
    token_type TEXT DEFAULT 'refresh',

    device_name TEXT,
    device_type TEXT,
    browser TEXT,
    os TEXT,
    ip_address TEXT,
    location TEXT,

    expires_at TEXT NOT NULL,
    revoked INTEGER DEFAULT 0,
    revoked_at TEXT,
    revoked_reason TEXT,

    last_used_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 3. EMAIL VERIFICATION TOKENS
-- =============================================
CREATE TABLE email_verification_tokens (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    token TEXT NOT NULL UNIQUE,
    type TEXT DEFAULT 'email_verification',

    expires_at TEXT NOT NULL,
    used INTEGER DEFAULT 0,
    used_at TEXT,

    request_ip TEXT,
    request_user_agent TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 4. PHONE VERIFICATION (OTP)
-- =============================================
CREATE TABLE phone_verifications (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    phone_number TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    otp_type TEXT DEFAULT 'verification',

    expires_at TEXT NOT NULL,
    verified INTEGER DEFAULT 0,
    verified_at TEXT,

    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,

    request_ip TEXT,
    request_user_agent TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 5. PASSWORD RESET
-- =============================================
CREATE TABLE password_resets (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    token TEXT NOT NULL UNIQUE,
    reset_type TEXT DEFAULT 'password',

    expires_at TEXT NOT NULL,
    used INTEGER DEFAULT 0,
    used_at TEXT,

    request_ip TEXT,
    request_user_agent TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 6. TWO-FACTOR AUTHENTICATION
-- =============================================
CREATE TABLE two_factor_auth (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    secret TEXT NOT NULL,
    backup_codes TEXT NOT NULL, -- JSON array of hashed backup codes

    enabled INTEGER DEFAULT 1,
    verified INTEGER DEFAULT 0,

    recovery_email TEXT,
    recovery_phone TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 7. LOGIN HISTORY (Audit)
-- =============================================
CREATE TABLE login_history (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    login_type TEXT,
    success INTEGER NOT NULL,
    failure_reason TEXT,

    ip_address TEXT,
    user_agent TEXT,
    device_name TEXT,
    device_type TEXT,
    browser TEXT,
    os TEXT,
    country TEXT,
    city TEXT,

    session_id TEXT REFERENCES refresh_tokens(id) ON DELETE SET NULL,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 8. USER ACTIVITY LOG
-- =============================================
CREATE TABLE user_activity_log (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    activity_type TEXT NOT NULL,
    activity_data TEXT, -- JSON object

    ip_address TEXT,
    user_agent TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 9. SOCIAL ACCOUNTS (OAuth)
-- =============================================
CREATE TABLE social_accounts (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    provider TEXT NOT NULL,
    provider_id TEXT NOT NULL,
    provider_email TEXT,

    profile_data TEXT, -- JSON object
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TEXT,

    verified INTEGER DEFAULT 1,
    linked_at TEXT DEFAULT CURRENT_TIMESTAMP,
    last_used_at TEXT,

    UNIQUE(provider, provider_id)
);

-- =============================================
-- 10. TOKEN BLOCKLIST
-- =============================================
CREATE TABLE token_blocklist (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),

    token_jti TEXT NOT NULL UNIQUE,
    token_type TEXT NOT NULL,

    reason TEXT,
    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,

    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 11. RATE LIMITING
-- =============================================
CREATE TABLE rate_limits (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),

    key TEXT NOT NULL,
    action TEXT NOT NULL,
    window_start TEXT NOT NULL,
    attempts INTEGER DEFAULT 0,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(key, action, window_start)
);

-- =============================================
-- 12. USER PREFERENCES
-- =============================================
CREATE TABLE user_preferences (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,

    email_notifications INTEGER DEFAULT 1,
    sms_notifications INTEGER DEFAULT 1,
    push_notifications INTEGER DEFAULT 1,
    marketing_emails INTEGER DEFAULT 0,

    login_alerts INTEGER DEFAULT 1,
    transaction_alerts INTEGER DEFAULT 1,

    language TEXT DEFAULT 'en',
    timezone TEXT DEFAULT 'Africa/Nairobi',
    currency TEXT DEFAULT 'KES',

    profile_visibility TEXT DEFAULT 'public',
    show_email INTEGER DEFAULT 0,
    show_phone INTEGER DEFAULT 0,

    theme TEXT DEFAULT 'light',
    notifications_sound INTEGER DEFAULT 1,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 13. AUDIT LOG
-- =============================================
CREATE TABLE audit_log (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),

    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    admin_id TEXT REFERENCES users(id) ON DELETE SET NULL,

    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id TEXT,

    changes TEXT, -- JSON object
    ip_address TEXT,
    user_agent TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- INDEXES
-- =============================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_mpesa ON users(mpesa_phone_number);
CREATE INDEX idx_users_status ON users(account_status);
CREATE INDEX idx_users_trust ON users(trust_score);
CREATE INDEX idx_users_created ON users(created_at);
CREATE INDEX idx_users_referral ON users(referral_code);
CREATE INDEX idx_users_referred_by ON users(referred_by);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_revoked ON refresh_tokens(revoked);

CREATE INDEX idx_email_verification_user ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_token ON email_verification_tokens(token);
CREATE INDEX idx_email_verification_expires ON email_verification_tokens(expires_at);

CREATE INDEX idx_phone_verification_user ON phone_verifications(user_id);
CREATE INDEX idx_phone_verification_phone ON phone_verifications(phone_number);
CREATE INDEX idx_phone_verification_expires ON phone_verifications(expires_at);

CREATE INDEX idx_password_resets_user ON password_resets(user_id);
CREATE INDEX idx_password_resets_token ON password_resets(token);
CREATE INDEX idx_password_resets_expires ON password_resets(expires_at);

CREATE INDEX idx_login_history_user ON login_history(user_id);
CREATE INDEX idx_login_history_created ON login_history(created_at);
CREATE INDEX idx_login_history_ip ON login_history(ip_address);

CREATE INDEX idx_user_activity_user ON user_activity_log(user_id);
CREATE INDEX idx_user_activity_type ON user_activity_log(activity_type);
CREATE INDEX idx_user_activity_created ON user_activity_log(created_at);

CREATE INDEX idx_social_accounts_user ON social_accounts(user_id);
CREATE INDEX idx_social_accounts_provider ON social_accounts(provider, provider_id);

CREATE INDEX idx_token_blocklist_jti ON token_blocklist(token_jti);
CREATE INDEX idx_token_blocklist_expires ON token_blocklist(expires_at);

CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_audit_log_created ON audit_log(created_at);
CREATE INDEX idx_audit_log_action ON audit_log(action);

-- =============================================
-- TRIGGERS (manual updated_at maintenance)
-- =============================================

CREATE TRIGGER update_users_updated_at
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_refresh_tokens_updated_at
AFTER UPDATE ON refresh_tokens
FOR EACH ROW
BEGIN
    UPDATE refresh_tokens SET created_at = created_at WHERE id = OLD.id;
END;

CREATE TRIGGER update_user_preferences_updated_at
AFTER UPDATE ON user_preferences
FOR EACH ROW
BEGIN
    UPDATE user_preferences SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

-- =============================================
-- DEFAULT DATA
-- =============================================

INSERT INTO users (
    id,
    email,
    password_hash,
    full_name,
    username,
    age,
    phone_number,
    mpesa_phone_number,
    is_admin,
    email_verified,
    phone_verified,
    identity_verified,
    account_status,
    trust_score,
    trust_level
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'admin@donjo.com',
    'CHANGE_ME_IN_APPLICATION',
    'Donjo Admin',
    'admin',
    30,
    '254700000000',
    '254700000000',
    1,
    1,
    1,
    1,
    'active',
    100,
    'verified'
) ON CONFLICT (email) DO NOTHING;
