package repository

import (
	"database/sql"
	"fmt"

	"donjo_booking/internal/models"
)

// InstanceRepository owns ticket instances: assignment of named holders,
// transfers (code rotation), resale marketplace, and gate lookup.
type InstanceRepository struct {
	db *sql.DB
}

func NewInstanceRepository(db *sql.DB) *InstanceRepository {
	return &InstanceRepository{db: db}
}

const instanceColumns = `
	ti.id, ti.booking_id, ti.ticket_id, ti.event_id, ti.user_id, ti.ticket_code,
	ti.qr_code_data, ti.qr_code_image_url, ti.barcode, ti.holder_name, ti.holder_email,
	ti.holder_phone, ti.status, ti.used_at, ti.used_by, ti.transfer_allowed,
	ti.transferred, ti.transferred_from, ti.transferred_to, ti.transferred_at,
	ti.transfer_code, ti.listed_price, ti.listed_at, ti.unlisted_at, ti.resold_price,
	ti.resold_at, ti.checked_in, ti.checked_in_at, ti.checked_in_by, ti.scan_count,
	ti.last_scanned_at, ti.vip_access, ti.special_notes, ti.is_valid,
	ti.invalidation_reason, ti.created_at, ti.updated_at`

type instanceRow struct {
	ID             string
	BookingID      string
	TicketID       string
	EventID        string
	UserID         string
	TicketCode     string
	QRData         string
	QRImageURL     sql.NullString
	Barcode        sql.NullString
	HolderName     sql.NullString
	HolderEmail    sql.NullString
	HolderPhone    sql.NullString
	Status         string
	UsedAt         sql.NullString
	UsedBy         sql.NullString
	TransferAllowed int
	Transferred    int
	TransferredFrom sql.NullString
	TransferredTo  sql.NullString
	TransferredAt  sql.NullString
	TransferCode   sql.NullString
	ListedPrice    sql.NullFloat64
	ListedAt       sql.NullString
	UnlistedAt     sql.NullString
	ResoldPrice    sql.NullFloat64
	ResoldAt       sql.NullString
	CheckedIn      int
	CheckedInAt    sql.NullString
	CheckedInBy    sql.NullString
	ScanCount      int
	LastScannedAt  sql.NullString
	VIPAccess      int
	SpecialNotes   sql.NullString
	IsValid        int
	InvalidationReason sql.NullString
	CreatedAt      string
	UpdatedAt      string
}

func (r *instanceRow) scan() []interface{} {
	return []interface{}{
		&r.ID, &r.BookingID, &r.TicketID, &r.EventID, &r.UserID, &r.TicketCode,
		&r.QRData, &r.QRImageURL, &r.Barcode, &r.HolderName, &r.HolderEmail,
		&r.HolderPhone, &r.Status, &r.UsedAt, &r.UsedBy, &r.TransferAllowed,
		&r.Transferred, &r.TransferredFrom, &r.TransferredTo, &r.TransferredAt,
		&r.TransferCode, &r.ListedPrice, &r.ListedAt, &r.UnlistedAt, &r.ResoldPrice,
		&r.ResoldAt, &r.CheckedIn, &r.CheckedInAt, &r.CheckedInBy, &r.ScanCount,
		&r.LastScannedAt, &r.VIPAccess, &r.SpecialNotes, &r.IsValid,
		&r.InvalidationReason, &r.CreatedAt, &r.UpdatedAt,
	}
}

func (r *instanceRow) model() *models.TicketInstance {
	m := &models.TicketInstance{
		ID:             r.ID,
		BookingID:      r.BookingID,
		TicketID:       r.TicketID,
		EventID:        r.EventID,
		UserID:         r.UserID,
		TicketCode:     r.TicketCode,
		QRData:         r.QRData,
		QRImageURL:     r.QRImageURL.String,
		Barcode:        r.Barcode.String,
		HolderName:     r.HolderName.String,
		HolderEmail:    r.HolderEmail.String,
		HolderPhone:    r.HolderPhone.String,
		Status:         r.Status,
		UsedBy:         r.UsedBy.String,
		TransferAllowed: r.TransferAllowed == 1,
		Transferred:    r.Transferred == 1,
		TransferredFrom: r.TransferredFrom.String,
		TransferredTo:  r.TransferredTo.String,
		TransferCode:   r.TransferCode.String,
		CheckedIn:      r.CheckedIn == 1,
		CheckedInBy:    r.CheckedInBy.String,
		ScanCount:      r.ScanCount,
		VIPAccess:      r.VIPAccess == 1,
		SpecialNotes:   r.SpecialNotes.String,
		IsValid:        r.IsValid == 1,
		InvalidationReason: r.InvalidationReason.String,
		CreatedAt:      mustTime(r.CreatedAt),
		UpdatedAt:      mustTime(r.UpdatedAt),
	}
	if r.UsedAt.Valid {
		m.UsedAt = scanTime(r.UsedAt)
	}
	if r.TransferredAt.Valid {
		m.TransferredAt = scanTime(r.TransferredAt)
	}
	if r.ListedPrice.Valid {
		m.ListedPrice = &r.ListedPrice.Float64
	}
	m.ListedAt = scanTime(r.ListedAt)
	m.UnlistedAt = scanTime(r.UnlistedAt)
	if r.ResoldPrice.Valid {
		m.ResoldPrice = &r.ResoldPrice.Float64
	}
	m.ResoldAt = scanTime(r.ResoldAt)
	m.CheckedInAt = scanTime(r.CheckedInAt)
	m.LastScannedAt = scanTime(r.LastScannedAt)
	return m
}

func (r *InstanceRepository) Get(id string) (*models.TicketInstance, error) {
	return r.getWhere(`ti.id = ?`, id)
}

func (r *InstanceRepository) GetByCode(code string) (*models.TicketInstance, error) {
	return r.getWhere(`ti.ticket_code = ?`, code)
}

func (r *InstanceRepository) GetByTransferCode(code string) (*models.TicketInstance, error) {
	return r.getWhere(`ti.transfer_code = ?`, code)
}

// Exec runs a raw UPDATE/INSERT against ticket_instances (guarded transitions
// issued by the service layer).
func (r *InstanceRepository) Exec(query string, args ...interface{}) (sql.Result, error) {
	return r.db.Exec(query, args...)
}

func (r *InstanceRepository) getWhere(cond string, arg interface{}) (*models.TicketInstance, error) {
	row := &instanceRow{}
	err := r.db.QueryRow(`SELECT `+instanceColumns+` FROM ticket_instances ti WHERE `+cond, arg).Scan(row.scan()...)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return row.model(), nil
}

// ListByUser returns instances the user currently holds (owned codes only:
// a ticket they shred or resold is no longer theirs and no longer listed).
func (r *InstanceRepository) ListByUser(userID string) ([]*models.TicketInstance, error) {
	return r.withMeta(`WHERE ti.user_id = ? ORDER BY ti.created_at DESC`, userID)
}

// ListForUserWithMeta returns a user's instances joined with event/ticket info.
func (r *InstanceRepository) ListForUserWithMeta(userID string) ([]*models.TicketInstance, error) {
	return r.withMeta(`WHERE ti.user_id = ? ORDER BY ti.created_at DESC`, userID)
}

// ListByBooking returns all instances under a booking.
func (r *InstanceRepository) ListByBooking(bookingID string) ([]*models.TicketInstance, error) {
	rows, err := r.db.Query(`SELECT `+instanceColumns+` FROM ticket_instances ti
		WHERE ti.booking_id = ? ORDER BY ti.created_at ASC`, bookingID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return r.scanAll(rows)
}

// Marketplace lists instances currently offered for resale.
func (r *InstanceRepository) Marketplace() ([]*models.TicketInstance, error) {
	return r.withMeta(`WHERE ti.status = 'listed' ORDER BY ti.listed_at ASC`)
}

func (r *InstanceRepository) MarketplaceWithMeta() ([]*models.TicketInstance, error) {
	return r.withMeta(`WHERE ti.status = 'listed' ORDER BY ti.listed_at ASC`)
}

// withMeta selects instances joined to their bookings for display context and
// fills in event_title/event_slug/ticket_type/ticket_name/booking_reference.
func (r *InstanceRepository) withMeta(cond string, args ...interface{}) ([]*models.TicketInstance, error) {
	rows, err := r.db.Query(`
		SELECT `+instanceColumns+`,
			b.event_title, b.event_slug, b.ticket_type, b.ticket_name, b.booking_reference
		FROM ticket_instances ti
		LEFT JOIN bookings b ON b.id = ti.booking_id
		`+cond, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*models.TicketInstance
	for rows.Next() {
		row := &instanceRow{}
		var title, slug, ttype, tname, bref sql.NullString
		if err := rows.Scan(append(row.scan(),
			&title, &slug, &ttype, &tname, &bref)...); err != nil {
			return nil, err
		}
		m := row.model()
		m.EventTitle, m.EventSlug, m.TicketType, m.TicketName, m.BookingRef =
			title.String, slug.String, ttype.String, tname.String, bref.String
		out = append(out, m)
	}
	if out == nil {
		out = []*models.TicketInstance{}
	}
	return out, rows.Err()
}

func (r *InstanceRepository) scanAll(rows *sql.Rows) ([]*models.TicketInstance, error) {
	var out []*models.TicketInstance
	for rows.Next() {
		row := &instanceRow{}
		if err := rows.Scan(row.scan()...); err != nil {
			return nil, err
		}
		out = append(out, row.model())
	}
	if out == nil {
		out = []*models.TicketInstance{}
	}
	return out, rows.Err()
}

// Assign writes the named holder for a group-assisted ticket.
func (r *InstanceRepository) Assign(id, name, email, phone string) error {
	res, err := r.db.Exec(`UPDATE ticket_instances
		SET holder_name = ?, holder_email = ?, holder_phone = ? WHERE id = ?`,
		nullStr(name), nullStr(email), nullStr(phone), id)
	if err != nil {
		return err
	}
	return requireAffected(res, 1)
}

func (r *InstanceRepository) SetTransferCode(id, code string) error {
	res, err := r.db.Exec(`UPDATE ticket_instances SET transfer_code = ? WHERE id = ?`, code, id)
	if err != nil {
		return err
	}
	return requireAffected(res, 1)
}

func requireAffected(res sql.Result, want int64) error {
	if res == nil {
		return fmt.Errorf("database returned no result")
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n != want {
		return sql.ErrNoRows
	}
	return nil
}