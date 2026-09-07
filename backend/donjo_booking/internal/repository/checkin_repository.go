package repository

import (
	"database/sql"
	"time"

	"donjo_booking/internal/models"
)

// CheckinRepository handles gate scans and scan-location configuration. All
// scans are logged in qr_scan_logs, success or failure.
type CheckinRepository struct {
	db *sql.DB
}

func NewCheckinRepository(db *sql.DB) *CheckinRepository {
	return &CheckinRepository{db: db}
}

// RecordScan logs a gate attempt and returns the log id.
func (r *CheckinRepository) RecordScan(log *models.QRScanLog) (string, error) {
	id, err := newID(r.db)
	if err != nil {
		return "", err
	}
	_, err = r.db.Exec(`
		INSERT INTO qr_scan_logs (
			id, ticket_instance_id, event_id, booking_id, scanner_id, user_id,
			scan_type, scan_result, qr_code_scanned, scan_location, scan_location_name,
			scan_ip, scan_device_info, response_message, response_code,
			ticket_status_before, ticket_status_after, metadata, created_at
		) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
		id, log.TicketInstanceID, log.EventID, log.BookingID, log.ScannerID, log.UserID,
		log.ScanType, log.ScanResult, log.QRCodeScanned, log.ScanLocation, log.ScanLocationName,
		log.ScanIP, log.ScanDeviceInfo, log.ResponseMessage, log.ResponseCode,
		log.TicketStatusBefore, log.TicketStatusAfter, log.Metadata,
		time.Now().UTC().Format(time.RFC3339),
	)
	return id, err
}

// MarkUsed flips an instance to used, recording the scan. Guarded so a second
// scan is a no-op for repeaters but still counted.
func (r *CheckinRepository) MarkUsed(instanceID, scannerID, location string) (bool, error) {
	tx, err := r.db.Begin()
	if err != nil {
		return false, err
	}
	defer tx.Rollback()

	row := &instanceRow{}
	now := time.Now().UTC().Format(time.RFC3339)
	err = tx.QueryRow(`SELECT `+instanceColumns+` FROM ticket_instances ti WHERE ti.id = ?`, instanceID).Scan(row.scan()...)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}

	already := row.CheckedIn == 1
	_, err = tx.Exec(`UPDATE ticket_instances SET
			status = ?, used_at = ?, used_by = ?, checked_in = 1,
			checked_in_at = ?, checked_in_by = ?, check_in_location = ?,
			scan_count = scan_count + 1, last_scanned_at = ?
		WHERE id = ?`,
		models.InstanceUsed, now, scannerID, now, scannerID, location,
		now, instanceID,
	)
	if err != nil {
		return false, err
	}
	if err := tx.Commit(); err != nil {
		return false, err
	}
	return !already, nil
}

func (r *CheckinRepository) BumpScan(locationID string, success bool) error {
	col := "failed_scans"
	if success {
		col = "success_scans"
	}
	res, err := r.db.Exec(`UPDATE scan_locations SET total_scans = total_scans + 1, `+col+` = `+col+` + 1 WHERE id = ?`, locationID)
	if err != nil {
		return err
	}
	return requireAffected(res, 1)
}

// ---- scan locations --------------------------------------------------------

func (r *CheckinRepository) CreateLocation(l *models.ScanLocation) error {
	id, err := newID(r.db)
	if err != nil {
		return err
	}
	now := time.Now().UTC().Format(time.RFC3339)
	if !l.IsActive {
		l.IsActive = true
	}
	if l.Radius == 0 {
		l.Radius = 50
	}
	_, err = r.db.Exec(`
		INSERT INTO scan_locations (
			id, event_id, name, description, address, coordinates, radius,
			opens_at, closes_at, allowed_ticket_types, requires_extra_verification,
			assigned_staff, is_active, is_primary, created_at, updated_at
		) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
		id, l.EventID, l.Name, nullStr(l.Description), nullStr(l.Address),
		nullStr(l.Coordinates), l.Radius, nullStr(l.OpensAt), nullStr(l.ClosesAt),
		nullStr(l.AllowedTicketTypes), boolInt(l.RequiresExtraVerification),
		nullStr(l.AssignedStaff), boolInt(l.IsActive), boolInt(l.IsPrimary),
		now, now,
	)
	if err != nil {
		return err
	}
	l.ID = id
	l.CreatedAt = mustTime(now)
	l.UpdatedAt = mustTime(now)
	return nil
}

func (r *CheckinRepository) ListLocations(eventID string) ([]*models.ScanLocation, error) {
	rows, err := r.db.Query(`SELECT id, event_id, name, description, address, coordinates,
		radius, opens_at, closes_at, allowed_ticket_types, requires_extra_verification,
		assigned_staff, is_active, is_primary, total_scans, success_scans, failed_scans,
		created_at, updated_at FROM scan_locations WHERE event_id = ? ORDER BY is_primary DESC, name`, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanLocations(rows)
}

func scanLocations(rows *sql.Rows) ([]*models.ScanLocation, error) {
	var out []*models.ScanLocation
	for rows.Next() {
		l := &models.ScanLocation{}
		var desc, addr, coords, opens, closes, allowed, staff sql.NullString
		var reqExtra, active, primary int
		var created, updated string
		if err := rows.Scan(&l.ID, &l.EventID, &l.Name, &desc, &addr, &coords,
			&l.Radius, &opens, &closes, &allowed, &reqExtra, &staff,
			&active, &primary, &l.TotalScans, &l.SuccessScans, &l.FailedScans,
			&created, &updated); err != nil {
			return nil, err
		}
		l.Description, l.Address, l.Coordinates, l.OpensAt, l.ClosesAt = desc.String, addr.String, coords.String, opens.String, closes.String
		l.AllowedTicketTypes, l.AssignedStaff = allowed.String, staff.String
		l.RequiresExtraVerification = reqExtra == 1
		l.IsActive, l.IsPrimary = active == 1, primary == 1
		l.CreatedAt = mustTime(created)
		l.UpdatedAt = mustTime(updated)
		out = append(out, l)
	}
	if out == nil {
		out = []*models.ScanLocation{}
	}
	return out, rows.Err()
}

func (r *CheckinRepository) GetLocation(id string) (*models.ScanLocation, error) {
	rows, err := r.db.Query(`SELECT id, event_id, name, description, address, coordinates,
		radius, opens_at, closes_at, allowed_ticket_types, requires_extra_verification,
		assigned_staff, is_active, is_primary, total_scans, success_scans, failed_scans,
		created_at, updated_at FROM scan_locations WHERE id = ?`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	locs, err := scanLocations(rows)
	if err != nil {
		return nil, err
	}
	if len(locs) == 0 {
		return nil, nil
	}
	return locs[0], nil
}