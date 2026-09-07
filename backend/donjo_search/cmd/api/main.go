package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"donjo_search/internal/server"
)

func gracefulShutdown(apiServer *server.Server, done chan bool) {
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
	apiServer.Close()

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

func serve(server *server.Server) error {
	cert, key := server.TLSFiles()
	if cert != "" && key != "" {
		log.Printf("listening with TLS (cert=%s)", cert)
		return server.ListenAndServeTLS(cert, key)
	}
	log.Printf("listening without TLS (set TLS_CERT_FILE and TLS_KEY_FILE to enable HTTPS)")
	return server.ListenAndServe()
}
