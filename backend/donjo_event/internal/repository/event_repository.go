package repository

import (
	"database/sql"
	"fmt"
	"strings"

	"donjo_event/internal/models"
)

type EventRepository struct {
	db *sql.DB
}

func NewEventRepository(db *sql.DB) *EventRepository {
	return &EventRepository{db: db}
}

var eventColumns = `
	id, creator_id, title, slug, description, short_description, category, sub_category,
	tags, event_type, is_virtual, virtual_link, virtual_platform, venue_id, location,
	address, city, county, country, coordinates, start_time, end_time, timezone,
	setup_time, teardown_time, total_capacity, available_tickets, min_ticket_price,
	max_ticket_price, is_free, ticket_sales_start, ticket_sales_end,
	ticket_transfer_allowed, refund_deadline, status, is_published, published_at,
	is_private, invite_only, event_password, is_verified, verified_by, verified_at,
	verification_notes, banner_image, gallery_images, video_url, organizer_name,
	organizer_email, organizer_phone, views, likes, shares, tickets_sold, revenue,
	allow_waitlist, requires_age_verification, minimum_age, created_at, updated_at,
	deleted_at`

type eventRow struct {
	ID           string
	IDValid      bool
	CreatorID    string
	Title        string
	Slug         string
	Description  sql.NullString
	ShortDesc    sql.NullString
	Category     string
	SubCategory  sql.NullString
	Tags         sql.NullString
	EventType    string
	IsVirtual    bool
	VirtualLink  sql.NullString
	VirtualPlat  sql.NullString
	VenueID      sql.NullString
	Location     sql.NullString
	Address      sql.NullString
	City         sql.NullString
	County       sql.NullString
	Country      string
	Coordinates  sql.NullString
	StartTime    string
	EndTime      string
	Timezone     string
	SetupTime    sql.NullString
	TeardownTime sql.NullString
	TotalCap     int
	AvailTickets sql.NullInt64
	MinPrice     float64
	MaxPrice     float64
	IsFree       bool
	SalesStart   sql.NullString
	SalesEnd     sql.NullString
	Transfer     bool
	RefundDead   sql.NullString
	Status       string
	Published    bool
	PublishedAt  sql.NullString
	IsPrivate    bool
	InviteOnly   bool
	EventPass    sql.NullString
	IsVerified   bool
	VerifiedBy   sql.NullString
	VerifiedAt   sql.NullString
	VerifNotes   sql.NullString
	BannerImage  sql.NullString
	GalleryImg   sql.NullString
	VideoURL     sql.NullString
	OrgName      sql.NullString
	OrgEmail     sql.NullString
	OrgPhone     sql.NullString
	Views        int
	Likes        int
	Shares       int
	TixSold      int
	Revenue      float64
	AllowWait    bool
	ReqAge       bool
	MinAge       sql.NullInt64
	CreatedAt    string
	UpdatedAt    string
	DeletedAt    sql.NullString
}

func (r *eventRow) scan() []interface{} {
	return []interface{}{
		&r.ID, &r.CreatorID, &r.Title, &r.Slug, &r.Description, &r.ShortDesc,
		&r.Category, &r.SubCategory, &r.Tags, &r.EventType, &r.IsVirtual, &r.VirtualLink,
		&r.VirtualPlat, &r.VenueID, &r.Location, &r.Address, &r.City, &r.County,
		&r.Country, &r.Coordinates, &r.StartTime, &r.EndTime, &r.Timezone, &r.SetupTime,
		&r.TeardownTime, &r.TotalCap, &r.AvailTickets, &r.MinPrice, &r.MaxPrice,
		&r.IsFree, &r.SalesStart, &r.SalesEnd, &r.Transfer, &r.RefundDead, &r.Status,
		&r.Published, &r.PublishedAt, &r.IsPrivate, &r.InviteOnly, &r.EventPass,
		&r.IsVerified, &r.VerifiedBy, &r.VerifiedAt, &r.VerifNotes, &r.BannerImage,
		&r.GalleryImg, &r.VideoURL, &r.OrgName, &r.OrgEmail, &r.OrgPhone, &r.Views,
		&r.Likes, &r.Shares, &r.TixSold, &r.Revenue, &r.AllowWait, &r.ReqAge,
		&r.MinAge, &r.CreatedAt, &r.UpdatedAt, &r.DeletedAt,
	}
}

func (r *eventRow) model() *models.Event {
	e := &models.Event{
		ID:                     r.ID,
		CreatorID:              r.CreatorID,
		Title:                  r.Title,
		Slug:                   r.Slug,
		Description:            r.Description.String,
		ShortDescription:       r.ShortDesc.String,
		Category:               r.Category,
		SubCategory:            r.SubCategory.String,
		Tags:                   scanStrings(r.Tags),
		EventType:              r.EventType,
		IsVirtual:              r.IsVirtual,
		VirtualLink:            r.VirtualLink.String,
		VirtualPlatform:        r.VirtualPlat.String,
		VenueID:                r.VenueID.String,
		Location:               r.Location.String,
		Address:                r.Address.String,
		City:                   r.City.String,
		County:                 r.County.String,
		Country:                r.Country,
		Coordinates:            scanCoordinates(r.Coordinates),
		StartTime:              mustTime(r.StartTime),
		EndTime:                mustTime(r.EndTime),
		Timezone:               r.Timezone,
		SetupTime:              scanTime(r.SetupTime),
		TeardownTime:           scanTime(r.TeardownTime),
		TotalCapacity:          r.TotalCap,
		AvailableTickets:       intPtrIf(r.AvailTickets.Valid, int(r.AvailTickets.Int64)),
		MinTicketPrice:         r.MinPrice,
		MaxTicketPrice:         r.MaxPrice,
		IsFree:                 r.IsFree,
		TicketSalesStart:       scanTime(r.SalesStart),
		TicketSalesEnd:         scanTime(r.SalesEnd),
		TicketTransferAllowed:  r.Transfer,
		RefundDeadline:         scanTime(r.RefundDead),
		Status:                 r.Status,
		IsPublished:            r.Published,
		PublishedAt:            scanTime(r.PublishedAt),
		IsPrivate:              r.IsPrivate,
		InviteOnly:             r.InviteOnly,
		EventPassword:          r.EventPass.String,
		IsVerified:             r.IsVerified,
		VerifiedBy:             r.VerifiedBy.String,
		VerifiedAt:             scanTime(r.VerifiedAt),
		VerificationNotes:      r.VerifNotes.String,
		BannerImage:            r.BannerImage.String,
		GalleryImages:          scanStrings(r.GalleryImg),
		VideoURL:               r.VideoURL.String,
		OrganizerName:          r.OrgName.String,
		OrganizerEmail:         r.OrgEmail.String,
		OrganizerPhone:         r.OrgPhone.String,
		Views:                  r.Views,
		Likes:                  r.Likes,
		Shares:                 r.Shares,
		TicketsSold:            r.TixSold,
		Revenue:                r.Revenue,
		AllowWaitlist:          r.AllowWait,
		RequiresAgeVerification: r.ReqAge,
		MinimumAge:             intPtrIf(r.MinAge.Valid, int(r.MinAge.Int64)),
		CreatedAt:              mustTime(r.CreatedAt),
		UpdatedAt:              mustTime(r.UpdatedAt),
		DeletedAt:              scanTime(r.DeletedAt),
	}
	return e
}

func (r *EventRepository) Create(e *models.Event) (string, error) {
	id, err := newID(r.db)
	if err != nil {
		return "", err
	}
	_, err = r.db.Exec(`
		INSERT INTO events (
			id, creator_id, title, slug, description, short_description, category, sub_category,
			tags, event_type, is_virtual, virtual_link, virtual_platform, venue_id, location,
			address, city, county, country, coordinates, start_time, end_time, timezone,
			setup_time, teardown_time, total_capacity, available_tickets, min_ticket_price,
			max_ticket_price, is_free, ticket_sales_start, ticket_sales_end,
			ticket_transfer_allowed, refund_deadline, status, is_published, published_at,
			is_private, invite_only, event_password, is_verified, verified_by, verified_at,
			verification_notes, banner_image, gallery_images, video_url, organizer_name,
			organizer_email, organizer_phone, views, likes, shares, tickets_sold, revenue,
			allow_waitlist, requires_age_verification, minimum_age
		) VALUES (
			?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,
			?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
		)`,
		id, e.CreatorID, e.Title, e.Slug, nullStr(e.Description), nullStr(e.ShortDescription),
		e.Category, nullStr(e.SubCategory), jsonStr(e.Tags), e.EventType, boolInt(e.IsVirtual),
		nullStr(e.VirtualLink), nullStr(e.VirtualPlatform), nullStr(e.VenueID), nullStr(e.Location),
		nullStr(e.Address), nullStr(e.City), nullStr(e.County), e.Country, coordsStr(e.Coordinates),
		fmtTime(e.StartTime), fmtTime(e.EndTime), e.Timezone, fmtTimePtr(e.SetupTime),
		fmtTimePtr(e.TeardownTime), e.TotalCapacity, intVal(e.AvailableTickets), e.MinTicketPrice,
		e.MaxTicketPrice, boolInt(e.IsFree), fmtTimePtr(e.TicketSalesStart), fmtTimePtr(e.TicketSalesEnd),
		boolInt(e.TicketTransferAllowed), fmtTimePtr(e.RefundDeadline), e.Status, boolInt(e.IsPublished),
		fmtTimePtr(e.PublishedAt), boolInt(e.IsPrivate), boolInt(e.InviteOnly), nullStr(e.EventPassword),
		boolInt(e.IsVerified), nullStr(e.VerifiedBy), fmtTimePtr(e.VerifiedAt),
		nullStr(e.VerificationNotes), nullStr(e.BannerImage), jsonStr(e.GalleryImages),
		nullStr(e.VideoURL), nullStr(e.OrganizerName), nullStr(e.OrganizerEmail),
		nullStr(e.OrganizerPhone), 0, 0, 0, 0, 0, boolInt(e.AllowWaitlist),
		boolInt(e.RequiresAgeVerification), intVal(e.MinimumAge),
	)
	if err != nil {
		return "", err
	}
	return id, nil
}

func (r *EventRepository) GetByID(id string) (*models.Event, error) {
	return r.get(`SELECT `+eventColumns+` FROM events WHERE id = ? AND deleted_at IS NULL`, id)
}

func (r *EventRepository) GetBySlug(slug string) (*models.Event, error) {
	return r.get(`SELECT `+eventColumns+` FROM events WHERE slug = ? AND deleted_at IS NULL`, slug)
}

// SlugTaken reports whether any row (including soft-deleted ones) holds the
// slug, which is what blocks re-creating the same slug for a new resource.
func (r *EventRepository) SlugTaken(slug string) (bool, error) {
	var one int
	err := r.db.QueryRow(`SELECT 1 FROM events WHERE slug = ? LIMIT 1`, slug).Scan(&one)
	if err == sql.ErrNoRows {
		return false, nil
	}
	return err == nil, err
}

func (r *EventRepository) get(query string, arg string) (*models.Event, error) {
	row := &eventRow{}
	err := r.db.QueryRow(query, arg).Scan(row.scan()...)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return row.model(), nil
}

type EventFilter struct {
	CreatorID string
	Category  string
	Status    string
	City      string
	Upcoming  bool
	Limit     int
	Offset    int
}

func (r *EventRepository) List(f EventFilter) ([]*models.Event, error) {
	var conds []string
	var args []interface{}

	conds = append(conds, "deleted_at IS NULL")
	if f.CreatorID != "" {
		conds = append(conds, "creator_id = ?")
		args = append(args, f.CreatorID)
	}
	if f.Category != "" {
		conds = append(conds, "category = ?")
		args = append(args, f.Category)
	}
	if f.Status != "" {
		conds = append(conds, "status = ?")
		args = append(args, f.Status)
	}
	if f.City != "" {
		conds = append(conds, "city = ?")
		args = append(args, f.City)
	}
	if f.Upcoming {
		conds = append(conds, "start_time > datetime('now')")
	}

	limit := f.Limit
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	offset := f.Offset
	if offset < 0 {
		offset = 0
	}

	query := fmt.Sprintf(`SELECT %s FROM events WHERE %s ORDER BY start_time DESC LIMIT ? OFFSET ?`,
		eventColumns, strings.Join(conds, " AND "))
	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []*models.Event
	for rows.Next() {
		row := &eventRow{}
		if err := rows.Scan(row.scan()...); err != nil {
			return nil, err
		}
		events = append(events, row.model())
	}
	return events, rows.Err()
}

func (r *EventRepository) Update(e *models.Event) error {
	res, err := r.db.Exec(`
		UPDATE events SET
			title=?, slug=?, description=?, short_description=?, category=?, sub_category=?,
			tags=?, event_type=?, is_virtual=?, virtual_link=?, virtual_platform=?, venue_id=?,
			location=?, address=?, city=?, county=?, country=?, coordinates=?, start_time=?,
			end_time=?, timezone=?, setup_time=?, teardown_time=?, total_capacity=?,
			available_tickets=?, min_ticket_price=?, max_ticket_price=?, is_free=?,
			ticket_sales_start=?, ticket_sales_end=?, ticket_transfer_allowed=?,
			refund_deadline=?, status=?, is_published=?, published_at=?, is_private=?,
			invite_only=?, event_password=?, is_verified=?, verified_by=?, verified_at=?,
			verification_notes=?, banner_image=?, gallery_images=?, video_url=?,
			organizer_name=?, organizer_email=?, organizer_phone=?, views=?, likes=?, shares=?,
			tickets_sold=?, revenue=?, allow_waitlist=?, requires_age_verification=?,
			minimum_age=?
		WHERE id = ? AND deleted_at IS NULL`,
		e.Title, e.Slug, nullStr(e.Description), nullStr(e.ShortDescription), e.Category,
		nullStr(e.SubCategory), jsonStr(e.Tags), e.EventType, boolInt(e.IsVirtual),
		nullStr(e.VirtualLink), nullStr(e.VirtualPlatform), nullStr(e.VenueID),
		nullStr(e.Location), nullStr(e.Address), nullStr(e.City), nullStr(e.County),
		e.Country, coordsStr(e.Coordinates), fmtTime(e.StartTime), fmtTime(e.EndTime),
		e.Timezone, fmtTimePtr(e.SetupTime), fmtTimePtr(e.TeardownTime), e.TotalCapacity,
		intVal(e.AvailableTickets), e.MinTicketPrice, e.MaxTicketPrice, boolInt(e.IsFree),
		fmtTimePtr(e.TicketSalesStart), fmtTimePtr(e.TicketSalesEnd),
		boolInt(e.TicketTransferAllowed), fmtTimePtr(e.RefundDeadline), e.Status,
		boolInt(e.IsPublished), fmtTimePtr(e.PublishedAt), boolInt(e.IsPrivate),
		boolInt(e.InviteOnly), nullStr(e.EventPassword), boolInt(e.IsVerified),
		nullStr(e.VerifiedBy), fmtTimePtr(e.VerifiedAt), nullStr(e.VerificationNotes),
		nullStr(e.BannerImage), jsonStr(e.GalleryImages), nullStr(e.VideoURL),
		nullStr(e.OrganizerName), nullStr(e.OrganizerEmail), nullStr(e.OrganizerPhone),
		e.Views, e.Likes, e.Shares, e.TicketsSold, e.Revenue, boolInt(e.AllowWaitlist),
		boolInt(e.RequiresAgeVerification), intVal(e.MinimumAge), e.ID,
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

func (r *EventRepository) Delete(id string) error {
	res, err := r.db.Exec(`UPDATE events SET deleted_at = CURRENT_TIMESTAMP, is_published = 0 WHERE id = ? AND deleted_at IS NULL`, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *EventRepository) IncrementViews(id string) error {
	_, err := r.db.Exec(`UPDATE events SET views = views + 1 WHERE id = ?`, id)
	return err
}

func (r *EventRepository) IncrementLike(id string) error {
	_, err := r.db.Exec(`UPDATE events SET likes = likes + 1 WHERE id = ?`, id)
	return err
}

func (r *EventRepository) Publish(id string) error {
	res, err := r.db.Exec(`
		UPDATE events SET is_published = 1, status = 'active',
			published_at = COALESCE(published_at, CURRENT_TIMESTAMP)
		WHERE id = ? AND deleted_at IS NULL`, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *EventRepository) Unpublish(id string) error {
	res, err := r.db.Exec(`UPDATE events SET is_published = 0, status = 'draft' WHERE id = ? AND deleted_at IS NULL`, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *EventRepository) TicketTypeCount(id string) (int, error) {
	var n int
	err := r.db.QueryRow(`SELECT COUNT(1) FROM tickets WHERE event_id = ? AND is_active = 1 AND is_hidden = 0`, id).Scan(&n)
	return n, err
}