package notificationservice

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"regexp"
	"time"

	"donjo_notifications/internal/messaging"
)

var (
	ErrNotFound = errors.New("notification not found")
)

// Service owns the SQLite notification database and implements every
// operation invoked by the message consumer and the HTTP API.
type Service struct {
	db  *sql.DB
	log *log.Logger
}

// New wires a Service onto an already-migrated SQLite handle.
func New(db *sql.DB) *Service {
	return &Service{db: db, log: log.New(log.Writer(), "[notify] ", log.LstdFlags)}
}

func (s *Service) now() string { return time.Now().UTC().Format(time.RFC3339) }

func (s *Service) logf(format string, args ...interface{}) {
	s.log.Printf(format, args...)
}

func newID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return hex.EncodeToString(b)
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

// CreateNotification persists a notification and, when feed fields are set, a
// companion feed item. Template-driven notifications are rendered here.
func (s *Service) CreateNotification(userID string, in *NotifyIn) (*Notification, error) {
	if in.Channel == "" {
		in.Channel = ChannelInApp
	}
	if in.Type == "" {
		in.Type = "generic"
	}
	if in.Priority == "" {
		in.Priority = "medium"
	}
	if in.Status == "" {
		in.Status = "pending"
	}
	if in.Channel == ChannelInApp && in.Status == "pending" {
		// In-app notifications are considered delivered the moment they're stored.
		in.Status = "delivered"
	}

	// Template rendering overrides any inline subject/content.
	if in.TemplateID != "" {
		tmpl, err := s.Template(in.TemplateID)
		if err != nil {
			return nil, err
		}
		if tmpl == nil || !tmpl.IsActive {
			return nil, fmt.Errorf("%w: template %q not found or inactive", ErrNotFound, in.TemplateID)
		}
		subj, content := RenderTemplate(tmpl, in.TemplateData)
		if in.Subject == "" {
			in.Subject = subj
		}
		if in.Content == "" {
			in.Content = content
		}
		if in.HTMLContent == "" && tmpl.HTMLTemplate != "" {
			in.HTMLContent = render(tmpl.HTMLTemplate, in.TemplateData)
		}
	}

	meta, _ := json.Marshal(in.Metadata)
	data, _ := json.Marshal(in.TemplateData)
	now := s.now()
	nID := newID()

	var deliveredAt interface{}
	if in.Status == "delivered" {
		deliveredAt = now
	}

	_, err := s.db.Exec(`
		INSERT INTO notifications
			(id, user_id, channel, type, subject, content, html_content,
			 template_id, template_data, status, priority,
			 reference_id, reference_type, metadata, retry_count,
			 created_at, updated_at, delivered_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)`,
		nID, userID, in.Channel, in.Type, orNull(in.Subject), in.Content,
		orNull(in.HTMLContent), orNull(in.TemplateID), orNull(string(data)),
		in.Status, in.Priority, orNull(in.ReferenceID), orNull(in.ReferenceType),
		orNull(string(meta)), now, now, deliveredAt,
	)
	if err != nil {
		return nil, fmt.Errorf("insert notification: %w", err)
	}

	if in.FeedType != "" {
		if err := s.addFeedItem(userID, nID, in.FeedType, in.FeedTitle, in.FeedMessage,
			in.FeedImageURL, feedPriority(in.FeedPriority), now); err != nil {
			return nil, err
		}
	}

	return s.NotificationByID(userID, nID)
}

// NotificationByID loads one of the user's notifications.
func (s *Service) NotificationByID(userID, id string) (*Notification, error) {
	row := s.db.QueryRow(`
		SELECT id, user_id, channel, type, subject, content, html_content,
		       template_id, template_data, status, sent_at, delivered_at,
		       read_at, clicked_at, error_message, retry_count, priority,
		       reference_id, reference_type, metadata, created_at, updated_at
		FROM notifications WHERE id = ? AND user_id = ?`, id, userID)

	n := &Notification{}
	var subject, html, tmplID, tmplData, sentAt, delAt, readAt, clickAt,
		errorMsg, refID, refType, meta, createdAt, updatedAt sql.NullString
	if err := row.Scan(&n.ID, &n.UserID, &n.Channel, &n.Type, &subject, &n.Content,
		&html, &tmplID, &tmplData, &n.Status, &sentAt, &delAt, &readAt, &clickAt,
		&errorMsg, &n.RetryCount, &n.Priority, &refID, &refType, &meta,
		&createdAt, &updatedAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	n.CreatedAt = parseTimeValue(createdAt.String)
	n.UpdatedAt = parseTimeValue(updatedAt.String)
	n.Subject = subject.String
	n.HTMLContent = html.String
	n.TemplateID = tmplID.String
	n.TemplateData = unmarshalMap(tmplData.String)
	n.SentAt = parseTimePtr(sentAt.String)
	n.DeliveredAt = parseTimePtr(delAt.String)
	n.ReadAt = parseTimePtr(readAt.String)
	n.ClickedAt = parseTimePtr(clickAt.String)
	n.ErrorMessage = errorMsg.String
	n.ReferenceID = refID.String
	n.ReferenceType = refType.String
	n.Metadata = unmarshalMap(meta.String)
	if n.TemplateData == nil {
		n.TemplateData = map[string]interface{}{}
	}
	if n.Metadata == nil {
		n.Metadata = map[string]interface{}{}
	}
	return n, nil
}

// ListNotifications returns the user's notifications, newest first.
func (s *Service) ListNotifications(userID, status string, limit int) ([]*Notification, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	q := `SELECT id, user_id, channel, type, subject, content, html_content,
		template_id, template_data, status, sent_at, delivered_at,
		read_at, clicked_at, error_message, retry_count, priority,
		reference_id, reference_type, metadata, created_at, updated_at
		FROM notifications WHERE user_id = ?`
	args := []interface{}{userID}
	if status != "" {
		q += ` AND status = ?`
		args = append(args, status)
	}
	q += ` ORDER BY created_at DESC, id DESC LIMIT ?`
	args = append(args, limit)

	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*Notification
	for rows.Next() {
		n := &Notification{}
		var subject, html, tmplID, tmplData, sentAt, delAt, readAt, clickAt,
			errorMsg, refID, refType, meta, createdAt, updatedAt sql.NullString
		if err := rows.Scan(&n.ID, &n.UserID, &n.Channel, &n.Type, &subject, &n.Content,
			&html, &tmplID, &tmplData, &n.Status, &sentAt, &delAt, &readAt, &clickAt,
			&errorMsg, &n.RetryCount, &n.Priority, &refID, &refType, &meta,
			&createdAt, &updatedAt); err != nil {
			return nil, err
		}
		n.CreatedAt = parseTimeValue(createdAt.String)
		n.UpdatedAt = parseTimeValue(updatedAt.String)
		n.Subject = subject.String
		n.HTMLContent = html.String
		n.TemplateID = tmplID.String
		n.TemplateData = unmarshalMap(tmplData.String)
		n.SentAt = parseTimePtr(sentAt.String)
		n.DeliveredAt = parseTimePtr(delAt.String)
		n.ReadAt = parseTimePtr(readAt.String)
		n.ClickedAt = parseTimePtr(clickAt.String)
		n.ErrorMessage = errorMsg.String
		n.ReferenceID = refID.String
		n.ReferenceType = refType.String
		n.Metadata = unmarshalMap(meta.String)
		if n.TemplateData == nil {
			n.TemplateData = map[string]interface{}{}
		}
		if n.Metadata == nil {
			n.Metadata = map[string]interface{}{}
		}
		out = append(out, n)
	}
	return out, rows.Err()
}

// MarkRead flags a notification as read (scoped to the user).
func (s *Service) MarkRead(userID, id string) error {
	return s.markNotification(userID, id, "read_at")
}

// MarkClicked flags a notification as clicked (and read).
func (s *Service) MarkClicked(userID, id string) error {
	if err := s.markNotification(userID, id, "read_at"); err != nil {
		return err
	}
	return s.markNotification(userID, id, "clicked_at")
}

func (s *Service) markNotification(userID, id, col string) error {
	now := s.now()
	res, err := s.db.Exec(`UPDATE notifications SET `+col+` = COALESCE(`+col+`, ?), updated_at = ?
		WHERE id = ? AND user_id = ?`, now, now, id, userID)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// UnreadCount returns how many of the user's notifications are unread.
func (s *Service) UnreadCount(userID string) (int, error) {
	var n int
	err := s.db.QueryRow(
		`SELECT COUNT(1) FROM notifications WHERE user_id = ? AND read_at IS NULL`, userID,
	).Scan(&n)
	return n, err
}

// ---------------------------------------------------------------------------
// Feed
// ---------------------------------------------------------------------------

func feedPriority(p *int) int {
	if p != nil {
		return *p
	}
	return 0
}

// addFeedItem inserts a user_feeds row linked to a notification (or standalone
// when notificationID is empty).
func (s *Service) addFeedItem(userID, notificationID, feedType, title, message, imageURL string, priority int, now string) error {
	_, err := s.db.Exec(`
		INSERT INTO user_feeds
			(id, user_id, notification_id, feed_type, priority, title, message,
			 image_url, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		newID(), userID, orNull(notificationID), feedType, priority,
		orNull(title), orNull(message), orNull(imageURL), now, now,
	)
	if err != nil {
		return fmt.Errorf("insert feed item: %w", err)
	}
	return nil
}

// Feed returns the user's non-expired feed items, highest-priority first.
func (s *Service) Feed(userID string, limit int, unreadOnly bool) ([]*FeedItem, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	q := `SELECT id, user_id, notification_id, feed_type, priority, position,
		title, message, image_url, viewed, viewed_at, clicked, clicked_at,
		interacted, interacted_at, expires_at, created_at, updated_at
		FROM user_feeds WHERE user_id = ?`
	args := []interface{}{userID}
	if unreadOnly {
		q += ` AND viewed = 0`
	}
	q += ` AND (expires_at IS NULL OR expires_at > ?)`
	args = append(args, s.now())
	q += ` ORDER BY priority DESC, created_at DESC, id DESC LIMIT ?`
	args = append(args, limit)

	rows, err := s.db.Query(q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*FeedItem
	for rows.Next() {
		it := &FeedItem{}
		var notifID, title, message, imageURL, viewedAt, clickedAt, interactedAt, expiresAt,
			createdAt, updatedAt sql.NullString
		var position sql.NullInt64
		var viewed, clicked, interacted int
		if err := rows.Scan(&it.ID, &it.UserID, &notifID, &it.FeedType, &it.Priority,
			&position, &title, &message, &imageURL, &viewed, &viewedAt, &clicked,
			&clickedAt, &interacted, &interactedAt, &expiresAt, &createdAt, &updatedAt); err != nil {
			return nil, err
		}
		it.Position = int(position.Int64)
		it.CreatedAt = parseTimeValue(createdAt.String)
		it.UpdatedAt = parseTimeValue(updatedAt.String)
		it.NotificationID = notifID.String
		it.Title = title.String
		it.Message = message.String
		it.ImageURL = imageURL.String
		it.Viewed = viewed == 1
		it.Clicked = clicked == 1
		it.Interacted = interacted == 1
		it.ViewedAt = parseTimePtr(viewedAt.String)
		it.ClickedAt = parseTimePtr(clickedAt.String)
		it.InteractedAt = parseTimePtr(interactedAt.String)
		it.ExpiresAt = parseTimePtr(expiresAt.String)
		out = append(out, it)
	}
	return out, rows.Err()
}

// convenience helpers for feed engagement flags
func (s *Service) markFeed(userID, id, col string) error {
	now := s.now()
	res, err := s.db.Exec(`UPDATE user_feeds SET `+col+` = COALESCE(`+col+`, ?), updated_at = ?
		WHERE id = ? AND user_id = ?`, now, now, id, userID)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// MarkFeedViewed flags a feed item as seen.
func (s *Service) MarkFeedViewed(userID, id string) error {
	return s.markFeed(userID, id, "viewed_at")
}

// MarkFeedClicked flags a feed item as opened (and viewed).
func (s *Service) MarkFeedClicked(userID, id string) error {
	if err := s.MarkFeedViewed(userID, id); err != nil {
		return err
	}
	return s.markFeed(userID, id, "clicked_at")
}

// MarkFeedInteracted flags a feed item as interacted with (and viewed).
func (s *Service) MarkFeedInteracted(userID, id string) error {
	if err := s.MarkFeedViewed(userID, id); err != nil {
		return err
	}
	return s.markFeed(userID, id, "interacted_at")
}

// ---------------------------------------------------------------------------
// Push devices
// ---------------------------------------------------------------------------

// RegisterDevice upserts an active push device for a user.
func (s *Service) RegisterDevice(userID string, in *DeviceIn) (*PushDevice, error) {
	if in.DeviceToken == "" || in.Platform == "" {
		return nil, errors.New("device_token and platform are required")
	}
	now := s.now()
	id := newID()
	_, err := s.db.Exec(`
		INSERT INTO push_devices
			(id, user_id, device_token, platform, device_id, device_name,
			 is_active, last_used_at, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
		ON CONFLICT(user_id, device_token) DO UPDATE SET
			platform = excluded.platform,
			device_id = excluded.device_id,
			device_name = excluded.device_name,
			is_active = 1,
			last_used_at = excluded.last_used_at,
			updated_at = excluded.updated_at`,
		id, userID, in.DeviceToken, in.Platform, orNull(in.DeviceID),
		orNull(in.DeviceName), now, now, now,
	)
	if err != nil {
		return nil, fmt.Errorf("register device: %w", err)
	}
	return s.deviceByToken(userID, in.DeviceToken)
}

func (s *Service) deviceByToken(userID, token string) (*PushDevice, error) {
	row := s.db.QueryRow(`
		SELECT id, user_id, device_token, platform, device_id, device_name,
		       is_active, last_used_at, created_at, updated_at
		FROM push_devices WHERE user_id = ? AND device_token = ?`, userID, token)
	return scanDevice(row)
}

// Devices lists the user's push devices.
func (s *Service) Devices(userID string) ([]*PushDevice, error) {
	rows, err := s.db.Query(`
		SELECT id, user_id, device_token, platform, device_id, device_name,
		       is_active, last_used_at, created_at, updated_at
		FROM push_devices WHERE user_id = ? ORDER BY created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*PushDevice
	for rows.Next() {
		d, err := scanDevice(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

// DeleteDevice deactivates a device (scoped to the user).
func (s *Service) DeleteDevice(userID, deviceID string) error {
	res, err := s.db.Exec(`UPDATE push_devices SET is_active = 0, updated_at = ?
		WHERE id = ? AND user_id = ?`, s.now(), deviceID, userID)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// optedInUsers returns distinct user ids with at least one active push device.
func (s *Service) optedInUsers() ([]string, error) {
	rows, err := s.db.Query(`SELECT DISTINCT user_id FROM push_devices WHERE is_active = 1`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var u string
		if err := rows.Scan(&u); err != nil {
			return nil, err
		}
		out = append(out, u)
	}
	return out, rows.Err()
}

type scanner interface {
	Scan(dest ...interface{}) error
}

func scanDevice(row scanner) (*PushDevice, error) {
	d := &PushDevice{}
	var deviceID, deviceName, lastUsed, createdAt, updatedAt sql.NullString
	var active int
	if err := row.Scan(&d.ID, &d.UserID, &d.DeviceToken, &d.Platform, &deviceID,
		&deviceName, &active, &lastUsed, &createdAt, &updatedAt); err != nil {
		return nil, err
	}
	d.DeviceID = deviceID.String
	d.DeviceName = deviceName.String
	d.IsActive = active == 1
	d.LastUsedAt = parseTimePtr(lastUsed.String)
	d.CreatedAt = parseTimeValue(createdAt.String)
	d.UpdatedAt = parseTimeValue(updatedAt.String)
	return d, nil
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

// Template loads one template by id.
func (s *Service) Template(id string) (*NotificationTemplate, error) {
	row := s.db.QueryRow(`
		SELECT id, name, type, subject_template, content_template, html_template,
		       required_variables, is_active, created_at, updated_at
		FROM notification_templates WHERE id = ?`, id)
	var reqVars, subject, html, createdAt, updatedAt sql.NullString
	var active int
	t := &NotificationTemplate{}
	if err := row.Scan(&t.ID, &t.Name, &t.Type, &subject, &t.ContentTemplate,
		&html, &reqVars, &active, &createdAt, &updatedAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	t.SubjectTemplate = subject.String
	t.HTMLTemplate = html.String
	t.IsActive = active == 1
	t.CreatedAt = parseTimeValue(createdAt.String)
	t.UpdatedAt = parseTimeValue(updatedAt.String)
	_ = json.Unmarshal([]byte(reqVars.String), &t.RequiredVariables)
	return t, nil
}

// Templates lists active templates, alpha by name.
func (s *Service) Templates() ([]*NotificationTemplate, error) {
	rows, err := s.db.Query(`
		SELECT id, name, type, subject_template, content_template, html_template,
		       required_variables, is_active, created_at, updated_at
		FROM notification_templates WHERE is_active = 1 ORDER BY name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []*NotificationTemplate
	for rows.Next() {
		var reqVars, subject, html, createdAt, updatedAt sql.NullString
		var active int
		t := &NotificationTemplate{}
		if err := rows.Scan(&t.ID, &t.Name, &t.Type, &subject, &t.ContentTemplate,
			&html, &reqVars, &active, &createdAt, &updatedAt); err != nil {
			return nil, err
		}
		t.SubjectTemplate = subject.String
		t.HTMLTemplate = html.String
		t.IsActive = active == 1
		t.CreatedAt = parseTimeValue(createdAt.String)
		t.UpdatedAt = parseTimeValue(updatedAt.String)
		_ = json.Unmarshal([]byte(reqVars.String), &t.RequiredVariables)
		out = append(out, t)
	}
	return out, rows.Err()
}

// ---------------------------------------------------------------------------
// Events (from donjo.events)
// ---------------------------------------------------------------------------

// OnTicketPurchased turns a ticket.purchased message into a buyer order
// confirmation and a creator sale alert, each with a feed item.
func (s *Service) OnTicketPurchased(in interface{}) error {
	p, err := decodePurchase(in)
	if err != nil {
		return err
	}
	if p.UserID == "" {
		s.logf("ticket.purchased: user_id missing, skipping")
		return nil
	}

	qty := p.Quantity
	if qty < 1 {
		qty = 1
	}

	// Buyer confirmation.
	_, err = s.CreateNotification(p.UserID, &NotifyIn{
		Channel:       ChannelInApp,
		Type:          "purchase_confirmation",
		TemplateID:    "00000000-0000-0000-0000-000000000001",
		TemplateData: map[string]interface{}{
			"event_title": p.EventTitle,
			"quantity":    qty,
			"ticket_name": p.TicketName,
			"order_id":    p.OrderID,
			"amount":      p.Amount,
			"currency":    p.Currency,
		},
		Status:        "delivered",
		ReferenceID:   p.OrderID,
		ReferenceType: "purchase",
		FeedType:      "purchase",
		FeedTitle:     p.EventTitle,
		FeedMessage:   fmt.Sprintf("You're going! %d x %s confirmed (order %s).", qty, p.TicketName, p.OrderID),
		FeedPriority:  intPtr(2),
	})
	if err != nil {
		return fmt.Errorf("buyer confirmation: %w", err)
	}

	// Creator sale alert, when the sale targets someone other than the buyer.
	if p.CreatorID != "" && p.CreatorID != p.UserID {
		_, err = s.CreateNotification(p.CreatorID, &NotifyIn{
			Channel:    ChannelInApp,
			Type:       "sale_alert",
			TemplateID: "00000000-0000-0000-0000-000000000002",
			TemplateData: map[string]interface{}{
				"event_title": p.EventTitle,
				"quantity":    qty,
				"ticket_name": p.TicketName,
			},
			Status:        "delivered",
			ReferenceID:   p.OrderID,
			ReferenceType: "sale",
			FeedType:      "sale",
			FeedTitle:     p.EventTitle,
			FeedMessage:   fmt.Sprintf("New sale: %d x %s.", qty, p.TicketName),
			FeedPriority:  intPtr(2),
		})
		if err != nil {
			return fmt.Errorf("creator sale alert: %w", err)
		}
	}

	s.logf("ticket.purchased: notified buyer %s (order %s)", p.UserID, p.OrderID)
	return nil
}

// OnEventPublished turns an event.published message into event-discovery feed
// items for every opted-in user (those with an active push device).
func (s *Service) OnEventPublished(in interface{}) error {
	ev, err := decodeEventPublished(in)
	if err != nil {
		return err
	}
	if ev.EventID == "" {
		s.logf("event.published: missing event id, skipping")
		return nil
	}

	users, err := s.optedInUsers()
	if err != nil {
		return err
	}
	if len(users) == 0 {
		s.logf("event.published: no opted-in users yet")
		return nil
	}

	now := s.now()
	for _, uid := range users {
		n := &Notification{
			ID:            newID(),
			UserID:        uid,
			Channel:       ChannelInApp,
			Type:          "event_discovery",
			Status:        "delivered",
			DeliveredAt:   parseTime(now),
			Priority:      "medium",
			ReferenceID:   ev.EventID,
			ReferenceType: "event",
			Content:       fmt.Sprintf("%s is coming up on Donjo — reserve your spot.", ev.Title),
		}
		if err := s.insertNotification(n, now); err != nil {
			return err
		}
		if err := s.addFeedItem(uid, n.ID, "event_discovery", ev.Title, n.Content, "", 1, now); err != nil {
			return err
		}
	}
	s.logf("event.published: discovery feed items for %d opted-in users", len(users))
	return nil
}

// insertNotification is the low-level row write used by event handlers.
func (s *Service) insertNotification(n *Notification, now string) error {
	meta, _ := json.Marshal(map[string]interface{}{})
	_, err := s.db.Exec(`
		INSERT INTO notifications
			(id, user_id, channel, type, subject, content, html_content,
			 template_id, template_data, status, sent_at, delivered_at,
			 read_at, clicked_at, error_message, retry_count, priority,
			 reference_id, reference_type, metadata, created_at, updated_at)
		VALUES (?, ?, ?, ?, NULL, ?, NULL, NULL, NULL, ?, NULL, ?, NULL, NULL,
		        NULL, 0, ?, ?, ?, ?, ?, ?)`,
		n.ID, n.UserID, n.Channel, n.Type, n.Content, n.Status, orNullPtr(n.DeliveredAt),
		n.Priority, orNull(n.ReferenceID), n.ReferenceType, string(meta), now, now,
	)
	if err != nil {
		return fmt.Errorf("insert event notification: %w", err)
	}
	return nil
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

func orNull(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

func orNullPtr(t *time.Time) interface{} {
	if t == nil {
		return nil
	}
	return t.UTC().Format(time.RFC3339)
}

func intPtr(n int) *int { return &n }

func unmarshalMap(raw string) map[string]interface{} {
	if raw == "" {
		return nil
	}
	var m map[string]interface{}
	if err := json.Unmarshal([]byte(raw), &m); err != nil {
		return nil
	}
	return m
}

func parseTime(s string) *time.Time {
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		return nil
	}
	return &t
}

func parseTimePtr(s string) *time.Time {
	if s == "" {
		return nil
	}
	return parseTime(s)
}

// parseTimeValue parses a stored timestamp into a time.Time, tolerating both
// app-written RFC3339 strings and SQLite's native CURRENT_TIMESTAMP format.
func parseTimeValue(s string) time.Time {
	if t := parseTime(s); t != nil {
		return *t
	}
	v, err := time.Parse("2006-01-02 15:04:05", s)
	if err != nil {
		return time.Time{}
	}
	return v
}

var placeholder = regexp.MustCompile(`\{\{\s*([a-zA-Z0-9_]+)\s*\}\}`)

func render(s string, data map[string]interface{}) string {
	return placeholder.ReplaceAllStringFunc(s, func(m string) string {
		key := placeholder.FindStringSubmatch(m)[1]
		if v, ok := data[key]; ok {
			return fmt.Sprintf("%v", v)
		}
		return m
	})
}

// RenderTemplate fills a template's subject and content strings.
func RenderTemplate(t *NotificationTemplate, data map[string]interface{}) (subject, content string) {
	subject = render(t.SubjectTemplate, data)
	content = render(t.ContentTemplate, data)
	return subject, content
}

func decodePurchase(in interface{}) (*messaging.TicketPurchased, error) {
	b, err := json.Marshal(in)
	if err != nil {
		return nil, err
	}
	p := &messaging.TicketPurchased{}
	return p, json.Unmarshal(b, p)
}

func decodeEventPublished(in interface{}) (*messaging.EventPublished, error) {
	b, err := json.Marshal(in)
	if err != nil {
		return nil, err
	}
	ev := &messaging.EventPublished{}
	return ev, json.Unmarshal(b, ev)
}