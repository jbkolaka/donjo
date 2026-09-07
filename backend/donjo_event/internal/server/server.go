package server

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"donjo_event/internal/auth"
	"donjo_event/internal/database"
	"donjo_event/internal/eventservice"
	"donjo_event/internal/messaging"
	"donjo_event/internal/repository"
)

type Server struct {
	port int
	http *http.Server

	db      database.Service
	bus     *messaging.Client
	authMw  *auth.Middleware
	eventH  *eventservice.Handler
	ticketR *repository.TicketRepository
	ctx     context.Context
	cancel  context.CancelFunc
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8081
	}

	srv := &Server{
		port: port,
		db:   database.New(),
	}

	migrationsDir, err := filepath.Abs("migrations")
	if err != nil {
		panic(err)
	}
	if err := srv.db.Migrate(migrationsDir); err != nil {
		panic(fmt.Sprintf("failed to run migrations: %s", err))
	}

	eventRepo := repository.NewEventRepository(srv.db.DB())
	venueRepo := repository.NewVenueRepository(srv.db.DB())
	srv.ticketR = repository.NewTicketRepository(srv.db.DB())

	// RabbitMQ: non-blocking background connect with auto-reconnect. The API
	// serves immediately; messaging comes online once RabbitMQ is reachable.
	srv.bus = messaging.NewClient()
	srv.ctx, srv.cancel = context.WithCancel(context.Background())
	srv.bus.StartConsumers(
		srv.ctx,
		func(ticketID string, qty int) error {
			return srv.ticketR.ReleaseReserved(ticketID, qty)
		},
	)
	srv.bus.Start()

	svc := eventservice.NewService(eventRepo, venueRepo, srv.ticketR, srv.bus)
	srv.authMw = auth.NewMiddleware()
	srv.eventH = eventservice.NewHandler(svc)

	srv.http = &http.Server{
		Addr:         fmt.Sprintf(":%d", srv.port),
		Handler:      srv.RegisterRoutes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	return srv
}

// ListenAndServe runs the HTTP server. It returns http.ErrServerClosed on a
// graceful shutdown.
func (s *Server) ListenAndServe() error {
	return s.http.ListenAndServe()
}

// ListenAndServeTLS runs the HTTP server over TLS with the given cert/key
// files.
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
		return s.db.Close()
	}
	return nil
}

func (s *Server) Shutdown(ctx context.Context) error {
	if s.http != nil {
		return s.http.Shutdown(ctx)
	}
	return nil
}
