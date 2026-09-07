package database

import (
	"context"
	"database/sql"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	_ "github.com/joho/godotenv/autoload"
	_ "github.com/mattn/go-sqlite3"
)

type Service interface {
	Health() map[string]string

	DB() *sql.DB

	Migrate(migrationsDir string) error

	Close() error
}

type service struct {
	db *sql.DB
}

var (
	dbInstance *service
)

// dbURL resolves the SQLite file location lazily so tests can override it via
// the environment before the first New() call.
func dbURL() string {
	if raw := os.Getenv("BLUEPRINT_DB_URL"); raw != "" {
		return raw
	}
	return "./db/donjo_payment.db"
}

func New() Service {
	if dbInstance != nil {
		return dbInstance
	}

	if err := ensureDBDir(dbURL()); err != nil {
		log.Fatal(err)
	}

	db, err := sql.Open("sqlite3", dbURL())
	if err != nil {
		log.Fatal(err)
	}

	db.SetMaxOpenConns(1)

	dbInstance = &service{
		db: db,
	}
	return dbInstance
}

func (s *service) DB() *sql.DB {
	return s.db
}

func (s *service) Migrate(migrationsDir string) error {
	if _, err := s.db.Exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
		version TEXT PRIMARY KEY,
		applied_at TEXT DEFAULT CURRENT_TIMESTAMP
	)`); err != nil {
		return fmt.Errorf("create schema_migrations table: %w", err)
	}

	entries, err := fs.Glob(os.DirFS(migrationsDir), "*.up.sql")
	if err != nil {
		return fmt.Errorf("list migrations: %w", err)
	}
	sort.Strings(entries)

	for _, entry := range entries {
		version := strings.TrimSuffix(entry, ".up.sql")

		var exists int
		if err := s.db.QueryRow(`SELECT COUNT(1) FROM schema_migrations WHERE version = ?`, version).Scan(&exists); err != nil {
			return err
		}
		if exists > 0 {
			continue
		}

		path := filepath.Join(migrationsDir, entry)
		content, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("read migration %s: %w", entry, err)
		}

		tx, err := s.db.Begin()
		if err != nil {
			return err
		}

		if _, err := tx.Exec(string(content)); err != nil {
			tx.Rollback()
			return fmt.Errorf("apply migration %s: %w", entry, err)
		}

		if _, err := tx.Exec(`INSERT INTO schema_migrations (version) VALUES (?)`, version); err != nil {
			tx.Rollback()
			return err
		}

		if err := tx.Commit(); err != nil {
			return err
		}

		log.Printf("applied migration: %s", entry)
	}

	return nil
}

// ensureDBDir creates the directory for the SQLite file when the configured
// URL is a file path (e.g. ./db/donjo_payment.db).
func ensureDBDir(raw string) error {
	raw = strings.TrimPrefix(raw, "file:")
	if strings.Contains(raw, "?") {
		raw = raw[:strings.Index(raw, "?")]
	}
	dir := filepath.Dir(raw)
	if dir == "." || dir == "" || dir == string(filepath.Separator) {
		return nil
	}
	return os.MkdirAll(dir, 0o755)
}

func (s *service) Health() map[string]string {
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	stats := make(map[string]string)

	err := s.db.PingContext(ctx)
	if err != nil {
		stats["status"] = "down"
		stats["error"] = fmt.Sprintf("db down: %v", err)
		log.Printf("db down: %v", err)
		return stats
	}

	stats["status"] = "up"
	stats["message"] = "It's healthy"

	dbStats := s.db.Stats()
	stats["open_connections"] = strconv.Itoa(dbStats.OpenConnections)
	stats["in_use"] = strconv.Itoa(dbStats.InUse)
	stats["idle"] = strconv.Itoa(dbStats.Idle)
	stats["wait_count"] = strconv.FormatInt(dbStats.WaitCount, 10)
	stats["wait_duration"] = dbStats.WaitDuration.String()
	stats["max_idle_closed"] = strconv.FormatInt(dbStats.MaxIdleClosed, 10)
	stats["max_lifetime_closed"] = strconv.FormatInt(dbStats.MaxLifetimeClosed, 10)

	if dbStats.OpenConnections > 40 {
		stats["message"] = "The database is experiencing heavy load."
	}

	if dbStats.WaitCount > 1000 {
		stats["message"] = "The database has a high number of wait events, indicating potential bottlenecks."
	}

	if dbStats.MaxIdleClosed > int64(dbStats.OpenConnections)/2 {
		stats["message"] = "Many idle connections are being closed, consider revising the connection pool settings."
	}

	if dbStats.MaxLifetimeClosed > int64(dbStats.OpenConnections)/2 {
		stats["message"] = "Many connections are being closed due to max lifetime, consider increasing max lifetime or revising the connection usage pattern."
	}

	return stats
}

func (s *service) Close() error {
	log.Printf("Disconnected from database: %s", dbURL())
	return s.db.Close()
}
