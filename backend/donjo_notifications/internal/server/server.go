package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"donjo_notifications/internal/auth"
	"donjo_notifications/internal/database"
	"donjo_notifications/internal/messaging"
	"donjo_notifications/internal/notificationservice"
	"donjo_notifications/internal/ratelimit"
)

type Server struct {
	port    int
	http    *http.Server
	db      database.Service
	bus     *messaging.Client
	notif   *notificationservice.Service
	handler *notificationservice.Handler
	ctx     context.Context
	cancel  context.CancelFunc
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8086
	}

	srv := &Server{
		port: port,
		ctx:  context.Background(),
	}
	srv.ctx, srv.cancel = context.WithCancel(srv.ctx)

	db := database.New()
	migrationsDir, err := findMigrationsDir()
	if err != nil {
		log.Fatalf("[notify] migrations dir: %v", err)
	}
	if err := db.Migrate(migrationsDir); err != nil {
		log.Fatalf("[notify] migrations: %v", err)
	}
	srv.db = db

	// RabbitMQ: background consumer on the notifications queue. Starts offline
	// and retries automatically.
	srv.bus = messaging.NewClient()

	srv.notif = notificationservice.New(db.DB())
	srv.handler = notificationservice.NewHandler(srv.notif, auth.NewMiddleware())

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

// consume is the single handler registered on the notifications queue. It
// inspects the routing key and dispatches to the notification service (ingest
// = notify + feed).
func (s *Server) consume(env messaging.Envelope) error {
	switch env.Key {
	case messaging.KeyTicketPurchased:
		return s.notif.OnTicketPurchased(env.Data)
	case messaging.KeyEventPublished:
		return s.notif.OnEventPublished(env.Data)
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

// findMigrationsDir locates the SQL migrations directory by walking up from
// the working directory until a dir containing *.up.sql files is found. This
// makes the server runnable from anywhere (make run, tests, docker) instead
// of only from the service root. MIGRATIONS_DIR overrides the search.
func findMigrationsDir() (string, error) {
	if raw := os.Getenv("MIGRATIONS_DIR"); raw != "" {
		return raw, nil
	}
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}
	for {
		candidate := filepath.Join(dir, "migrations")
		entries, err := os.ReadDir(candidate)
		if err == nil {
			for _, e := range entries {
				if !e.IsDir() && strings.HasSuffix(e.Name(), ".up.sql") {
					return candidate, nil
				}
			}
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "", fmt.Errorf("no migrations directory found walking up from working directory")
}
var rateLimiter = ratelimit.New(rateLimitRequests(), time.Minute)

func rateLimitRequests() int {
	if raw := os.Getenv("RATE_LIMIT_REQUESTS"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			return n
		}
	}
	return 300
}