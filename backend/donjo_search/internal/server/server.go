package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"donjo_search/internal/es"
	"donjo_search/internal/messaging"
	"donjo_search/internal/ratelimit"
	"donjo_search/internal/searchcore"
)

type Server struct {
	port    int
	http    *http.Server
	bus     *messaging.Client
	svc     *searchcore.SearchService
	handler *searchcore.Handler
	ctx     context.Context
	cancel  context.CancelFunc
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8084
	}

	srv := &Server{
		port: port,
		ctx:  context.Background(),
	}
	srv.ctx, srv.cancel = context.WithCancel(srv.ctx)

	esURL := os.Getenv("ELASTICSEARCH_URL")
	if esURL == "" {
		esURL = "http://localhost:9200"
	}
	esClient := es.New(esURL, os.Getenv("ELASTICSEARCH_USERNAME"), os.Getenv("ELASTICSEARCH_PASSWORD"))

	// Declare and create the search indices on startup. When ES is down
	// the ping fails but the HTTP server still boots (graceful degrade);
	// indices are created once ES comes online before the first message is
	// consumed.
	if _, err := esClient.Ping(srv.ctx); err != nil {
		log.Printf("[search] ES ping failed at startup (%v) — indices will be created when ES is reachable", err)
	} else {
		srv.ensureIndices(esClient)
	}

	// RabbitMQ: background consumer on its own queue. Starts offline and
	// retries automatically.
	srv.bus = messaging.NewClient()

	srv.svc = searchcore.New(esClient).
		SetContext(srv.ctx)
	srv.handler = searchcore.NewHandler(srv.svc)

	srv.bus.StartConsumers(srv.ctx, srv.consume)
	srv.bus.Start()

	srv.http = &http.Server{
		Addr:         fmt.Sprintf(":%d", srv.port),
		Handler:      srv.RegisterRoutes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	return srv
}

func (s *Server) ensureIndices(esClient *es.Client) {
	esClient.Manage(searchcore.IndexEvents, es.EventsMapping())
	esClient.Manage(searchcore.IndexTickets, es.TicketsMapping())
	esClient.Manage(searchcore.IndexVenues, es.VenuesMapping())
	if err := esClient.EnsureIndices(s.ctx); err != nil {
		log.Printf("[search] ensure indices: %v", err)
	}
}

// consume is the single handler registered on the queue. It inspects the
// routing key and dispatches to the matching indexer.
func (s *Server) consume(env messaging.Envelope) error {
	switch env.Key {
	case messaging.KeyEventCreated, messaging.KeyEventUpdated:
		return s.svc.UpsertEvent(env.Data)
	case messaging.KeyEventPublished:
		// The published payload only carries event_id/slug/title; flip the
		// searchable is_published flag on the event doc and its ticket docs.
		if env.EventID == "" {
			return nil
		}
		if err := s.svc.ScriptUpdate(searchcore.IndexEvents, env.EventID,
			"ctx._source.is_published=true;ctx._source.status='published';", nil); err != nil {
			return err
		}
		return s.svc.MarkEventPublished(env.EventID)
	case messaging.KeyEventDeleted:
		if env.EventID == "" {
			return nil
		}
		return s.svc.DeleteDoc(searchcore.IndexEvents, env.EventID)
	case messaging.KeyTicketTypeCreated, messaging.KeyTicketTypeUpdated:
		return s.svc.UpsertTicket(env.Data)
	case messaging.KeyTicketPurchased:
		p, err := messaging.TicketPurchasedFrom(env)
		if err != nil {
			return err
		}
		if p == nil {
			return nil
		}
		return s.svc.ApplyPurchase(searchcore.TicketPurchaseIn{
			OrderID:   p.OrderID,
			EventID:   p.EventID,
			TicketID:  p.TicketID,
			Quantity:  p.Quantity,
			UnitPrice: p.UnitPrice,
			UserID:    p.UserID,
			CreatorID: p.CreatorID,
		})
	case messaging.KeyTicketSaleReleased:
		r, err := messaging.TicketSaleReleasedFrom(env)
		if err != nil {
			return err
		}
		if r == nil {
			return nil
		}
		return s.svc.ApplySaleReleased(searchcore.TicketReleasedIn{
			TicketID: r.TicketID,
			EventID:  r.EventID,
			Quantity: r.Quantity,
		})
	case messaging.KeyVenueCreated, messaging.KeyVenueUpdated:
		return s.svc.UpsertVenue(env.Data)
	case messaging.KeyVenueDeleted:
		if env.EventID == "" {
			return nil
		}
		return s.svc.DeleteDoc(searchcore.IndexVenues, env.EventID)
	default:
		return nil
	}
}

func (s *Server) ListenAndServe() error {
	return s.http.ListenAndServe()
}

// ListenAndServeTLS runs the HTTP server over TLS with the given cert/key.
func (s *Server) ListenAndServeTLS(certFile, keyFile string) error {
	return s.http.ListenAndServeTLS(certFile, keyFile)
}

func (s *Server) Close() error {
	if s.cancel != nil {
		s.cancel()
	}
	if s.bus != nil {
		_ = s.bus.Close()
	}
	return nil
}

func (s *Server) Shutdown(ctx context.Context) error {
	if s.http != nil {
		return s.http.Shutdown(ctx)
	}
	return nil
}

// TLSFiles returns the cert/key pair configured via TLS_CERT_FILE /
// TLS_KEY_FILE, or two empty strings when plain HTTP is intended.
func (s *Server) TLSFiles() (cert, key string) {
	return os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE")
}

// rateLimiter is a simple per-IP fixed-window budget.
var rateLimiter = ratelimit.New(rateLimitRequests(), time.Minute)

func rateLimitRequests() int {
	if raw := os.Getenv("RATE_LIMIT_REQUESTS"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			return n
		}
	}
	return 300
}
