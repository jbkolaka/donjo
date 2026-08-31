package server

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	_ "github.com/joho/godotenv/autoload"

	"donjo_backend/internal/auth"
	"donjo_backend/internal/database"
	"donjo_backend/internal/mailer"
	"donjo_backend/internal/repository"
)

type Server struct {
	port int

	db         database.Service
	authH      *auth.Handler
	authMw     *auth.Middleware
	userRepo   *repository.UserRepository
	uploadsDir string
}

func NewServer() *http.Server {
	port, _ := strconv.Atoi(os.Getenv("PORT"))
	uploadsDir := os.Getenv("UPLOAD_DIR")
	if uploadsDir == "" {
		uploadsDir = "uploads"
	}
	NewServer := &Server{
		port:       port,
		uploadsDir: uploadsDir,

		db: database.New(),
	}

	migrationsDir, err := filepath.Abs("migrations")
	if err != nil {
		panic(err)
	}
	if err := NewServer.db.Migrate(migrationsDir); err != nil {
		panic(fmt.Sprintf("failed to run migrations: %s", err))
	}

	NewServer.userRepo = repository.NewUserRepository(NewServer.db.DB())
	twoFactorRepo := repository.NewTwoFactorRepository(NewServer.db.DB())
	refreshRepo := repository.NewRefreshTokenRepository(NewServer.db.DB())
	passResetRepo := repository.NewPasswordResetRepository(NewServer.db.DB())
	rateLimitRepo := repository.NewRateLimitRepository(NewServer.db.DB())
	tokens := auth.NewTokenManager()
	authSvc := auth.NewService(NewServer.userRepo, twoFactorRepo, refreshRepo, passResetRepo, rateLimitRepo, tokens, mailer.New())
	publicBase := os.Getenv("PUBLIC_BASE_URL")
	if publicBase == "" {
		if b := os.Getenv("APP_BASE_URL"); b != "" {
			publicBase = b
		} else {
			publicBase = fmt.Sprintf("http://localhost:%d", port)
		}
	}
	NewServer.authH = auth.NewHandler(authSvc, uploadsDir, publicBase)
	NewServer.authMw = auth.NewMiddleware(tokens)

	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", NewServer.port),
		Handler:      NewServer.RegisterRoutes(),
		IdleTimeout:  time.Minute,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	return server
}
