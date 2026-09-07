package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"

	"donjo_event/internal/models"
)

type VenueRepository struct {
	db *sql.DB
}

func NewVenueRepository(db *sql.DB) *VenueRepository {
	return &VenueRepository{db: db}
}

var venueColumns = `
	id, creator_id, name, slug, description, short_description, venue_type,
	venue_category, address, city, county, country, coordinates, map_embed_url,
	directions, capacity, max_capacity, base_price, pricing_type, min_booking_hours,
	max_booking_hours, security_deposit, cleaning_fee, is_available,
	availability_schedule, unavailable_dates, amenities, equipment, capacity_features,
	restrictions, is_verified, verified_by, verified_at, verification_notes, status,
	cover_image, gallery_images, virtual_tour_url, contact_name, contact_phone,
	contact_email, events_hosted, rating, review_count, created_at, updated_at,
	deleted_at`

type venueRow struct {
	ID           string
	CreatorID    string
	Name         string
	Slug         string
	Description  sql.NullString
	ShortDesc    sql.NullString
	VenueType    string
	VenueCat     sql.NullString
	Address      string
	City         sql.NullString
	County       sql.NullString
	Country      string
	Coordinates  sql.NullString
	MapEmbed     sql.NullString
	Directions   sql.NullString
	Capacity     int
	MaxCapacity  sql.NullInt64
	BasePrice    float64
	PricingType  string
	MinHours     int
	MaxHours     int
	SecurityD    float64
	CleaningFee  float64
	IsAvailable  bool
	AvailSched   sql.NullString
	UnavailDates sql.NullString
	Amenities    sql.NullString
	Equipment    sql.NullString
	CapFeatures  sql.NullString
	Restrictions sql.NullString
	IsVerified   bool
	VerifiedBy   sql.NullString
	VerifiedAt   sql.NullString
	VerifNotes   sql.NullString
	Status       string
	CoverImage   sql.NullString
	GalleryImg   sql.NullString
	VirtualTour  sql.NullString
	ContactName  sql.NullString
	ContactPhone sql.NullString
	ContactEmail sql.NullString
	EventsHosted int
	Rating       float64
	ReviewCount  int
	CreatedAt    string
	UpdatedAt    string
	DeletedAt    sql.NullString
}

func (r *venueRow) scan() []interface{} {
	return []interface{}{
		&r.ID, &r.CreatorID, &r.Name, &r.Slug, &r.Description, &r.ShortDesc,
		&r.VenueType, &r.VenueCat, &r.Address, &r.City, &r.County, &r.Country,
		&r.Coordinates, &r.MapEmbed, &r.Directions, &r.Capacity, &r.MaxCapacity,
		&r.BasePrice, &r.PricingType, &r.MinHours, &r.MaxHours, &r.SecurityD,
		&r.CleaningFee, &r.IsAvailable, &r.AvailSched, &r.UnavailDates, &r.Amenities,
		&r.Equipment, &r.CapFeatures, &r.Restrictions, &r.IsVerified, &r.VerifiedBy,
		&r.VerifiedAt, &r.VerifNotes, &r.Status, &r.CoverImage, &r.GalleryImg,
		&r.VirtualTour, &r.ContactName, &r.ContactPhone, &r.ContactEmail,
		&r.EventsHosted, &r.Rating, &r.ReviewCount, &r.CreatedAt, &r.UpdatedAt,
		&r.DeletedAt,
	}
}

func (r *venueRow) model() *models.Venue {
	v := &models.Venue{
		ID:                   r.ID,
		CreatorID:            r.CreatorID,
		Name:                 r.Name,
		Slug:                 r.Slug,
		Description:          r.Description.String,
		ShortDescription:     r.ShortDesc.String,
		VenueType:            r.VenueType,
		VenueCategory:        r.VenueCat.String,
		Address:              r.Address,
		City:                 r.City.String,
		County:               r.County.String,
		Country:              r.Country,
		Coordinates:          scanCoordinates(r.Coordinates),
		MapEmbedURL:          r.MapEmbed.String,
		Directions:           r.Directions.String,
		Capacity:             r.Capacity,
		MaxCapacity:          int(r.MaxCapacity.Int64),
		BasePrice:            r.BasePrice,
		PricingType:          r.PricingType,
		MinBookingHours:      r.MinHours,
		MaxBookingHours:      r.MaxHours,
		SecurityDeposit:      r.SecurityD,
		CleaningFee:          r.CleaningFee,
		IsAvailable:          r.IsAvailable,
		AvailabilitySchedule: scanMap(r.AvailSched),
		UnavailableDates:     scanStrings(r.UnavailDates),
		Amenities:            scanStrings(r.Amenities),
		Equipment:            scanStrings(r.Equipment),
		CapacityFeatures:     scanMap(r.CapFeatures),
		Restrictions:         scanStrings(r.Restrictions),
		IsVerified:           r.IsVerified,
		VerifiedBy:           r.VerifiedBy.String,
		VerifiedAt:           scanTime(r.VerifiedAt),
		VerificationNotes:    r.VerifNotes.String,
		Status:               r.Status,
		CoverImage:           r.CoverImage.String,
		GalleryImages:        scanStrings(r.GalleryImg),
		VirtualTourURL:       r.VirtualTour.String,
		ContactName:          r.ContactName.String,
		ContactPhone:         r.ContactPhone.String,
		ContactEmail:         r.ContactEmail.String,
		EventsHosted:         r.EventsHosted,
		Rating:               r.Rating,
		ReviewCount:          r.ReviewCount,
		CreatedAt:            mustTime(r.CreatedAt),
		UpdatedAt:            mustTime(r.UpdatedAt),
		DeletedAt:            scanTime(r.DeletedAt),
	}
	return v
}

func (r *VenueRepository) Create(v *models.Venue) (string, error) {
	id, err := newID(r.db)
	if err != nil {
		return "", err
	}
	_, err = r.db.Exec(`
		INSERT INTO venues (
			id, creator_id, name, slug, description, short_description, venue_type,
			venue_category, address, city, county, country, coordinates, map_embed_url,
			directions, capacity, max_capacity, base_price, pricing_type,
			min_booking_hours, max_booking_hours, security_deposit, cleaning_fee,
			is_available, availability_schedule, unavailable_dates, amenities, equipment,
			capacity_features, restrictions, is_verified, verified_by, verified_at,
			verification_notes, status, cover_image, gallery_images, virtual_tour_url,
			contact_name, contact_phone, contact_email, events_hosted, rating,
			review_count
		) VALUES (
			?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,
			?,?,?,?,?,?,?
		)`,
		id, v.CreatorID, v.Name, v.Slug, nullStr(v.Description), nullStr(v.ShortDescription),
		v.VenueType, nullStr(v.VenueCategory), v.Address, nullStr(v.City), nullStr(v.County),
		v.Country, coordsStr(v.Coordinates), nullStr(v.MapEmbedURL), nullStr(v.Directions),
		v.Capacity, intValp(&v.MaxCapacity), v.BasePrice, v.PricingType, v.MinBookingHours,
		v.MaxBookingHours, v.SecurityDeposit, v.CleaningFee, boolInt(v.IsAvailable),
		jsonStr(v.AvailabilitySchedule), jsonStr(v.UnavailableDates), jsonStr(v.Amenities),
		jsonStr(v.Equipment), jsonStr(v.CapacityFeatures), jsonStr(v.Restrictions),
		boolInt(v.IsVerified), nullStr(v.VerifiedBy), fmtTimePtr(v.VerifiedAt),
		nullStr(v.VerificationNotes), v.Status, nullStr(v.CoverImage), jsonStr(v.GalleryImages),
		nullStr(v.VirtualTourURL), nullStr(v.ContactName), nullStr(v.ContactPhone),
		nullStr(v.ContactEmail), 0, 0, 0,
	)
	if err != nil {
		return "", err
	}
	return id, nil
}

func (r *VenueRepository) GetByID(id string) (*models.Venue, error) {
	return r.get(`SELECT `+venueColumns+` FROM venues WHERE id = ? AND deleted_at IS NULL`, id)
}

func (r *VenueRepository) GetBySlug(slug string) (*models.Venue, error) {
	return r.get(`SELECT `+venueColumns+` FROM venues WHERE slug = ? AND deleted_at IS NULL`, slug)
}

// SlugTaken reports whether any row (including soft-deleted ones) holds the
// slug, which is what blocks re-creating the same slug for a new resource.
func (r *VenueRepository) SlugTaken(slug string) (bool, error) {
	var one int
	err := r.db.QueryRow(`SELECT 1 FROM venues WHERE slug = ? LIMIT 1`, slug).Scan(&one)
	if err == sql.ErrNoRows {
		return false, nil
	}
	return err == nil, err
}

func (r *VenueRepository) get(query string, arg string) (*models.Venue, error) {
	row := &venueRow{}
	err := r.db.QueryRow(query, arg).Scan(row.scan()...)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return row.model(), nil
}

type VenueFilter struct {
	CreatorID string
	VenueType string
	City      string
	Status    string
	Limit     int
	Offset    int
}

func (r *VenueRepository) List(f VenueFilter) ([]*models.Venue, error) {
	var conds []string
	var args []interface{}

	conds = append(conds, "deleted_at IS NULL")
	if f.CreatorID != "" {
		conds = append(conds, "creator_id = ?")
		args = append(args, f.CreatorID)
	}
	if f.VenueType != "" {
		conds = append(conds, "venue_type = ?")
		args = append(args, f.VenueType)
	}
	if f.City != "" {
		conds = append(conds, "city = ?")
		args = append(args, f.City)
	}
	if f.Status != "" {
		conds = append(conds, "status = ?")
		args = append(args, f.Status)
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

	query := fmt.Sprintf(`SELECT %s FROM venues WHERE %s ORDER BY created_at DESC LIMIT ? OFFSET ?`,
		venueColumns, strings.Join(conds, " AND "))
	args = append(args, limit, offset)

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var venues []*models.Venue
	for rows.Next() {
		row := &venueRow{}
		if err := rows.Scan(row.scan()...); err != nil {
			return nil, err
		}
		venues = append(venues, row.model())
	}
	return venues, rows.Err()
}

func (r *VenueRepository) Update(v *models.Venue) error {
	res, err := r.db.Exec(`
		UPDATE venues SET
			name=?, slug=?, description=?, short_description=?, venue_type=?,
			venue_category=?, address=?, city=?, county=?, country=?, coordinates=?,
			map_embed_url=?, directions=?, capacity=?, max_capacity=?, base_price=?,
			pricing_type=?, min_booking_hours=?, max_booking_hours=?, security_deposit=?,
			cleaning_fee=?, is_available=?, availability_schedule=?, unavailable_dates=?,
			amenities=?, equipment=?, capacity_features=?, restrictions=?, is_verified=?,
			verified_by=?, verified_at=?, verification_notes=?, status=?, cover_image=?,
			gallery_images=?, virtual_tour_url=?, contact_name=?, contact_phone=?,
			contact_email=?, events_hosted=?, rating=?, review_count=?
		WHERE id = ? AND deleted_at IS NULL`,
		v.Name, v.Slug, nullStr(v.Description), nullStr(v.ShortDescription), v.VenueType,
		nullStr(v.VenueCategory), v.Address, nullStr(v.City), nullStr(v.County), v.Country,
		coordsStr(v.Coordinates), nullStr(v.MapEmbedURL), nullStr(v.Directions), v.Capacity,
		intValp(&v.MaxCapacity), v.BasePrice, v.PricingType, v.MinBookingHours,
		v.MaxBookingHours, v.SecurityDeposit, v.CleaningFee, boolInt(v.IsAvailable),
		jsonStr(v.AvailabilitySchedule), jsonStr(v.UnavailableDates), jsonStr(v.Amenities),
		jsonStr(v.Equipment), jsonStr(v.CapacityFeatures), jsonStr(v.Restrictions),
		boolInt(v.IsVerified), nullStr(v.VerifiedBy), fmtTimePtr(v.VerifiedAt),
		nullStr(v.VerificationNotes), v.Status, nullStr(v.CoverImage), jsonStr(v.GalleryImages),
		nullStr(v.VirtualTourURL), nullStr(v.ContactName), nullStr(v.ContactPhone),
		nullStr(v.ContactEmail), v.EventsHosted, v.Rating, v.ReviewCount, v.ID,
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

func (r *VenueRepository) Delete(id string) error {
	res, err := r.db.Exec(`UPDATE venues SET deleted_at = CURRENT_TIMESTAMP, is_available = 0 WHERE id = ? AND deleted_at IS NULL`, id)
	if err != nil {
		return err
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (r *VenueRepository) IncrementHosted(id string) error {
	_, err := r.db.Exec(`UPDATE venues SET events_hosted = events_hosted + 1 WHERE id = ?`, id)
	return err
}

func scanMap(v sql.NullString) map[string]interface{} {
	if !v.Valid || v.String == "" {
		return nil
	}
	out := map[string]interface{}{}
	if err := json.Unmarshal([]byte(v.String), &out); err != nil {
		return nil
	}
	return out
}

func intValp(p *int) interface{} {
	if p == nil {
		return nil
	}
	return *p
}