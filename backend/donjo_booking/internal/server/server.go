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

	"donjo_booking/internal/auth"
	"donjo_booking/internal/bookingservice"
	"donjo_booking/internal/database"
	"donjo_booking/internal/messaging"
	"donjo_booking/internal/repository"
)

type Server struct {
	port int
	http *http.Server

	db     database.Service
	bus    *messaging.Client
	authMw *auth.Middleware
	handle *bookingservice.Handler
	ctx    context.Context
	cancel context.CancelFunc
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8082
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

	bookingRepo := repository.NewBookingRepository(srv.db.DB())
	instanceRepo := repository.NewInstanceRepository(srv.db.DB())
	checkinRepo := repository.NewCheckinRepository(srv.db.DB())
	waitlistRepo := repository.NewWaitlistRepository(srv.db.DB())

	// RabbitMQ: non-blocking background connect with auto-reconnect. The API
	// serves immediately; order intake comes online once RabbitMQ is reachable.
	srv.bus = messaging.NewClient()
	srv.ctx, srv.cancel = context.WithCancel(context.Background())

	svc := bookingservice.New(bookingRepo, instanceRepo, checkinRepo, waitlistRepo)
	srv.bus.StartConsumers(srv.ctx, svc.HandlePurchase, svc.ApplyPayment)
	srv.bus.Start()

	srv.authMw = auth.NewMiddleware()
	srv.handle = bookingservice.NewHandler(svc)

	srv.http = &http.Server{
		Addr:         fmt.Sprintf(":%d", srv.port),
		Handler:      srv.RegisterRoutes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	return srv
}

func (s *Server) ListenAndServe() error {
	return s.http.ListenAndServe()
}

// ListenAndServeTLS runs the HTTP server over TLS with the given cert/key files.
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