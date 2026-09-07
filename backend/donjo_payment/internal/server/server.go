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

	"donjo_payment/internal/auth"
	"donjo_payment/internal/database"
	"donjo_payment/internal/messaging"
	"donjo_payment/internal/paymentservice"
	"donjo_payment/internal/repository"
)

type Server struct {
	port int
	http *http.Server

	db     database.Service
	bus    *messaging.Client
	authMw *auth.Middleware
	handle *paymentservice.Handler
	ctx    context.Context
	cancel context.CancelFunc
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8083
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

	txnRepo := repository.NewTransactionRepository(srv.db.DB())
	walletRepo := repository.NewWalletRepository(srv.db.DB())

	// RabbitMQ: non-blocking background connect with auto-reconnect. The API
	// serves immediately; payment intake comes online once RabbitMQ is up.
	srv.bus = messaging.NewClient()
	srv.ctx, srv.cancel = context.WithCancel(context.Background())

	svc := paymentservice.New(txnRepo, walletRepo, srv.bus)
	srv.bus.StartConsumers(srv.ctx, svc.HandlePurchase)
	srv.bus.Start()

	srv.authMw = auth.NewMiddleware()
	srv.handle = paymentservice.NewHandler(svc)

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
