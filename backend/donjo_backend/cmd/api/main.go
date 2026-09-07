package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"donjo_backend/internal/server"
)

func gracefulShutdown(apiServer *http.Server, done chan bool) {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	<-ctx.Done()

	log.Println("shutting down gracefully, press Ctrl+C again to force")
	stop()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := apiServer.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown with error: %v", err)
	}

	log.Println("Server exiting")

	done <- true
}

func main() {

	server := server.NewServer()

	done := make(chan bool, 1)

	go gracefulShutdown(server, done)

	err := serve(server)
	if err != nil && err != http.ErrServerClosed {
		panic(fmt.Sprintf("http server error: %s", err))
	}

	<-done
	log.Println("Graceful shutdown complete.")
}

// serve starts the HTTP server, terminating TLS when TLS_CERT_FILE and
// TLS_KEY_FILE are both set, otherwise plain HTTP for local development.
func serve(srv *http.Server) error {
	cert, key := os.Getenv("TLS_CERT_FILE"), os.Getenv("TLS_KEY_FILE")
	if cert != "" && key != "" {
		log.Printf("listening with TLS (cert=%s)", cert)
		return srv.ListenAndServeTLS(cert, key)
	}
	log.Printf("listening without TLS (set TLS_CERT_FILE and TLS_KEY_FILE to enable HTTPS)")
	return srv.ListenAndServe()
}
