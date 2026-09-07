package eventservice

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"donjo_event/internal/messaging"
	"donjo_event/internal/models"
	"donjo_event/internal/repository"
)

var (
	ErrNotFound     = errors.New("not found")
	ErrConflict     = errors.New("conflict: resource with same identifier already exists")
	ErrUnauthorized = errors.New("not authorized to perform this action")
	ErrInvalidInput = errors.New("invalid input")
	ErrSoldOut      = errors.New("tickets sold out")
	ErrNotPublished = errors.New("event is not published")
)

type Service struct {
	db      *repository.EventRepository
	venues  *repository.VenueRepository
	tickets *repository.TicketRepository
	bus     *messaging.Client
}

func NewService(db *repository.EventRepository, venues *repository.VenueRepository, tickets *repository.TicketRepository, bus *messaging.Client) *Service {
	if bus == nil {
		bus = &messaging.Client{}
	}
	return &Service{db: db, venues: venues, tickets: tickets, bus: bus}
}

// ---- Events ----

func (s *Service) CreateEvent(creatorID string, in *models.Event) (*models.Event, error) {
	if in.Title == "" || in.Category == "" {
		return nil, fmt.Errorf("%w: title and category are required", ErrInvalidInput)
	}
	if in.StartTime.IsZero() || in.EndTime.IsZero() {
		return nil, fmt.Errorf("%w: start_time and end_time are required", ErrInvalidInput)
	}
	if in.EndTime.Before(in.StartTime) {
		return nil, fmt.Errorf("%w: end_time must be after start_time", ErrInvalidInput)
	}
	if in.TotalCapacity <= 0 {
		return nil, fmt.Errorf("%w: total_capacity must be greater than zero", ErrInvalidInput)
	}
	if in.Slug == "" {
		in.Slug = Slugify(in.Title)
	}

	if taken, err := s.db.SlugTaken(in.Slug); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: slug '%s' is taken", ErrConflict, in.Slug)
	}

	in.CreatorID = creatorID
	if in.EventType == "" {
		in.EventType = "in_person"
	}
	if in.Status == "" {
		in.Status = "draft"
	}
	if in.Country == "" {
		in.Country = "Kenya"
	}
	if in.Timezone == "" {
		in.Timezone = "Africa/Nairobi"
	}
	// Schema defaults these to TRUE (1); Go zero values are FALSE, so promote
	// them to the SQL defaults when unset by the caller.
	in.TicketTransferAllowed = true
	in.AllowWaitlist = true
	if in.AvailableTickets == nil {
		avail := in.TotalCapacity
		in.AvailableTickets = &avail
	}
	if in.MinTicketPrice == 0 && in.MaxTicketPrice == 0 {
		in.IsFree = true
	}

	id, err := s.db.Create(in)
	if err != nil {
		return nil, err
	}

	created, err := s.db.GetByID(id)
	if err != nil || created == nil {
		return created, err
	}

	s.bus.Publish(messaging.KeyEventCreated, messaging.Envelope{
		Resource: "event",
		EventID:  created.ID,
		Data:     created,
	})
	return created, nil
}

func (s *Service) GetEvent(id string) (*models.Event, error) {
	e, err := s.db.GetByID(id)
	if err != nil {
		return nil, err
	}
	if e == nil {
		return nil, ErrNotFound
	}
	tickets, err := s.tickets.ListByEvent(e.ID)
	if err != nil {
		return nil, err
	}
	e.Tickets = tickets
	return e, nil
}

func (s *Service) GetEventBySlug(slug string) (*models.Event, error) {
	e, err := s.db.GetBySlug(slug)
	if err != nil {
		return nil, err
	}
	if e == nil {
		return nil, ErrNotFound
	}
	tickets, err := s.tickets.ListByEvent(e.ID)
	if err != nil {
		return nil, err
	}
	e.Tickets = tickets
	return e, nil
}

func (s *Service) ListEvents(actor string, f repository.EventFilter) ([]*models.Event, error) {
	// Public browsing (and other people's events) only surfaces active
	// (published) events. Creators can see their own drafts by passing their
	// creator_id. An explicit ?status= is always respected.
	if f.Status == "" {
		if f.CreatorID == "" || f.CreatorID != actor {
			f.Status = "active"
		}
	}
	return s.db.List(f)
}

func (s *Service) UpdateEvent(actorID, id string, in *models.Event) (*models.Event, error) {
	existing, err := s.db.GetByID(id)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, ErrNotFound
	}
	if existing.CreatorID != actorID {
		return nil, ErrUnauthorized
	}

	in.ID = id
	in.CreatorID = existing.CreatorID
	if in.Status == "" {
		in.Status = existing.Status
	}
	// Preserve immutable atomics
	in.Views = existing.Views
	in.Likes = existing.Likes
	in.Shares = existing.Shares
	in.TicketsSold = existing.TicketsSold
	in.Revenue = existing.Revenue

	if err := s.db.Update(in); err != nil {
		return nil, err
	}

	updated, err := s.db.GetByID(id)
	if err != nil || updated == nil {
		return updated, err
	}

	s.bus.Publish(messaging.KeyEventUpdated, messaging.Envelope{
		Resource: "event",
		EventID:  updated.ID,
		Data:     updated,
	})
	return updated, nil
}

func (s *Service) DeleteEvent(actorID, id string) error {
	existing, err := s.db.GetByID(id)
	if err != nil {
		return err
	}
	if existing == nil {
		return ErrNotFound
	}
	if existing.CreatorID != actorID {
		return ErrUnauthorized
	}
	if err := s.db.Delete(id); err != nil {
		return err
	}
	s.bus.Publish(messaging.KeyEventDeleted, messaging.Envelope{
		Resource: "event",
		EventID:  id,
		Data: map[string]interface{}{
			"creator_id": existing.CreatorID,
			"title":      existing.Title,
			"slug":       existing.Slug,
		},
	})
	return nil
}

func (s *Service) PublishEvent(actorID, id string) (*models.Event, error) {
	existing, err := s.db.GetByID(id)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, ErrNotFound
	}
	if existing.CreatorID != actorID {
		return nil, ErrUnauthorized
	}
	if err := s.db.Publish(id); err != nil {
		return nil, err
	}
	updated, err := s.db.GetByID(id)
	if err != nil || updated == nil {
		return updated, err
	}
	s.bus.Publish(messaging.KeyEventPublished, messaging.Envelope{
		Resource: "event",
		EventID:  updated.ID,
		Data: messaging.EventPublished{
			EventID: updated.ID,
			Slug:    updated.Slug,
			Title:   updated.Title,
		},
	})
	return updated, nil
}

func (s *Service) UnpublishEvent(actorID, id string) error {
	existing, err := s.db.GetByID(id)
	if err != nil {
		return err
	}
	if existing == nil {
		return ErrNotFound
	}
	if existing.CreatorID != actorID {
		return ErrUnauthorized
	}
	return s.db.Unpublish(id)
}

func (s *Service) IncrementViews(id string) {
	_ = s.db.IncrementViews(id)
}

func (s *Service) LikeEvent(id string) error {
	if _, err := s.db.GetByID(id); err != nil {
		return ErrNotFound
	}
	return s.db.IncrementLike(id)
}

// ---- Venues ----

func (s *Service) CreateVenue(creatorID string, in *models.Venue) (*models.Venue, error) {
	if in.Name == "" || in.Address == "" || in.VenueType == "" || in.Capacity <= 0 {
		return nil, fmt.Errorf("%w: name, address, venue_type and capacity > 0 are required", ErrInvalidInput)
	}
	if in.BasePrice < 0 {
		return nil, fmt.Errorf("%w: base_price cannot be negative", ErrInvalidInput)
	}
	if in.Slug == "" {
		in.Slug = Slugify(in.Name)
	}
	if taken, err := s.venues.SlugTaken(in.Slug); err != nil {
		return nil, err
	} else if taken {
		return nil, fmt.Errorf("%w: slug '%s' is taken", ErrConflict, in.Slug)
	}

	in.CreatorID = creatorID
	if in.Country == "" {
		in.Country = "Kenya"
	}
	if in.PricingType == "" {
		in.PricingType = "hourly"
	}
	if in.Status == "" {
		in.Status = "pending_verification"
	}
	in.IsAvailable = true
	if in.MinBookingHours == 0 {
		in.MinBookingHours = 2
	}
	if in.MaxBookingHours == 0 {
		in.MaxBookingHours = 12
	}

	id, err := s.venues.Create(in)
	if err != nil {
		return nil, err
	}
	created, err := s.venues.GetByID(id)
	if err != nil || created == nil {
		return created, err
	}
	s.bus.Publish(messaging.KeyVenueCreated, messaging.Envelope{
		Resource: "venue",
		EventID:  created.ID,
		Data:     created,
	})
	return created, nil
}

func (s *Service) GetVenue(id string) (*models.Venue, error) {
	v, err := s.venues.GetByID(id)
	if err != nil {
		return nil, err
	}
	if v == nil {
		return nil, ErrNotFound
	}
	return v, nil
}

func (s *Service) ListVenues(f repository.VenueFilter) ([]*models.Venue, error) {
	return s.venues.List(f)
}

func (s *Service) UpdateVenue(actorID, id string, in *models.Venue) (*models.Venue, error) {
	existing, err := s.venues.GetByID(id)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, ErrNotFound
	}
	if existing.CreatorID != actorID {
		return nil, ErrUnauthorized
	}
	in.ID = id
	in.CreatorID = existing.CreatorID
	in.EventsHosted = existing.EventsHosted
	in.Rating = existing.Rating
	in.ReviewCount = existing.ReviewCount

	if err := s.venues.Update(in); err != nil {
		return nil, err
	}
	updated, err := s.venues.GetByID(id)
	if err != nil || updated == nil {
		return updated, err
	}
	s.bus.Publish(messaging.KeyVenueUpdated, messaging.Envelope{
		Resource: "venue",
		EventID:  updated.ID,
		Data:     updated,
	})
	return updated, nil
}

func (s *Service) DeleteVenue(actorID, id string) error {
	existing, err := s.venues.GetByID(id)
	if err != nil {
		return err
	}
	if existing == nil {
		return ErrNotFound
	}
	if existing.CreatorID != actorID {
		return ErrUnauthorized
	}
	if err := s.venues.Delete(id); err != nil {
		return err
	}
	s.bus.Publish(messaging.KeyVenueDeleted, messaging.Envelope{
		Resource: "venue",
		EventID:  id,
		Data: map[string]interface{}{
			"creator_id": existing.CreatorID,
			"name":       existing.Name,
		},
	})
	return nil
}

// ---- Tickets ----

func (s *Service) CreateTicket(actorID string, eventID string, in *models.Ticket) (*models.Ticket, error) {
	event, err := s.db.GetByID(eventID)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, ErrNotFound
	}
	if event.CreatorID != actorID {
		return nil, ErrUnauthorized
	}
	if in.Name == "" || in.Type == "" || in.Price < 0 || in.Quantity <= 0 {
		return nil, fmt.Errorf("%w: name, type, non-negative price and quantity > 0 are required", ErrInvalidInput)
	}

	in.EventID = eventID
	in.IsActive = true
	in.IsTransferable = true
	if in.MaxPerUser == 0 {
		in.MaxPerUser = 10
	}
	if in.MinPerUser == 0 {
		in.MinPerUser = 1
	}
	id, err := s.tickets.Create(in)
	if err != nil {
		return nil, err
	}
	created, err := s.tickets.GetByID(id)
	if err != nil || created == nil {
		return created, err
	}
	_ = s.tickets.SyncEventSoldAndRevenue(eventID)

	s.bus.Publish(messaging.KeyTicketTypeCreated, messaging.Envelope{
		Resource: "ticket",
		EventID:  eventID,
		Data:     created,
	})
	return created, nil
}

func (s *Service) UpdateTicket(actorID, id string, in *models.Ticket) (*models.Ticket, error) {
	existing, err := s.tickets.GetByID(id)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, ErrNotFound
	}
	event, err := s.db.GetByID(existing.EventID)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, ErrNotFound
	}
	if event.CreatorID != actorID {
		return nil, ErrUnauthorized
	}

	in.ID = id
	in.EventID = existing.EventID
	if err := s.tickets.Update(in); err != nil {
		return nil, err
	}
	updated, err := s.tickets.GetByID(id)
	if err != nil || updated == nil {
		return updated, err
	}
	_ = s.tickets.SyncEventSoldAndRevenue(existing.EventID)

	s.bus.Publish(messaging.KeyTicketTypeUpdated, messaging.Envelope{
		Resource: "ticket",
		EventID:  existing.EventID,
		Data:     updated,
	})
	return updated, nil
}

func (s *Service) DeleteTicket(actorID, id string) error {
	existing, err := s.tickets.GetByID(id)
	if err != nil {
		return err
	}
	if existing == nil {
		return ErrNotFound
	}
	event, err := s.db.GetByID(existing.EventID)
	if err != nil {
		return err
	}
	if event == nil {
		return ErrNotFound
	}
	if event.CreatorID != actorID {
		return ErrUnauthorized
	}
	if existing.Sold > 0 {
		return fmt.Errorf("%w: cannot delete a ticket type that has sales", ErrConflict)
	}
	if err := s.tickets.Delete(id); err != nil {
		return err
	}
	_ = s.tickets.SyncEventSoldAndRevenue(existing.EventID)
	return nil
}

func (s *Service) ListTickets(eventID string) ([]*models.Ticket, error) {
	return s.tickets.ListByEvent(eventID)
}

// PurchaseTicket performs the ticketing flow: validate -> reserve -> confirm
// sale -> sync event analytics -> publish an enriched ticket.purchased. The
// booking service owns admission codes now: it consumes this event and mints
// one ticket instance per seat.
func (s *Service) PurchaseTicket(eventID, ticketID, userID, userEmail string, quantity int) (*models.Ticket, error) {
	if quantity < 1 {
		return nil, fmt.Errorf("%w: quantity must be at least 1", ErrInvalidInput)
	}

	event, err := s.db.GetByID(eventID)
	if err != nil {
		return nil, err
	}
	if event == nil {
		return nil, ErrNotFound
	}
	if !event.IsPublished || event.Status != "active" {
		return nil, ErrNotPublished
	}

	ticket, err := s.tickets.GetByID(ticketID)
	if err != nil {
		return nil, err
	}
	if ticket == nil || ticket.EventID != eventID || !ticket.IsActive {
		return nil, ErrNotFound
	}
	if quantity > ticket.MaxPerUser {
		return nil, fmt.Errorf("%w: exceeds max per user (%d)", ErrInvalidInput, ticket.MaxPerUser)
	}
	if ticket.SalesStart != nil && event.StartTime.Before(*ticket.SalesStart) {
		return nil, fmt.Errorf("%w: ticket sales have not started", ErrInvalidInput)
	}

	// Reserve atomically (single-writer SQLite makes this safe).
	if err := s.tickets.Reserve(ticketID, quantity); err != nil {
		if errors.Is(err, repository.ErrSoldOut) {
			return nil, ErrSoldOut
		}
		return nil, err
	}

	if err := s.tickets.ConfirmPurchase(ticketID, quantity); err != nil {
		if errors.Is(err, repository.ErrSoldOut) {
			return nil, ErrSoldOut
		}
		return nil, err
	}
	if err := s.tickets.SyncEventSoldAndRevenue(eventID); err != nil {
		return nil, err
	}

	unit := ticket.Price + ticket.ServiceFee + ticket.ProcessingFee
	amount := unit * float64(quantity)
	orderID, err := s.newOrderID()
	if err != nil {
		return nil, err
	}
	s.bus.Publish(messaging.KeyTicketPurchased, messaging.Envelope{
		Resource: "ticket",
		EventID:  eventID,
		Data: messaging.TicketPurchased{
			OrderID:       orderID,
			EventID:       eventID,
			EventSlug:     event.Slug,
			EventTitle:    event.Title,
			TicketID:      ticketID,
			TicketType:    ticket.Type,
			TicketName:    ticket.Name,
			Quantity:      quantity,
			UserID:        userID,
			UserEmail:     userEmail,
			UnitPrice:     ticket.Price,
			ServiceFee:    ticket.ServiceFee,
			ProcessingFee: ticket.ProcessingFee,
			Amount:        amount,
			Currency:      "KES",
			CreatorID:     event.CreatorID,
		},
	})

	updated, err := s.tickets.GetByID(ticketID)
	if err != nil || updated == nil {
		return ticket, err
	}
	return updated, nil
}

// newOrderID allocates a unique purchase order id shared with the booking
// service so a booking can reference the checkout that produced it.
func (s *Service) newOrderID() (string, error) {
	b := make([]byte, 7)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return "DONJO-ORD-" + strings.ToUpper(hex.EncodeToString(b)), nil
}

// Slugify builds a URL-safe slug from an event/venue title.
func Slugify(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	var b strings.Builder
	lastDash := false
	for _, r := range s {
		switch {
		case (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9'):
			b.WriteRune(r)
			lastDash = false
		default:
			if b.Len() > 0 && !lastDash {
				b.WriteByte('-')
				lastDash = true
			}
		}
	}
	slug := strings.Trim(b.String(), "-")
	if slug == "" {
		slug = fmt.Sprintf("event-%d", time.Now().UnixNano()/int64(time.Millisecond))
	}
	if len(slug) > 100 {
		slug = slug[:100]
	}
	return slug
}
