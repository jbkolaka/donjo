package server

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"donjo_api_gateway/internal/gateway"
)

func newTestRouter() http.Handler {
	cfg := gateway.LoadConfig()
	// Point everything at an unreachable port so proxy/health calls fail fast
	// without hanging.
	for _, up := range cfg.Upstreams {
		up.URL.Scheme = "http"
		up.URL.Host = "127.0.0.1:1"
	}
	svc := &Server{
		config:  cfg,
		gateway: gateway.NewGateway(cfg),
	}
	return svc.RegisterRoutes()
}

func TestHelloWorldHandler(t *testing.T) {
	r := newTestRouter()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", w.Code)
	}
	var body map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if body["message"] != "Donjo API Gateway" {
		t.Errorf("message = %q, want %q", body["message"], "Donjo API Gateway")
	}
}

func TestHealthHandlerReportsUpstreams(t *testing.T) {
	r := newTestRouter()
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	// Every upstream is unreachable in this test, so the gateway reports
	// ServiceUnavailable (not ready to route) while still listing each
	// upstream under "services".
	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want 503 (body %s)", w.Code, w.Body.String())
	}
	var body struct {
		Status   string            `json:"status"`
		Services map[string]string `json:"services"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if body.Status != "degraded" {
		t.Errorf("status = %q, want degraded", body.Status)
	}
	for _, want := range []string{"auth", "event", "booking", "payment", "search", "ml", "notifications"} {
		if got, ok := body.Services[want]; !ok {
			t.Errorf("services missing %q: %v", want, body.Services)
		} else if got != "down" {
			t.Errorf("services[%q] = %q, want down", want, got)
		}
	}
}

func TestUnknownRouteGets404(t *testing.T) {
	r := newTestRouter()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/nope/nowhere", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404 (body %s)", w.Code, w.Body.String())
	}
}