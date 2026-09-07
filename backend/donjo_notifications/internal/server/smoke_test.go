package server

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"
)

// TestEndToEndSmoke boots the full server stack against a throwaway SQLite
// database (migrations included) and exercises the public surface so the
// service is verified to work from wire to storage without a persistent
// RabbitMQ broker (the consumer simply retries offline).
func TestEndToEndSmoke(t *testing.T) {
	dbURL := filepath.Join(t.TempDir(), "smoke.db")
	t.Setenv("BLUEPRINT_DB_URL", dbURL)
	t.Setenv("PORT", "0")
	t.Setenv("RABBITMQ_URL", "amqp://localhost:1") // unreachable -> retries, never blocks requests

	s := NewServer()
	defer s.Close()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	s.RegisterRoutes().ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("health status = %d, want 200 (body %s)", w.Code, w.Body.String())
	}
	var health map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &health); err != nil {
		t.Fatalf("parse health: %v", err)
	}
	if health["status"] != "up" {
		t.Fatalf("health status field = %v, want up", health["status"])
	}

	req = httptest.NewRequest(http.MethodGet, "/api/v1/templates", nil)
	w = httptest.NewRecorder()
	s.RegisterRoutes().ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("templates status = %d, want 200 (body %s)", w.Code, w.Body.String())
	}
	var resp struct {
		Items []map[string]interface{} `json:"items"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("parse templates: %v", err)
	}
	if len(resp.Items) != 4 {
		t.Fatalf("templates = %d, want the 4 seeded rows", len(resp.Items))
	}
	names := map[string]bool{}
	for _, it := range resp.Items {
		names[it["name"].(string)] = true
	}
	for _, want := range []string{"purchase_confirmation", "sale_alert", "event_discovery", "welcome"} {
		if !names[want] {
			t.Errorf("seeded template %q missing from %v", want, names)
		}
	}
}