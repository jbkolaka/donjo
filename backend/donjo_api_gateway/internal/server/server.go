package server

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"donjo_api_gateway/internal/gateway"
	"donjo_api_gateway/internal/ratelimit"
)

type Server struct {
	port    int
	http    *http.Server
	config  *gateway.Config
	gateway *gateway.Gateway
}

func NewServer() *Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	if port == 0 {
		port = 8087
	}

	cfg := gateway.LoadConfig()

	srv := &Server{
		port:    port,
		config:  cfg,
		gateway: gateway.NewGateway(cfg),
	}

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

// ListenAndServeTLS runs the HTTP server over TLS with the given cert/key.
func (s *Server) ListenAndServeTLS(certFile, keyFile string) error {
	return s.http.ListenAndServeTLS(certFile, keyFile)
}

func (s *Server) Close() error {
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

// rateLimiter is a per-socket-IP fixed-window safety net that sits in front
// of the whole /api/v1 surface; each upstream enforces its own stricter
// budgets on top of it.
var rateLimiter = ratelimit.New(rateLimitRequests(), time.Minute)

func rateLimitRequests() int {
	if raw := os.Getenv("RATE_LIMIT_REQUESTS"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			return n
		}
	}
	return 1000
}