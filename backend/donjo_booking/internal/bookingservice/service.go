package bookingservice

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"time"

	"donjo_booking/internal/messaging"
	"donjo_booking/internal/models"
	"donjo_booking/internal/repository"
)

// Sentinels the handler maps onto HTTP status codes.
var (
	ErrNotFound   = errors.New("not found")
	ErrForbidden  = errors.New("forbidden")
	ErrConflict   = errors.New("conflict")
	ErrBadRequest = errors.New("bad request")
	ErrInternal   = errors.New("internal error")
)

// BookingService implements the booking domain: async order intake, holder
// assignment, ticket shares/claims, resale, waitlist, and gate check-in.
type BookingService struct {
	bookings  *repository.BookingRepository
	instances *repository.InstanceRepository
	checkin   *repository.CheckinRepository
	waitlist  *repository.WaitlistRepository
	auditLog  *log.Logger
}

func New(bookings *repository.BookingRepository, instances *repository.InstanceRepository,
	checkin *repository.CheckinRepository, waitlist *repository.WaitlistRepository) *BookingService {
	return &BookingService{
		bookings: bookings,
		instances: instances,
		checkin:  checkin,
		waitlist: waitlist,
		auditLog: log.Default(),
	}
}

func (s *BookingService) audit(format string, args ...interface{}) {
	s.auditLog.Printf("[booking] "+format, args...)
}

// ---- async intake (RabbitMQ consumer) ---------------------------------------

// HandlePurchase creates the booking and mints one instance per seat. Called
// from the ticket.purchased consumer; a failure requeues the message.
func (s *BookingService) HandlePurchase(p messaging.TicketPurchased) error {
	if p.UserID == "" || p.EventID == "" || p.TicketID == "" || p.Quantity <= 0 {
		return errors.New("incomplete ticket.purchased payload")
	}
	snap := models.BookingSnapshot{
		OrderID:       p.OrderID,
		EventID:       p.EventID,
		EventSlug:     p.EventSlug,
		EventTitle:    p.EventTitle,
		TicketID:      p.TicketID,
		TicketType:    p.TicketType,
		TicketName:    p.TicketName,
		Quantity:      p.Quantity,
		UnitPrice:     p.UnitPrice,
		ServiceFee:    p.ServiceFee,
		ProcessingFee: p.ProcessingFee,
		Amount:        p.Amount,
		Currency:      p.Currency,
		UserID:        p.UserID,
		UserEmail:     p.UserEmail,
	}
	b, err := s.bookings.CreateFromPurchase(snap)
	if err != nil {
		return fmt.Errorf("create booking: %w", err)
	}
	s.audit("booking %s created for %s (%d %s)", b.BookingReference, p.UserID, p.Quantity, p.TicketName)
	return nil
}

// ApplyPayment backfills the booking with the payment service's ids once
// payment.processed arrives. Called from the consumer; a failure requeues.
func (s *BookingService) ApplyPayment(p messaging.PaymentProcessed) error {
	if p.OrderID == "" || p.TransactionID == "" || p.EscrowID == "" {
		return errors.New("incomplete payment.processed payload")
	}
	method := p.PaymentMethod
	if method == "" {
		method = "mpesa"
	}
	if err := s.bookings.ApplyPayment(p.OrderID, p.TransactionID, p.EscrowID, p.EscrowStatus, method); err != nil {
		return fmt.Errorf("backfill payment on %s: %w", p.OrderID, err)
	}
	s.audit("booking %s matched payment txn %s / escrow %s", p.OrderID, p.TransactionID, p.EscrowID)
	return nil
}

// ---- bookings ----------------------------------------------------------------

func (s *BookingService) ListMyBookings(userID string) ([]*models.Booking, error) {
	bs, err := s.bookings.ListByUser(userID)
	if err != nil {
		return nil, err
	}
	if err := s.bookings.AttachInstances(bs); err != nil {
		return nil, err
	}
	return bs, nil
}

func (s *BookingService) BookingDetail(userID, id string) (*models.Booking, error) {
	b, err := s.bookings.Get(id)
	if err != nil || b == nil {
		return nil, ErrNotFound
	}
	if b.UserID != userID {
		return nil, ErrForbidden
	}
	if err := s.bookings.AttachInstances([]*models.Booking{b}); err != nil {
		return nil, err
	}
	return b, nil
}

// ---- instances / group assignment ---------------------------------------------

// InstancesForUser enriches instances with event/ticket context for display.
func (s *BookingService) InstancesForUser(userID string) ([]*models.TicketInstance, error) {
	return s.instances.ListForUserWithMeta(userID)
}

// AssignHolder records the named person a group ticket is for. Each instance
// of a group purchase is assigned per seat.
func (s *BookingService) AssignHolder(userID, instanceID, name, email, phone string) (*models.TicketInstance, error) {
	inst, err := s.instances.Get(instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil || inst.UserID != userID {
		return nil, ErrNotFound
	}
	if inst.Status != models.InstanceActive {
		return nil, ErrConflict
	}
	if err := s.instances.Assign(instanceID, name, email, phone); err != nil {
		return nil, ErrInternal
	}
	s.audit("instance %s assigned to holder %s", instanceID, name)
	return s.instances.Get(instanceID)
}

// ---- transfer (share / claim) --------------------------------------------------

// ShareTicket offers a ticket to another person. The code is rotated
// immediately so the current holder's version stops working at the gate; the
// claimer receives it on claim.
func (s *BookingService) ShareTicket(userID, instanceID, email string) (*models.TicketInstance, error) {
	inst, err := s.instances.Get(instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil || inst.UserID != userID {
		return nil, ErrNotFound
	}
	if !inst.TransferAllowed {
		return nil, ErrForbidden
	}
	if inst.Status != models.InstanceActive {
		return nil, ErrConflict
	}

	code, err := transferCode()
	if err != nil {
		return nil, ErrInternal
	}
	res, err := s.instances.Exec(`UPDATE ticket_instances SET
			ticket_code = ?, qr_code_data = ?, transfer_code = ?, status = ?,
			holder_email = ?,
			listed_price = NULL, listed_at = NULL
		WHERE id = ? AND status IN ('active','resold')`,
		code, "DONJO:"+code, code, models.InstancePendingClaim, email, instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if err := requireOne(res); err != nil {
		return nil, ErrConflict
	}
	s.audit("instance %s shared to %s", instanceID, email)
	return s.instances.Get(instanceID)
}

// ClaimTicket completes a share. Only the person the ticket was offered to
// (email match) may claim; the pre-issued code becomes theirs.
func (s *BookingService) ClaimTicket(userID, email, code string) (*models.TicketInstance, error) {
	inst, err := s.instances.GetByTransferCode(code)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil {
		return nil, ErrNotFound
	}
	if email == "" || inst.HolderEmail == "" || !stringsEqualFold(email, inst.HolderEmail) {
		return nil, ErrForbidden
	}
	if inst.Status != models.InstancePendingClaim {
		return nil, ErrConflict
	}
	now := time.Now().UTC().Format(time.RFC3339)
	res, err := s.instances.Exec(`UPDATE ticket_instances SET
			status = 'active', user_id = ?, transferred = 1,
			transferred_from = ?, transferred_to = ?, transferred_at = ?,
			transfer_code = NULL
		WHERE id = ? AND status = 'pending_claim'`,
		userID, inst.UserID, userID, now, inst.ID)
	if err != nil {
		return nil, ErrInternal
	}
	if err := requireOne(res); err != nil {
		return nil, ErrConflict
	}
	s.audit("instance %s claimed by %s (from %s)", inst.ID, userID, inst.UserID)
	return s.instances.Get(inst.ID)
}

// CancelShare returns an offered ticket to the owner's active queue and mints
// a fresh code (the offered one is dead).
func (s *BookingService) CancelShare(userID, instanceID string) (*models.TicketInstance, error) {
	inst, err := s.instances.Get(instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil || inst.UserID != userID {
		return nil, ErrNotFound
	}
	if inst.Status != models.InstancePendingClaim {
		return nil, ErrConflict
	}
	newCode := rotatingCode()
	res, err := s.instances.Exec(`UPDATE ticket_instances SET
			status = 'active', transfer_code = NULL,
			ticket_code = ?, qr_code_data = ? WHERE id = ? AND status = 'pending_claim'`,
		newCode, "DONJO:"+newCode, instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if err := requireOne(res); err != nil {
		return nil, ErrConflict
	}
	return s.instances.Get(instanceID)
}

// ---- resale --------------------------------------------------------------------

func (s *BookingService) ListForResale(userID, instanceID string, price float64) (*models.TicketInstance, error) {
	if price <= 0 {
		return nil, ErrBadRequest
	}
	inst, err := s.instances.Get(instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil || inst.UserID != userID {
		return nil, ErrNotFound
	}
	if !inst.TransferAllowed {
		return nil, ErrForbidden
	}
	if inst.Status != models.InstanceActive {
		return nil, ErrConflict
	}
	now := time.Now().UTC().Format(time.RFC3339)
	res, err := s.instances.Exec(`UPDATE ticket_instances SET
			status = 'listed', listed_price = ?, listed_at = ? WHERE id = ? AND status = 'active'`,
		price, now, instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if err := requireOne(res); err != nil {
		return nil, ErrConflict
	}
	s.audit("instance %s listed for resale at %.2f", instanceID, price)
	return s.instances.Get(instanceID)
}

func (s *BookingService) UnlistResale(userID, instanceID string) (*models.TicketInstance, error) {
	inst, err := s.instances.Get(instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil || inst.UserID != userID {
		return nil, ErrNotFound
	}
	if inst.Status != models.InstanceListed {
		return nil, ErrConflict
	}
	now := time.Now().UTC().Format(time.RFC3339)
	res, err := s.instances.Exec(`UPDATE ticket_instances SET
			status = 'active', unlisted_at = ?, listed_price = NULL, listed_at = NULL
		WHERE id = ? AND status = 'listed'`, now, instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if err := requireOne(res); err != nil {
		return nil, ErrConflict
	}
	return s.instances.Get(instanceID)
}

func (s *BookingService) Marketplace() ([]*models.TicketInstance, error) {
	return s.instances.MarketplaceWithMeta()
}

// BuyResale sells a listed instance to the buyer. The code is rotated at sale
// time so the seller's version stops working; ownership moves and the status
// resets to "active" so the buyer can share or relist it.
func (s *BookingService) BuyResale(buyerID, instanceID string) (*models.TicketInstance, error) {
	inst, err := s.instances.Get(instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if inst == nil {
		return nil, ErrNotFound
	}
	if inst.UserID == buyerID {
		return nil, ErrForbidden
	}
	if inst.Status != models.InstanceListed || inst.ListedPrice == nil {
		return nil, ErrConflict
	}
	newCode := rotatingCode()
	now := time.Now().UTC().Format(time.RFC3339)
	res, err := s.instances.Exec(`UPDATE ticket_instances SET
			status = 'active', user_id = ?, ticket_code = ?, qr_code_data = ?,
			transferred = 1, transferred_from = ?, transferred_to = ?, transferred_at = ?,
			resold_price = listed_price, resold_at = ?, listed_at = NULL, listed_price = NULL,
			transfer_code = NULL
		WHERE id = ? AND status = 'listed'`,
		buyerID, newCode, "DONJO:"+newCode, inst.UserID, buyerID, now,
		now, instanceID)
	if err != nil {
		return nil, ErrInternal
	}
	if err := requireOne(res); err != nil {
		return nil, ErrConflict
	}
	s.audit("instance %s resold at %.2f to %s", instanceID, *inst.ListedPrice, buyerID)
	return s.instances.Get(instanceID)
}

// ---- check-in --------------------------------------------------------------------

type CheckinResult struct {
	Allowed  bool                     `json:"allowed"`
	Message  string                   `json:"message"`
	Instance *models.TicketInstance   `json:"instance,omitempty"`
}

// Checkin validates a scanned code at the gate. Every attempt is logged with
// the status seen; failed scans are deliberately uninformative ("invalid
// ticket") so the code itself never confirms or denies ownership to a stranger.
func (s *BookingService) Checkin(scannerID, ip, device, location, code string) (*CheckinResult, error) {
	inst, err := s.instances.GetByCode(code)
	if err != nil {
		return nil, ErrInternal
	}
	logEntry := &models.QRScanLog{
		UserID:        scannerID,
		ScannerID:     scannerID,
		QRCodeScanned: code,
		ScanIP:        ip,
		ScanDeviceInfo: device,
		ScanLocation:  location,
		ScanType:      "entry",
		ScanResult:    "blocked",
	}
	defer func() {
		if inst != nil {
			logEntry.TicketInstanceID = inst.ID
			logEntry.EventID = inst.EventID
			logEntry.BookingID = inst.BookingID
			logEntry.TicketStatusBefore = inst.Status
		}
		_, _ = s.checkin.RecordScan(logEntry)
	}()

	if inst == nil {
		return &CheckinResult{Allowed: false, Message: "invalid ticket"}, nil
	}
	switch inst.Status {
	case models.InstanceVoid, models.InstanceListed, models.InstancePendingClaim:
		logEntry.ResponseMessage = "ticket not valid at gate"
		return &CheckinResult{Allowed: false, Message: "invalid ticket"}, nil
	case models.InstanceUsed:
		if inst.CheckedIn {
			logEntry.ResponseMessage = "already checked in"
			return &CheckinResult{Allowed: false, Message: "already checked in"}, nil
		}
	}

	changed, err := s.checkin.MarkUsed(inst.ID, scannerID, location)
	if err != nil {
		return nil, ErrInternal
	}
	if changed {
		logEntry.ScanResult = "success"
		logEntry.TicketStatusAfter = "used"
		logEntry.ResponseMessage = "checked in"
		logEntry.ResponseCode = "CHECKED_IN"
		s.audit("instance %s checked in by scanner %s at %s", inst.ID, scannerID, location)
	} else {
		logEntry.ResponseMessage = "already checked in"
	}
	out, _ := s.instances.Get(inst.ID)
	return &CheckinResult{Allowed: true, Message: "checked in", Instance: out}, nil
}

// ---- waitlist + scan locations ----------------------------------------------------

func (s *BookingService) JoinWaitlist(userID, eventID, ticketType string, qty int) error {
	if eventID == "" || qty < 1 {
		return ErrBadRequest
	}
	return s.waitlist.Join(models.WaitlistEntry{
		EventID: eventID, UserID: userID, TicketType: ticketType, Quantity: qty,
	})
}

func (s *BookingService) LeaveWaitlist(userID, eventID string) error {
	return s.waitlist.Leave(eventID, userID)
}

func (s *BookingService) Waitlist(eventID string) ([]*models.WaitlistEntry, int, error) {
	es, err := s.waitlist.List(eventID)
	if err != nil {
		return nil, 0, err
	}
	n, err := s.waitlist.Count(eventID)
	if err != nil {
		return nil, 0, err
	}
	return es, n, nil
}

func (s *BookingService) CreateScanLocation(l *models.ScanLocation) error {
	if l.EventID == "" || l.Name == "" {
		return ErrBadRequest
	}
	return s.checkin.CreateLocation(l)
}

func (s *BookingService) ScanLocations(eventID string) ([]*models.ScanLocation, error) {
	return s.checkin.ListLocations(eventID)
}

// ---- helpers ----------------------------------------------------------------------

func transferCode() (string, error) {
	b := make([]byte, 12)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func rotatingCode() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func stringsEqualFold(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := 0; i < len(a); i++ {
		// ascii lowercasing is enough for emails in practice
		ca, cb := a[i], b[i]
		if 'A' <= ca && ca <= 'Z' {
			ca += 'a' - 'A'
		}
		if 'A' <= cb && cb <= 'Z' {
			cb += 'a' - 'A'
		}
		if ca != cb {
			return false
		}
	}
	return true
}

func requireOne(res result) error {
	if res == nil {
		return errors.New("no result")
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n != 1 {
		return ErrConflict
	}
	return nil
}

type result interface {
	RowsAffected() (int64, error)
}