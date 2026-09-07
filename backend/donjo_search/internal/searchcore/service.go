package searchcore

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"donjo_search/internal/es"
)

// DocIn is the rabbit payload shape published by donjo_event. It is a
// superset of the fields the search index cares about.
type DocIn struct {
	ID               string     `json:"id"`
	CreatorID        string     `json:"creator_id"`
	Title            string     `json:"title"`
	Slug             string     `json:"slug"`
	Description      string     `json:"description,omitempty"`
	ShortDescription string     `json:"short_description,omitempty"`
	Category         string     `json:"category,omitempty"`
	SubCategory      string     `json:"sub_category,omitempty"`
	Tags             []string   `json:"tags,omitempty"`
	EventType        string     `json:"event_type"`
	IsVirtual        bool       `json:"is_virtual"`
	VirtualLink      string     `json:"virtual_link,omitempty"`
	VirtualPlatform  string     `json:"virtual_platform,omitempty"`
	VenueID          string     `json:"venue_id,omitempty"`
	VenueName        string     `json:"venue_name,omitempty"`
	Location         string     `json:"location,omitempty"`
	Address          string     `json:"address,omitempty"`
	City             string     `json:"city,omitempty"`
	County           string     `json:"county,omitempty"`
	Country          string     `json:"country,omitempty"`
	Coordinates      *latLon    `json:"coordinates,omitempty"`
	StartTime        *time.Time `json:"start_time,omitempty"`
	EndTime          *time.Time `json:"end_time,omitempty"`
	Timezone         string     `json:"timezone,omitempty"`
	TotalCapacity    int        `json:"total_capacity"`
	MinTicketPrice   float64    `json:"min_ticket_price"`
	MaxTicketPrice   float64    `json:"max_ticket_price"`
	IsFree           bool       `json:"is_free"`
	Status           string     `json:"status,omitempty"`
	IsPublished      bool       `json:"is_published"`
	IsPrivate        bool       `json:"is_private"`
	InviteOnly       bool       `json:"invite_only"`
	OrganizerName    string     `json:"organizer_name,omitempty"`
	Views            int        `json:"views"`
	Likes            int        `json:"likes"`
	TicketsSold      int        `json:"tickets_sold"`
	Revenue          float64    `json:"revenue"`
	Tickets          []ticketIn `json:"tickets,omitempty"`
	CreatedAt        *time.Time `json:"created_at,omitempty"`
	UpdatedAt        *time.Time `json:"updated_at,omitempty"`
}

type latLon struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type ticketIn struct {
	ID            string     `json:"id"`
	Name          string     `json:"name"`
	Type          string     `json:"type,omitempty"`
	Tier          string     `json:"tier,omitempty"`
	Price         float64    `json:"price"`
	ServiceFee    float64    `json:"service_fee"`
	ProcessingFee float64    `json:"processing_fee"`
	Quantity      int        `json:"quantity"`
	Sold          int        `json:"sold"`
	Reserved      int        `json:"reserved"`
	IsActive      bool       `json:"is_active"`
	IsHidden      bool       `json:"is_hidden"`
	SalesStart    *time.Time `json:"sales_start,omitempty"`
	SalesEnd      *time.Time `json:"sales_end,omitempty"`
}

func (t *ticketIn) availability() int {
	return t.Quantity - t.Sold - t.Reserved
}

// SearchService owns the Elasticsearch read models. It is a pure consumer of
// donjo_event's events: messages arrive on its own queue and it upserts
// documents into the three indices. The HTTP layer reads the same store.
type SearchService struct {
	es  *es.Client
	ctx context.Context

	// decorate, when set, can post-process an event doc before indexing
	// (used to inject venue contextual fields).
	decorate func(*DocIn)
}

func New(esClient *es.Client) *SearchService {
	return &SearchService{es: esClient, ctx: context.Background()}
}

// SetContext binds all writes to a cancellable context for shutdown.
func (s *SearchService) SetContext(ctx context.Context) *SearchService {
	s.ctx = ctx
	return s
}

// WithDecorator registers a doc decorator hook.
func (s *SearchService) WithDecorator(fn func(*DocIn)) *SearchService {
	s.decorate = fn
	return s
}

// UpsertEvent indexes (or replaces) an event document from donor payload.
func (s *SearchService) UpsertEvent(in interface{}) error {
	var doc DocIn
	if err := decode(in, &doc); err != nil {
		return err
	}
	if doc.ID == "" {
		return fmt.Errorf("event doc missing id")
	}
	if s.decorate != nil {
		s.decorate(&doc)
	}
	s.logf("index event %s (%s)", doc.ID, doc.Title)
	return s.es.Update(s.ctx, IndexEvents, doc.ID, doc.eventPartial())
}

// UpsertTicket indexes (or replaces) a ticket document. donjo_event publishes
// ticket.type.created/updated with a bare Ticket payload (its own id + the
// parent event_id), while the event.create/update messages carry an event doc
// with a nested tickets array. Both shapes are handled here.
func (s *SearchService) UpsertTicket(in interface{}) error {
	data, err := json.Marshal(in)
	if err != nil {
		return err
	}
	// Try the bare-ticket shape first.
	var bare struct {
		ID              string     `json:"id"`
		Name            string     `json:"name"`
		Description     string     `json:"description,omitempty"`
		Type            string     `json:"type,omitempty"`
		Tier            string     `json:"tier,omitempty"`
		Price           float64    `json:"price"`
		OriginalPrice   float64    `json:"original_price,omitempty"`
		ServiceFee      float64    `json:"service_fee"`
		ProcessingFee   float64    `json:"processing_fee"`
		Quantity        int        `json:"quantity"`
		Sold            int        `json:"sold"`
		Reserved        int        `json:"reserved"`
		IsActive        bool       `json:"is_active"`
		IsHidden        bool       `json:"is_hidden"`
		IsTransferable  bool       `json:"is_transferable"`
		IsRefundable    bool       `json:"is_refundable"`
		RequiresIDCheck bool       `json:"requires_id_check"`
		EventID         string     `json:"event_id"`
		SalesStart      *time.Time `json:"sales_start,omitempty"`
		SalesEnd        *time.Time `json:"sales_end,omitempty"`
		CreatedAt       *time.Time `json:"created_at,omitempty"`
		UpdatedAt       *time.Time `json:"updated_at,omitempty"`
	}
	if err := json.Unmarshal(data, &bare); err == nil && bare.ID != "" && bare.EventID != "" {
		// We also want the event's title/city for cross-cut facets, but the
		// bare ticket message does not carry them; the event doc in the
		// events index does. Lift what we can from a stored event doc.
		evCtx := s.loadEventContext(bare.EventID)
		t := &TicketDoc{
			Type:             "ticket",
			ID:               bare.ID,
			Name:             bare.Name,
			Description:      bare.Description,
			TypeName:         bare.Type,
			Tier:             bare.Tier,
			Price:            bare.Price,
			OriginalPrice:    bare.OriginalPrice,
			ServiceFee:       bare.ServiceFee,
			ProcessingFee:    bare.ProcessingFee,
			Quantity:         bare.Quantity,
			Sold:             bare.Sold,
			Reserved:         bare.Reserved,
			Availability:     bare.Quantity - bare.Sold - bare.Reserved,
			IsActive:         bare.IsActive,
			IsHidden:         bare.IsHidden,
			IsTransferable:   bare.IsTransferable,
			IsRefundable:     bare.IsRefundable,
			RequiresIDCheck:  bare.RequiresIDCheck,
			EventID:          bare.EventID,
			EventTitle:       evCtx.title,
			EventSlug:        evCtx.slug,
			EventCategory:    evCtx.category,
			EventCity:        evCtx.city,
			EventStartTime:   evCtx.start,
			EventIsPublished: evCtx.published,
			CreatedAt:        ts(bare.CreatedAt),
			UpdatedAt:        ts(bare.UpdatedAt),
		}
		s.logf("index ticket %s (%s)", t.ID, t.Name)
		if err := s.es.Update(s.ctx, IndexTickets, t.ID, ticketPartial(t)); err != nil {
			return err
		}
		return s.syncTicketIntoEvent(bare.EventID, ticketIn{
			ID:            bare.ID,
			Name:          bare.Name,
			Type:          bare.Type,
			Tier:          bare.Tier,
			Price:         bare.Price,
			ServiceFee:    bare.ServiceFee,
			ProcessingFee: bare.ProcessingFee,
			Quantity:      bare.Quantity,
			Sold:          bare.Sold,
			Reserved:      bare.Reserved,
			IsActive:      bare.IsActive,
			IsHidden:      bare.IsHidden,
			SalesStart:    bare.SalesStart,
			SalesEnd:      bare.SalesEnd,
		})
	}

	// Fall back to the event-doc-with-nested-tickets shape.
	var doc DocIn
	if err := decode(in, &doc); err != nil {
		return err
	}
	if len(doc.Tickets) == 0 {
		s.logf("ticket message with no ticket payload ignored")
		return nil
	}
	tk := doc.Tickets[0]
	t := &TicketDoc{
		Type:             "ticket",
		ID:               tk.ID,
		Name:             tk.Name,
		TypeName:         tk.Type,
		Tier:             tk.Tier,
		Price:            tk.Price,
		ServiceFee:       tk.ServiceFee,
		ProcessingFee:    tk.ProcessingFee,
		Quantity:         tk.Quantity,
		Sold:             tk.Sold,
		Reserved:         tk.Reserved,
		Availability:     tk.availability(),
		IsActive:         tk.IsActive,
		IsHidden:         tk.IsHidden,
		EventID:          doc.ID,
		EventTitle:       doc.Title,
		EventSlug:        doc.Slug,
		EventCategory:    doc.Category,
		EventCity:        doc.City,
		EventStartTime:   ts(doc.StartTime),
		EventIsPublished: doc.IsPublished,
		CreatedAt:        ts(doc.CreatedAt),
		UpdatedAt:        ts(doc.UpdatedAt),
	}
	s.logf("index ticket %s (%s)", t.ID, t.Name)
	if err := s.es.Update(s.ctx, IndexTickets, t.ID, ticketPartial(t)); err != nil {
		return err
	}
	return s.syncTicketIntoEvent(doc.ID, tk)
}

// eventContext is a lightweight lookup into the events index for the fields
// the standalone ticket doc wants from its parent event.
type eventContext struct {
	title, slug, category, city, start string
	published                          bool
}

// loadEventContext fetches a stored event doc and returns the contextual
// fields (empty on any failure; the ticket doc still stands alone).
func (s *SearchService) loadEventContext(eventID string) eventContext {
	res, err := s.es.Search(s.ctx, IndexEvents, map[string]interface{}{
		"size": 1,
		"query": map[string]interface{}{
			"ids": map[string]interface{}{"values": []string{eventID}},
		},
	})
	if err != nil || res.Total == 0 {
		return eventContext{}
	}
	var src map[string]interface{}
	if err := json.Unmarshal(res.Hits[0].Source, &src); err != nil {
		return eventContext{}
	}
	var ec eventContext
	if v, ok := src["title"].(string); ok {
		ec.title = v
	}
	if v, ok := src["slug"].(string); ok {
		ec.slug = v
	}
	if v, ok := src["category"].(string); ok {
		ec.category = v
	}
	if v, ok := src["city"].(string); ok {
		ec.city = v
	}
	if v, ok := src["start_time"].(string); ok {
		ec.start = v
	}
	ec.published, _ = src["is_published"].(bool)
	return ec
}

// syncTicketIntoEvent patches the nested array of an event document with a
// ticket (replace-or-push) and recomputes available_tickets / min/max price.
func (s *SearchService) syncTicketIntoEvent(eventID string, tk ticketIn) error {
	nested := map[string]interface{}{
		"id":             tk.ID,
		"name":           tk.Name,
		"type":           tk.Type,
		"tier":           tk.Tier,
		"price":          tk.Price,
		"service_fee":    tk.ServiceFee,
		"processing_fee": tk.ProcessingFee,
		"quantity":       tk.Quantity,
		"sold":           tk.Sold,
		"reserved":       tk.Reserved,
		"availability":   tk.availability(),
		"is_active":      tk.IsActive,
		"is_hidden":      tk.IsHidden,
	}
	if v := ts(tk.SalesStart); v != "" {
		nested["sales_start"] = v
	}
	if v := ts(tk.SalesEnd); v != "" {
		nested["sales_end"] = v
	}
	script := `
		def ts=ctx._source.tickets;
		if(ts===null){ts=[];ctx._source.tickets=ts;}
		def replaced=false;
		def i=0;
		for(;i<ts.length;i++){if(ts[i].id==params.ticket.id){ts[i]=params.ticket;replaced=true;break;}}
		if(!replaced){ts.add(params.ticket);}
		def a=0,min=Double.MAX_VALUE,max=0,have=false;
		def j=0;
		for(;j<ts.length;j++){def x=ts[j];if(x.is_active&&!x.is_hidden){a+=x.availability;if(x.price<min)min=x.price;if(x.price>max)max=x.price;have=true;}}
		ctx._source.available_tickets=a;
		if(have){ctx._source.min_ticket_price=min;ctx._source.max_ticket_price=max;}
		else{ctx._source.min_ticket_price=0;ctx._source.max_ticket_price=0;}
	`
	return s.es.ScriptUpdate(s.ctx, IndexEvents, eventID, script, map[string]interface{}{"ticket": nested})
}

// UpsertVenue indexes (or replaces) a venue document from donor payload.
func (s *SearchService) UpsertVenue(in interface{}) error {
	var doc VenueDoc
	if err := decode(in, &doc); err != nil {
		return err
	}
	if doc.ID == "" {
		return fmt.Errorf("venue doc missing id")
	}
	doc.Type = "venue"
	s.logf("index venue %s (%s)", doc.ID, doc.Name)
	return s.es.Update(s.ctx, IndexVenues, doc.ID, venuePartial(doc))
}

// DeleteDoc removes a document by id.
func (s *SearchService) DeleteDoc(index, id string) error {
	s.logf("delete %s %s", index, id)
	return s.es.Delete(s.ctx, index, id)
}

// ScriptUpdate exposes the ES client's painless script update for the few
// places that flip flags on an existing doc (e.g. event.published).
func (s *SearchService) ScriptUpdate(index, id, source string, params map[string]interface{}) error {
	return s.es.ScriptUpdate(s.ctx, index, id, source, params)
}

// MarkEventPublished propagates a publish to every ticket doc of one event
// (their event context is snapshotted at ticket-create time, which may have
// happened before the event went live).
func (s *SearchService) MarkEventPublished(eventID string) error {
	return s.es.UpdateByQuery(s.ctx, IndexTickets, map[string]interface{}{
		"query": map[string]interface{}{
			"term": map[string]interface{}{"event_id": eventID},
		},
		"script": map[string]interface{}{
			"source": "ctx._source.event_is_published=true;",
		},
	})
}

// ApplyPurchase refreshes an event's ticket availability and the standalone
// ticket document after a completed purchase.
func (s *SearchService) ApplyPurchase(p TicketPurchaseIn) error {
	if p.EventID == "" || p.TicketID == "" {
		return nil
	}
	s.logf("purchase order %s → event %s ticket %s qty %d", p.OrderID, p.EventID, p.TicketID, p.Quantity)

	// Decrement availability inside the nested ticket array and bump the
	// event-level sold/revenue counters. If the nested target is missing the
	// update is a no-op; the full event.create that follows in the pipeline
	// will reconcile the real numbers.
	script := "def tickets=ctx._source.tickets;if(tickets!=null){def avl=ctx._source.available_tickets;if(avl==null){avl=ctx._source.total_capacity;}for(def i=0;i<tickets.length;i++){if(tickets[i].id==params.id){def av=tickets[i].availability;tickets[i].sold=(tickets[i].sold==null?0:tickets[i].sold)+params.q;tickets[i].availability=(av==null?tickets[i].quantity:av)-params.q;ctx._source.tickets_sold=(ctx._source.tickets_sold==null?0:ctx._source.tickets_sold)+params.q;ctx._source.revenue=(ctx._source.revenue==null?0:ctx._source.revenue)+params.rev;ctx._source.available_tickets=avl-params.q;break;}}}"
	if err := s.es.ScriptUpdate(s.ctx, IndexEvents, p.EventID, script, map[string]interface{}{
		"id": p.TicketID, "q": p.Quantity, "rev": float64(p.Quantity) * p.UnitPrice,
	}); err != nil {
		return err
	}

	// Mirror onto the standalone ticket document.
	if err := s.es.ScriptUpdate(s.ctx, IndexTickets, p.TicketID,
		"def s=ctx._source.sold;def av=ctx._source.availability;ctx._source.sold=(s==null?0:s)+params.q;ctx._source.availability=(av==null?ctx._source.quantity:av)-params.q;",
		map[string]interface{}{"q": p.Quantity}); err != nil {
		return err
	}
	return nil
}

// ApplySaleReleased returns released stock to the available pool.
func (s *SearchService) ApplySaleReleased(r TicketReleasedIn) error {
	if r.TicketID == "" || r.EventID == "" {
		return nil
	}
	s.logf("sale released ticket %s qty %d", r.TicketID, r.Quantity)
	script := "def tickets=ctx._source.tickets;if(tickets!=null){for(def i=0;i<tickets.length;i++){if(tickets[i].id==params.id){def r=tickets[i].reserved;def av=tickets[i].availability;tickets[i].reserved=(r==null?0:r)-params.q;tickets[i].availability=(av==null?tickets[i].quantity:av)+params.q;break;}}}"
	if err := s.es.ScriptUpdate(s.ctx, IndexEvents, r.EventID, script, map[string]interface{}{"id": r.TicketID, "q": r.Quantity}); err != nil {
		return err
	}
	return s.es.ScriptUpdate(s.ctx, IndexTickets, r.TicketID,
		"def av=ctx._source.availability;ctx._source.reserved=(ctx._source.reserved==null?0:ctx._source.reserved)-params.q;ctx._source.availability=(av==null?ctx._source.quantity:av)+params.q;",
		map[string]interface{}{"q": r.Quantity})
}

func decode(in interface{}, out interface{}) error {
	data, err := json.Marshal(in)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, out)
}

func ts(t *time.Time) string {
	if t == nil {
		return ""
	}
	return t.UTC().Format(time.RFC3339)
}

func (s *SearchService) logf(f string, args ...interface{}) {
	log.Printf("[search] "+f, args...)
}
