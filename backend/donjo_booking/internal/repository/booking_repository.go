package repository

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"math/big"
	"time"

	"donjo_booking/internal/models"
)

// BookingRepository persists checkout orders (bookings) and their ticket
// instances. Creation is atomic: one booking + N instances per purchase.
type BookingRepository struct {
	db *sql.DB
}

func NewBookingRepository(db *sql.DB) *BookingRepository {
	return &BookingRepository{db: db}
}

// CreateFromPurchase atomically records a booking and mints one ticket
// instance per seat from a consumed ticket.purchased event.
func (r *BookingRepository) CreateFromPurchase(p models.BookingSnapshot) (*models.Booking, error) {
	tx, err := r.db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// The order id is the purchase's one canonical reference, shared by
	// event -> payment -> booking (payment backfills bookings.order_number
	// via payment.processed), so it must come from the message.
	if p.OrderID == "" {
		return nil, errors.New("order id is required")
	}
	// Idempotency: a redelivered ticket.purchased (consumer crash after
	// commit) must not mint a second booking for the same order.
	var existsID string
	if err := tx.QueryRow(`SELECT id FROM bookings WHERE order_number = ?`, p.OrderID).Scan(&existsID); err == nil && existsID != "" {
		if err := tx.Commit(); err != nil {
			return nil, err
		}
		return r.Get(existsID)
	}

	id, err := newID(tx)
	if err != nil {
		return nil, err
	}
	ref, err := r.uniqueReference(tx)
	if err != nil {
		return nil, err
	}
	orderNumber := p.OrderID
	paymentDate := time.Now().UTC().Format(time.RFC3339)
	unit := p.UnitPrice + p.ServiceFee + p.ProcessingFee
	total := float64(p.Quantity) * unit
	net := total - float64(p.Quantity)*(p.ServiceFee+p.ProcessingFee)

	_, err = tx.Exec(`
		INSERT INTO bookings (
			id, user_id, event_id, ticket_id, booking_reference, order_number,
			event_title, event_slug, ticket_type, ticket_name, quantity,
			unit_price, total_amount, service_fee, processing_fee, platform_fee,
			net_amount, payment_status, payment_date, status, attendee_email,
			booking_ip, booking_user_agent
		) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
		id, p.UserID, p.EventID, p.TicketID, ref, orderNumber,
		p.EventTitle, p.EventSlug, p.TicketType, p.TicketName, p.Quantity,
		unit, total, p.ServiceFee, p.ProcessingFee, 0,
		net, "paid", paymentDate, "confirmed", p.UserEmail,
		"", "",
	)
	if err != nil {
		return nil, err
	}

	for i := 0; i < p.Quantity; i++ {
		inID, err := newID(tx)
		if err != nil {
			return nil, err
		}
		code := newLargeToken()
		_, err = tx.Exec(`
			INSERT INTO ticket_instances (
				id, booking_id, ticket_id, event_id, user_id, ticket_code, qr_code_data,
				barcode, holder_email, status, transfer_allowed
			) VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
			inID, id, p.TicketID, p.EventID, p.UserID, code, "DONJO:"+ref+":"+code,
			code, p.UserEmail, models.InstanceActive, 1,
		)
		if err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return r.Get(id)
}

// uniqueReference generates an unused "DONJO-XXXXXX" reference.
func (r *BookingRepository) uniqueReference(tx *sql.Tx) (string, error) {
	for i := 0; i < 5; i++ {
		ref := "DONJO-" + bookingCode()
		var exists int
		if err := tx.QueryRow(`SELECT COUNT(1) FROM bookings WHERE booking_reference = ?`, ref).Scan(&exists); err != nil {
			return "", err
		}
		if exists == 0 {
			return ref, nil
		}
	}
	return "", fmt.Errorf("failed to allocate a unique booking reference")
}

func bookingCode() string {
	const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	out := make([]byte, 6)
	for i := range out {
		n, _ := rand.Int(rand.Reader, big.NewInt(int64(len(alphabet))))
		out[i] = alphabet[n.Int64()]
	}
	return string(out)
}

func randBytes(n int) []byte {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return b
}

func newLargeToken() string {
	return hex.EncodeToString(randBytes(16))
}

var bookingColumns = `
	b.id, b.user_id, b.event_id, b.ticket_id, b.booking_reference, b.order_number,
	b.event_title, b.event_slug, b.ticket_type, b.ticket_name, b.quantity,
	b.unit_price, b.total_amount, b.service_fee, b.processing_fee, b.platform_fee,
	b.net_amount, b.payment_method, b.payment_status, b.payment_date, b.transaction_id,
	b.escrow_id, b.escrow_status, b.status, b.status_reason, b.attendee_name,
	b.attendee_email, b.attendee_phone, b.attendee_notes, b.custom_answers,
	b.created_at, b.updated_at, b.cancelled_at, b.completed_at`

type bookingRow struct {
	ID             string
	UserID         string
	EventID        string
	TicketID       string
	BookingReference string
	OrderNumber    sql.NullString
	EventTitle     string
	EventSlug      sql.NullString
	TicketType     string
	TicketName     string
	Quantity       int
	UnitPrice      float64
	TotalAmount    float64
	ServiceFee     float64
	ProcessingFee  float64
	PlatformFee    float64
	NetAmount      sql.NullFloat64
	PaymentMethod  sql.NullString
	PaymentStatus  string
	PaymentDate    sql.NullString
	TransactionID  sql.NullString
	EscrowID       sql.NullString
	EscrowStatus   sql.NullString
	Status         string
	StatusReason   sql.NullString
	AttendeeName   sql.NullString
	AttendeeEmail  sql.NullString
	AttendeePhone  sql.NullString
	AttendeeNotes  sql.NullString
	CustomAnswers  sql.NullString
	CreatedAt      string
	UpdatedAt      string
	CancelledAt    sql.NullString
	CompletedAt    sql.NullString
}

func (r *bookingRow) scan() []interface{} {
	return []interface{}{
		&r.ID, &r.UserID, &r.EventID, &r.TicketID, &r.BookingReference, &r.OrderNumber,
		&r.EventTitle, &r.EventSlug, &r.TicketType, &r.TicketName, &r.Quantity,
		&r.UnitPrice, &r.TotalAmount, &r.ServiceFee, &r.ProcessingFee, &r.PlatformFee,
		&r.NetAmount, &r.PaymentMethod, &r.PaymentStatus, &r.PaymentDate, &r.TransactionID,
		&r.EscrowID, &r.EscrowStatus, &r.Status, &r.StatusReason, &r.AttendeeName,
		&r.AttendeeEmail, &r.AttendeePhone, &r.AttendeeNotes, &r.CustomAnswers,
		&r.CreatedAt, &r.UpdatedAt, &r.CancelledAt, &r.CompletedAt,
	}
}

func (r *bookingRow) model() *models.Booking {
	b := &models.Booking{
		ID:              r.ID,
		UserID:          r.UserID,
		EventID:         r.EventID,
		TicketID:        r.TicketID,
		BookingReference: r.BookingReference,
		OrderNumber:     r.OrderNumber.String,
		EventTitle:      r.EventTitle,
		EventSlug:       r.EventSlug.String,
		TicketType:      r.TicketType,
		TicketName:      r.TicketName,
		Quantity:        r.Quantity,
		UnitPrice:       r.UnitPrice,
		TotalAmount:     r.TotalAmount,
		ServiceFee:      r.ServiceFee,
		ProcessingFee:   r.ProcessingFee,
		PlatformFee:     r.PlatformFee,
		PaymentMethod:   r.PaymentMethod.String,
		PaymentStatus:   r.PaymentStatus,
		TransactionID:   r.TransactionID.String,
		EscrowID:        r.EscrowID.String,
		EscrowStatus:    r.EscrowStatus.String,
		Status:          r.Status,
		StatusReason:    r.StatusReason.String,
		AttendeeName:    r.AttendeeName.String,
		AttendeeEmail:   r.AttendeeEmail.String,
		AttendeePhone:   r.AttendeePhone.String,
		AttendeeNotes:   r.AttendeeNotes.String,
		CustomAnswers:   r.CustomAnswers.String,
		CreatedAt:       mustTime(r.CreatedAt),
		UpdatedAt:       mustTime(r.UpdatedAt),
	}
	if r.NetAmount.Valid {
		b.NetAmount = r.NetAmount.Float64
	}
	b.PaymentDate = scanTime(r.PaymentDate)
	b.CancelledAt = scanTime(r.CancelledAt)
	b.CompletedAt = scanTime(r.CompletedAt)
	return b
}

func (r *BookingRepository) Get(id string) (*models.Booking, error) {
	return r.getWhere(`b.id = ?`, id)
}

func (r *BookingRepository) GetByReference(ref string) (*models.Booking, error) {
	return r.getWhere(`b.booking_reference = ?`, ref)
}

// ApplyPayment backfills the booking with the payment service's
// transaction/escrow ids once payment.processed arrives. The WHERE guard
// (transaction_id IS NULL) keeps a duplicated/redelivered message from
// overwriting the canonical ids.
func (r *BookingRepository) ApplyPayment(orderNumber, txnID, escrowID, escrowStatus, paymentMethod string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := r.db.Exec(`
		UPDATE bookings SET
			transaction_id = ?, escrow_id = ?, escrow_status = ?,
			payment_method = ?, payment_status = 'paid', payment_date = ?
		WHERE order_number = ? AND transaction_id IS NULL`,
		txnID, escrowID, escrowStatus, paymentMethod, now, orderNumber)
	return err
}

func (r *BookingRepository) getWhere(cond string, arg interface{}) (*models.Booking, error) {
	row := &bookingRow{}
	err := r.db.QueryRow(`SELECT `+bookingColumns+` FROM bookings b WHERE `+cond+` AND b.deleted_at IS NULL`, arg).Scan(row.scan()...)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return row.model(), nil
}

func (r *BookingRepository) ListByUser(userID string) ([]*models.Booking, error) {
	rows, err := r.db.Query(`SELECT `+bookingColumns+` FROM bookings b
		WHERE b.user_id = ? AND b.deleted_at IS NULL ORDER BY b.created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*models.Booking
	for rows.Next() {
		row := &bookingRow{}
		if err := rows.Scan(row.scan()...); err != nil {
			return nil, err
		}
		out = append(out, row.model())
	}
	return out, rows.Err()
}

// AttachInstances loads ticket instances onto bookings in one query.
func (r *BookingRepository) AttachInstances(bookings []*models.Booking) error {
	if len(bookings) == 0 {
		return nil
	}
	for _, b := range bookings {
		rows, err := r.db.Query(`SELECT `+instanceColumns+` FROM ticket_instances ti
			WHERE ti.booking_id = ? ORDER BY ti.created_at ASC`, b.ID)
		if err != nil {
			return err
		}
		var insts []*models.TicketInstance
		for rows.Next() {
			ir := &instanceRow{}
			if err := rows.Scan(ir.scan()...); err != nil {
				rows.Close()
				return err
			}
			insts = append(insts, ir.model())
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			return err
		}
		if insts == nil {
			insts = []*models.TicketInstance{}
		}
		b.Instances = insts
	}
	return nil
}