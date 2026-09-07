package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"donjo_ml/internal/auth"
	"donjo_ml/internal/database"
	"donjo_ml/internal/messaging"
	"donjo_ml/internal/mlcore"
	"donjo_ml/internal/ratelimit"
)

type Server struct {
	port    int
	http    *http.Server
	db      database.Service
	bus     *messaging.Client
	core    *mlcore.MLService
	handler *mlcore.Handler
	ctx     context.Context
	cancel  context.CancelFunc
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8085
	}

	srv := &Server{
		port: port,
		ctx:  context.Background(),
	}
	srv.ctx, srv.cancel = context.WithCancel(srv.ctx)

	db := database.New()
	migrationsDir, err := filepath.Abs("migrations")
	if err != nil {
		log.Fatalf("[ml] resolve migrations dir: %v", err)
	}
	if err := db.Migrate(migrationsDir); err != nil {
		log.Fatalf("[ml] migrations: %v", err)
	}
	srv.db = db

	// RabbitMQ: background consumer on the ML queue. Starts offline and
	// retries automatically.
	srv.bus = messaging.NewClient()

	srv.core = mlcore.New(db.DB())
	srv.handler = mlcore.NewHandler(srv.core, auth.NewMiddleware())

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

// consume is the single handler registered on the ML queue. It inspects the
// routing key and dispatches to the model service (ingest = retrain).
func (s *Server) consume(env messaging.Envelope) error {
	switch env.Key {
	case messaging.KeyEventCreated, messaging.KeyEventUpdated:
		return s.core.UpsertEvent(env.Data)
	case messaging.KeyEventPublished:
		if env.EventID == "" {
			return nil
		}
		return s.core.MarkEventPublished(env.EventID)
	case messaging.KeyEventDeleted:
		if env.EventID == "" {
			return nil
		}
		return s.core.DeleteEvent(env.EventID)
	case messaging.KeyTicketTypeCreated, messaging.KeyTicketTypeUpdated:
		return s.core.UpsertTicket(env.Data)
	case messaging.KeyTicketPurchased:
		// The full purchase payload is all the model needs to strengthen the
		// buyer's profile and bump the event's popularity.
		return s.core.OnPurchase(env.Data)
	case messaging.KeyTicketSaleReleased:
		// Releases do not change embeddings; ack and move on.
		return nil
	case messaging.KeyVenueCreated, messaging.KeyVenueUpdated:
		return s.core.UpsertVenue(env.Data)
	case messaging.KeyVenueDeleted:
		return nil
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
	if s.db != nil {
		_ = s.db.Close()
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
