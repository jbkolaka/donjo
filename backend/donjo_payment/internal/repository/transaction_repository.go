package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"donjo_payment/internal/models"
)

// TransactionRepository owns the transactions / escrows / wallet_entries
// tables. Money movements are written together in one SQLite transaction so a
// purchase always lands as transaction + escrow + ledger entry or not at all.
type TransactionRepository struct {
	db *sql.DB
}

func NewTransactionRepository(db *sql.DB) *TransactionRepository {
	return &TransactionRepository{db: db}
}

const transactionSelect = `
SELECT t.id, t.user_id, t.booking_id, t.transaction_type, t.amount, t.currency,
       t.payment_method, t.payment_channel, t.status, t.status_reason,
       t.mpesa_receipt, t.mpesa_request_id, t.mpesa_checkout_request_id, t.mpesa_phone_number,
       t.wallet_before, t.wallet_after, t.platform_fee, t.processing_fee, t.net_amount,
       t.reference, t.metadata, t.initiated_at, t.completed_at, t.failed_at, t.created_at, t.updated_at,
       e.id, e.booking_id, e.total_amount, e.platform_fee, e.organizer_amount, e.refunded_amount,
       e.status, e.status_reason, e.release_date, e.release_condition, e.released_by,
       e.dispute_id, e.disputed_at, e.dispute_resolution, e.refund_id, e.refunded_at,
       e.created_at, e.updated_at
FROM transactions t
LEFT JOIN escrows e ON e.booking_id = t.reference`

// RecordPurchase writes the money movement for one completed purchase as a
// single unit: a paid M-Pesa transaction, a held escrow for the organizer's
// payout, and a credit line in the organizer's wallet ledger.
//
// The escrow is linked by the order id (escrows.booking_id = order id) because
// the payment service does not yet know the booking UUID; donjo_booking
// backfills the real pairing on the booking side.
func (r *TransactionRepository) RecordPurchase(p models.PurchaseSnapshot) (*models.Transaction, *models.Escrow, error) {
	tx, err := r.db.Begin()
	if err != nil {
		return nil, nil, err
	}
	defer tx.Rollback()

	// Idempotency: a redelivered ticket.purchased (consumer crash after commit)
	// must not mint a second transaction. When the order already exists, the
	// first attempt won, so return the existing rows.
	var existing string
	if err := tx.QueryRow(`SELECT id FROM transactions WHERE reference = ? LIMIT 1`, p.OrderID).Scan(&existing); err == nil && existing != "" {
		if err := tx.Commit(); err != nil {
			return nil, nil, err
		}
		tr, err := r.GetForUser(existing, p.UserID)
		if err != nil {
			return nil, nil, err
		}
		esc, err := r.getEscrowByBooking(p.OrderID)
		if err != nil {
			return nil, nil, err
		}
		return tr, esc, nil
	}

	now := time.Now().UTC()
	nowStr := now.Format(time.RFC3339)
	currency := p.Currency
	if currency == "" {
		currency = "KES"
	}

	txnID, err := newID(tx)
	if err != nil {
		return nil, nil, err
	}
	escrowID, err := newID(tx)
	if err != nil {
		return nil, nil, err
	}

	platformFee := p.ServiceFee + p.ProcessingFee
	netAmount := p.Amount - platformFee
	organizerAmount := netAmount

	_, err = tx.Exec(`
		INSERT INTO transactions (
			id, user_id, booking_id, transaction_type, amount, currency,
			payment_method, payment_channel, status, status_reason,
			mpesa_phone_number, platform_fee, processing_fee, net_amount,
			reference, metadata, initiated_at, completed_at, created_at, updated_at
		) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
		txnID, p.UserID, nil, models.TypePurchase, p.Amount, currency,
		models.MethodMpesa, models.ChannelMpesaExpress, models.StatusPaid, "",
		"", platformFee, p.ProcessingFee, netAmount,
		p.OrderID, nil, nowStr, nowStr, nowStr, nowStr,
	)
	if err != nil {
		return nil, nil, fmt.Errorf("insert transaction: %w", err)
	}

	escrowBookingID := p.OrderID // see RecordPurchase doc comment
	_, err = tx.Exec(`
		INSERT INTO escrows (
			id, booking_id, total_amount, platform_fee, organizer_amount,
			refunded_amount, status, status_reason, release_condition,
			created_at, updated_at
		) VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
		escrowID, escrowBookingID, p.Amount, platformFee, organizerAmount,
		0, models.EscrowHeld, "", "event_completed", nowStr, nowStr,
	)
	if err != nil {
		return nil, nil, fmt.Errorf("insert escrow: %w", err)
	}

	var balance float64
	if err := tx.QueryRow(
		`SELECT COALESCE(SUM(amount), 0) FROM wallet_entries WHERE user_id = ? AND status = 'completed'`,
		p.CreatorID,
	).Scan(&balance); err != nil {
		return nil, nil, err
	}

	walletID, err := newID(tx)
	if err != nil {
		return nil, nil, err
	}
	balanceAfter := balance + organizerAmount

	_, err = tx.Exec(`
		INSERT INTO wallet_entries (
			id, user_id, type, amount, balance_after, source_type, source_id,
			description, reference, status, created_at
		) VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
		walletID, p.CreatorID, models.WalletCredit, organizerAmount, balanceAfter,
		"escrow", escrowID, "Organizer hold for "+p.EventTitle, p.OrderID, "completed", nowStr,
	)
	if err != nil {
		return nil, nil, fmt.Errorf("insert wallet entry: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return nil, nil, err
	}

	tr, err := r.GetForUser(txnID, p.UserID)
	if err != nil {
		return nil, nil, err
	}
	esc, err := r.getEscrowByBooking(escrowBookingID)
	if err != nil {
		return nil, nil, err
	}
	return tr, esc, nil
}

// GetForUser returns one transaction owned by the given user (nil when absent).
func (r *TransactionRepository) GetForUser(id, userID string) (*models.Transaction, error) {
	row := r.db.QueryRow(transactionSelect+` WHERE t.id = ? AND t.user_id = ?`, id, userID)
	t, err := scanTransaction(row)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return t, err
}

// ListByUser returns the user's transactions, newest first.
func (r *TransactionRepository) ListByUser(userID string) ([]*models.Transaction, error) {
	rows, err := r.db.Query(transactionSelect+` WHERE t.user_id = ? ORDER BY t.created_at DESC, t.id DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*models.Transaction
	for rows.Next() {
		t, err := scanTransaction(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

// GetEscrowForUser returns one escrow if it belongs to a transaction the given
// user owns (escrows are linked to the purchase via the order reference).
func (r *TransactionRepository) GetEscrowForUser(id, userID string) (*models.Escrow, error) {
	row := r.db.QueryRow(`
		SELECT e.id, e.booking_id, e.total_amount, e.platform_fee, e.organizer_amount,
		       e.refunded_amount, e.status, e.status_reason, e.release_date,
		       e.release_condition, e.released_by, e.dispute_id, e.disputed_at,
		       e.dispute_resolution, e.refund_id, e.refunded_at, e.created_at, e.updated_at
		FROM escrows e
		JOIN transactions t ON t.reference = e.booking_id
		WHERE e.id = ? AND t.user_id = ?`,
		id, userID)
	esc, err := scanEscrow(row)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return esc, err
}

func (r *TransactionRepository) getEscrowByBooking(orderID string) (*models.Escrow, error) {
	row := r.db.QueryRow(`
		SELECT id, booking_id, total_amount, platform_fee, organizer_amount,
		       refunded_amount, status, status_reason, release_date,
		       release_condition, released_by, dispute_id, disputed_at,
		       dispute_resolution, refund_id, refunded_at, created_at, updated_at
		FROM escrows WHERE booking_id = ?`,
		orderID)
	esc, err := scanEscrow(row)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return esc, err
}

type scanner interface {
	Scan(dest ...interface{}) error
}

func scanTransaction(row scanner) (*models.Transaction, error) {
	var t models.Transaction
	var bookingID, channel, statusReason, mpesaReceipt, mpesaRequestID sql.NullString
	var mpesaCheckout, mpesaPhone sql.NullString
	var walletBefore, walletAfter sql.NullFloat64
	var metadata sql.NullString
	var initiatedAt, completedAt, failedAt, createdTime, updatedTime sql.NullString
	var esc models.Escrow
	var escBookingID, escStatusReason, escReleaseCond, escReleasedBy sql.NullString
	var escDisputeID, escDisputeRes, escRefundID sql.NullString
	var escOrganizer, escRefunded sql.NullFloat64
	var escReleaseDate, escDisputedAt, escRefundedAt sql.NullString
	var escCreatedAt, escUpdatedAt sql.NullString

	err := row.Scan(
		&t.ID, &t.UserID, &bookingID, &t.TransactionType, &t.Amount, &t.Currency,
		&t.PaymentMethod, &channel, &t.Status, &statusReason,
		&mpesaReceipt, &mpesaRequestID, &mpesaCheckout, &mpesaPhone,
		&walletBefore, &walletAfter, &t.PlatformFee, &t.ProcessingFee, &t.NetAmount,
		&t.Reference, &metadata, &initiatedAt, &completedAt, &failedAt, &createdTime, &updatedTime,
		&esc.ID, &escBookingID, &esc.TotalAmount, &esc.PlatformFee, &escOrganizer, &escRefunded,
		&esc.Status, &escStatusReason, &escReleaseDate, &escReleaseCond, &escReleasedBy,
		&escDisputeID, &escDisputedAt, &escDisputeRes, &escRefundID, &escRefundedAt,
		&escCreatedAt, &escUpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	t.BookingID = bookingID.String
	t.PaymentChannel = channel.String
	t.StatusReason = statusReason.String
	t.MpesaReceipt = mpesaReceipt.String
	t.MpesaRequestID = mpesaRequestID.String
	t.MpesaCheckoutRequestID = mpesaCheckout.String
	t.MpesaPhoneNumber = mpesaPhone.String
	t.WalletBefore = fptr(walletBefore.Valid, walletBefore.Float64)
	t.WalletAfter = fptr(walletAfter.Valid, walletAfter.Float64)
	if metadata.Valid {
		var m map[string]any
		if err := json.Unmarshal([]byte(metadata.String), &m); err == nil {
			t.Metadata = m
		}
	}
	t.CompletedAt = scanTime(completedAt)
	t.FailedAt = scanTime(failedAt)
	t.InitiatedAt = mustTime(initiatedAt.String)
	t.CreatedAt = mustTime(createdTime.String)
	t.UpdatedAt = mustTime(updatedTime.String)

	// Attach the escrow half of the purchase flow when the join matched.
	if esc.ID != "" {
		esc.BookingID = escBookingID.String
		esc.StatusReason = escStatusReason.String
		esc.ReleaseCondition = escReleaseCond.String
		esc.ReleasedBy = escReleasedBy.String
		esc.DisputeID = escDisputeID.String
		esc.DisputeResolution = escDisputeRes.String
		esc.RefundID = escRefundID.String
		esc.OrganizerAmount = escOrganizer.Float64
		esc.RefundedAmount = escRefunded.Float64
		esc.ReleaseDate = scanTime(escReleaseDate)
		esc.DisputedAt = scanTime(escDisputedAt)
		esc.RefundedAt = scanTime(escRefundedAt)
		esc.CreatedAt = mustTime(escCreatedAt.String)
		esc.UpdatedAt = mustTime(escUpdatedAt.String)
		t.Escrow = &esc
	}

	return &t, nil
}

func scanEscrow(row scanner) (*models.Escrow, error) {
	var e models.Escrow
	var bookingID, statusReason, releaseCond, releasedBy sql.NullString
	var disputeID, disputeRes, refundID sql.NullString
	var organizer, refunded sql.NullFloat64
	var releaseDate, disputedAt, refundedAt, createdAt, updatedAt sql.NullString

	err := row.Scan(
		&e.ID, &bookingID, &e.TotalAmount, &e.PlatformFee, &organizer, &refunded,
		&e.Status, &statusReason, &releaseDate, &releaseCond, &releasedBy,
		&disputeID, &disputedAt, &disputeRes, &refundID, &refundedAt, &createdAt, &updatedAt,
	)
	if err != nil {
		return nil, err
	}
	e.BookingID = bookingID.String
	e.StatusReason = statusReason.String
	e.ReleaseCondition = releaseCond.String
	e.ReleasedBy = releasedBy.String
	e.DisputeID = disputeID.String
	e.DisputeResolution = disputeRes.String
	e.RefundID = refundID.String
	e.OrganizerAmount = organizer.Float64
	e.RefundedAmount = refunded.Float64
	e.ReleaseDate = scanTime(releaseDate)
	e.DisputedAt = scanTime(disputedAt)
	e.RefundedAt = scanTime(refundedAt)
	e.CreatedAt = mustTime(createdAt.String)
	e.UpdatedAt = mustTime(updatedAt.String)
	return &e, nil
}
