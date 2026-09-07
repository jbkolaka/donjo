-- =============================================
-- PAYMENT SERVICE DATABASE (SQLite)
-- =============================================

-- TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL,
    booking_id TEXT,

    transaction_type TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT DEFAULT 'KES',

    payment_method TEXT NOT NULL,
    payment_channel TEXT,

    status TEXT DEFAULT 'pending',
    status_reason TEXT,

    -- M-Pesa Specific
    mpesa_receipt TEXT,
    mpesa_request_id TEXT,
    mpesa_checkout_request_id TEXT,
    mpesa_phone_number TEXT,

    -- Wallet Specific
    wallet_before REAL,
    wallet_after REAL,

    -- Fees
    platform_fee REAL DEFAULT 0,
    processing_fee REAL DEFAULT 0,
    net_amount REAL,

    reference TEXT,
    metadata TEXT,

    initiated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    completed_at TEXT,
    failed_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ESCROW TABLE
CREATE TABLE IF NOT EXISTS escrows (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    booking_id TEXT NOT NULL,

    total_amount REAL NOT NULL,
    platform_fee REAL DEFAULT 0,
    organizer_amount REAL,
    refunded_amount REAL DEFAULT 0,

    status TEXT DEFAULT 'held',
    status_reason TEXT,

    release_date TEXT,
    release_condition TEXT,
    released_by TEXT,

    dispute_id TEXT,
    disputed_at TEXT,
    dispute_resolution TEXT,

    refund_id TEXT,
    refunded_at TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- REFUNDS TABLE
CREATE TABLE IF NOT EXISTS refunds (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    booking_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    transaction_id TEXT REFERENCES transactions(id) ON DELETE SET NULL,

    refund_amount REAL NOT NULL,
    platform_fee_refund REAL DEFAULT 0,
    total_refund REAL NOT NULL,

    refund_type TEXT DEFAULT 'full',
    refund_reason TEXT,
    refund_reason_details TEXT,

    status TEXT DEFAULT 'pending',
    status_reason TEXT,

    payment_method TEXT,
    refund_reference TEXT,
    mpesa_receipt TEXT,
    processed_at TEXT,
    processed_by TEXT,

    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- WALLET ENTRIES
CREATE TABLE IF NOT EXISTS wallet_entries (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL,

    type TEXT NOT NULL,
    amount REAL NOT NULL,
    balance_after REAL NOT NULL,

    source_type TEXT,
    source_id TEXT,

    description TEXT,
    reference TEXT,

    status TEXT DEFAULT 'completed',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- M-PESA CALLBACKS
CREATE TABLE IF NOT EXISTS mpesa_callbacks (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    request_id TEXT NOT NULL,
    checkout_request_id TEXT NOT NULL,

    result_code TEXT,
    result_desc TEXT,
    receipt_number TEXT,
    callback_data TEXT,

    processed INTEGER DEFAULT 0,
    processed_at TEXT,
    processing_error TEXT,

    received_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- INDEXES
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_booking ON transactions(booking_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_mpesa_request ON transactions(mpesa_request_id);

CREATE INDEX idx_escrows_booking ON escrows(booking_id);
CREATE INDEX idx_escrows_status ON escrows(status);

CREATE INDEX idx_refunds_booking ON refunds(booking_id);
CREATE INDEX idx_refunds_user ON refunds(user_id);

CREATE INDEX idx_wallet_entries_user ON wallet_entries(user_id);
CREATE INDEX idx_mpesa_callbacks_request ON mpesa_callbacks(request_id);

-- TRIGGERS
CREATE TRIGGER update_transactions_updated_at
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
    UPDATE transactions SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_escrows_updated_at
AFTER UPDATE ON escrows
FOR EACH ROW
BEGIN
    UPDATE escrows SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;

CREATE TRIGGER update_refunds_updated_at
AFTER UPDATE ON refunds
FOR EACH ROW
BEGIN
    UPDATE refunds SET updated_at = CURRENT_TIMESTAMP WHERE id = OLD.id;
END;