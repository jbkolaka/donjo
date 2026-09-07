package repository

import (
	"database/sql"
	"fmt"

	"donjo_event/internal/models"
)

type TicketRepository struct {
	db *sql.DB
}

func NewTicketRepository(db *sql.DB) *TicketRepository {
	return &TicketRepository{db: db}
}

var ticketColumns = `
	id, event_id, type, tier, name, description, price, original_price, service_fee,
	processing_fee, quantity, sold, reserved, max_per_user, min_per_user, sales_start,
	sales_end, early_bird_deadline, is_transferable, is_refundable, requires_id_check,
	custom_fields, benefits, is_active, is_hidden, created_at, updated_at`

type ticketRow struct {
	ID           string
	EventID      string
	Type         string
	Tier         sql.NullString
	Name         string
	Description  sql.NullString
	Price        float64
	OriginalPrice sql.NullFloat64
	ServiceFee   float64
	ProcessingFee float64
	Quantity     int
	Sold         int
	Reserved     int
	MaxPerUser   int
	MinPerUser   int
	SalesStart   sql.NullString
	SalesEnd     sql.NullString
	EarlyBird    sql.NullString
	IsTransfer   bool
	IsRefundable bool
	RequiresID   bool
	CustomFields sql.NullString
	Benefits     sql.NullString
	IsActive     bool
	IsHidden     bool
	CreatedAt    string
	UpdatedAt    string
}

func (r *ticketRow) scan() []interface{} {
	return []interface{}{
		&r.ID, &r.EventID, &r.Type, &r.Tier, &r.Name, &r.Description, &r.Price,
		&r.OriginalPrice, &r.ServiceFee, &r.ProcessingFee, &r.Quantity, &r.Sold,
		&r.Reserved, &r.MaxPerUser, &r.MinPerUser, &r.SalesStart, &r.SalesEnd,
		&r.EarlyBird, &r.IsTransfer, &r.IsRefundable, &r.RequiresID, &r.CustomFields,
		&r.Benefits, &r.IsActive, &r.IsHidden, &r.CreatedAt, &r.UpdatedAt,
	}
}

func (r *ticketRow) model() *models.Ticket {
	t := &models.Ticket{
		ID:             r.ID,
		EventID:        r.EventID,
		Type:           r.Type,
		Tier:           r.Tier.String,
		Name:           r.Name,
		Description:    r.Description.String,
		Price:          r.Price,
		OriginalPrice:  r.OriginalPrice.Float64,
		ServiceFee:     r.ServiceFee,
		ProcessingFee:  r.ProcessingFee,
		Quantity:       r.Quantity,
		Sold:           r.Sold,
		Reserved:       r.Reserved,
		MaxPerUser:     r.MaxPerUser,
		MinPerUser:     r.MinPerUser,
		SalesStart:     scanTime(r.SalesStart),
		SalesEnd:       scanTime(r.SalesEnd),
		EarlyBirdDeadline: scanTime(r.EarlyBird),
		IsTransferable: r.IsTransfer,
		IsRefundable:   r.IsRefundable,
		RequiresIDCheck: r.RequiresID,
		CustomFields:   scanMap(r.CustomFields),
		Benefits:       scanStrings(r.Benefits),
		IsActive:       r.IsActive,
		IsHidden:       r.IsHidden,
		CreatedAt:      mustTime(r.CreatedAt),
		UpdatedAt:      mustTime(r.UpdatedAt),
	}
	return t
}

func (r *TicketRepository) Create(t *models.Ticket) (string, error) {
	id, err := newID(r.db)
	if err != nil {
		return "", err
	}
	_, err = r.db.Exec(`
		INSERT INTO tickets (
			id, event_id, type, tier, name, description, price, original_price,
			service_fee, processing_fee, quantity, sold, reserved, max_per_user,
			min_per_user, sales_start, sales_end, early_bird_deadline, is_transferable,
			is_refundable, requires_id_check, custom_fields, benefits, is_active,
			is_hidden
		) VALUES (
			?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
		)`,
		id, t.EventID, t.Type, nullStr(t.Tier), t.Name, nullStr(t.Description), t.Price,
		floatVal(t.OriginalPrice), t.ServiceFee, t.ProcessingFee, t.Quantity, 0, 0,
		t.MaxPerUser, t.MinPerUser, fmtTimePtr(t.SalesStart), fmtTimePtr(t.SalesEnd),
		fmtTimePtr(t.EarlyBirdDeadline), boolInt(t.IsTransferable), boolInt(t.IsRefundable),
		boolInt(t.RequiresIDCheck), jsonStr(t.CustomFields), jsonStr(t.Benefits),
		boolInt(t.IsActive), boolInt(t.IsHidden),
	)
	if err != nil {
		return "", err
	}
	return id, nil
}

func (r *TicketRepository) GetByID(id string) (*models.Ticket, error) {
	row := &ticketRow{}
	err := r.db.QueryRow(`SELECT `+ticketColumns+` FROM tickets WHERE id = ?`, id).Scan(row.scan()...)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return row.model(), nil
}

func (r *TicketRepository) ListByEvent(eventID string) ([]*models.Ticket, error) {
	rows, err := r.db.Query(`SELECT `+ticketColumns+` FROM tickets WHERE event_id = ? ORDER BY price ASC, created_at ASC`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tickets []*models.Ticket
	for rows.Next() {
		row := &ticketRow{}
		if err := rows.Scan(row.scan()...); err != nil {
			return nil, err
		}
		tickets = append(tickets, row.model())
	}
	return tickets, rows.Err()
}

func (r *TicketRepository) Update(t *models.Ticket) error {
	res, err := r.db.Exec(`
		UPDATE tickets SET
			type=?, tier=?, name=?, description=?, price=?, original_price=?, service_fee=?,
			processing_fee=?, quantity=?, sold=?, reserved=?, max_per_user=?, min_per_user=?,
			sales_start=?, sales_end=?, early_bird_deadline=?, is_transferable=?,
			is_refundable=?, requires_id_check=?, custom_fields=?, benefits=?, is_active=?,
			is_hidden=?
		WHERE id = ?`,
		t.Type, nullStr(t.Tier), t.Name, nullStr(t.Description), t.Price,
		floatVal(t.OriginalPrice), t.ServiceFee, t.ProcessingFee, t.Quantity, t.Sold,
		t.Reserved, t.MaxPerUser, t.MinPerUser, fmtTimePtr(t.SalesStart),
		fmtTimePtr(t.SalesEnd), fmtTimePtr(t.EarlyBirdDeadline), boolInt(t.IsTransferable),
		boolInt(t.IsRefundable), boolInt(t.RequiresIDCheck), jsonStr(t.CustomFields),
		jsonStr(t.Benefits), boolInt(t.IsActive), boolInt(t.IsHidden), t.ID,
	)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *TicketRepository) Delete(id string) error {
	res, err := r.db.Exec(`DELETE FROM tickets WHERE id = ?`, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *TicketRepository) SetActive(id string, active bool) error {
	_, err := r.db.Exec(`UPDATE tickets SET is_active = ? WHERE id = ?`, boolInt(active), id)
	return err
}

// Reserve atomically decrements available quantity for a purchase.
// Returns the number of affected rows (0 = insufficient quantity/sold out).
func (r *TicketRepository) Reserve(id string, qty int) error {
	res, err := r.db.Exec(`
		UPDATE tickets
		SET reserved = reserved + ?
		WHERE id = ? AND is_active = 1 AND (quantity - sold - reserved) >= ?`,
		qty, id, qty,
	)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrSoldOut
	}
	return nil
}

// ConfirmPurchase moves reserved tickets to sold.
func (r *TicketRepository) ConfirmPurchase(id string, qty int) error {
	res, err := r.db.Exec(`
		UPDATE tickets
		SET sold = sold + ?, reserved = MAX(reserved - ?, 0)
		WHERE id = ? AND (sold + ?) <= quantity`,
		qty, qty, id, qty,
	)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ErrSoldOut
	}
	return nil
}

// ReleaseReserved returns reserved tickets back to availability.
func (r *TicketRepository) ReleaseReserved(id string, qty int) error {
	_, err := r.db.Exec(`UPDATE tickets SET reserved = MAX(reserved - ?, 0) WHERE id = ?`, qty, id)
	return err
}

func (r *TicketRepository) Available(id string) (int, error) {
	var available int
	err := r.db.QueryRow(`
		SELECT quantity - sold - reserved FROM tickets WHERE id = ?`, id).Scan(&available)
	return available, err
}

func (r *TicketRepository) AvailableMap(eventID string) (map[string]int, error) {
	rows, err := r.db.Query(`
		SELECT id, quantity - sold - reserved FROM tickets WHERE event_id = ?`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := make(map[string]int)
	for rows.Next() {
		var id string
		var avail int
		if err := rows.Scan(&id, &avail); err != nil {
			return nil, err
		}
		out[id] = avail
	}
	return out, rows.Err()
}

func (r *TicketRepository) SyncEventSoldAndRevenue(eventID string) error {
	_, err := r.db.Exec(`
		UPDATE events
		SET tickets_sold = (
			SELECT COALESCE(SUM(sold), 0) FROM tickets WHERE event_id = ?
		),
		revenue = (
			SELECT COALESCE(SUM(sold * (price + service_fee + processing_fee)), 0)
			FROM tickets WHERE event_id = ?
		),
		available_tickets = (
			SELECT COALESCE(SUM(quantity - sold - reserved), 0) FROM tickets WHERE event_id = ?
		)
		WHERE id = ?`, eventID, eventID, eventID, eventID,
	)
	return err
}

var ErrSoldOut = fmt.Errorf("tickets sold out or insufficient quantity")

func floatVal(v float64) interface{} {
	// float64 0 is stored as 0.0; no special handling needed
	return v
}