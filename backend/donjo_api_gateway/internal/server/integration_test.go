package server

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"donjo_api_gateway/internal/gateway"
)

// upstreamStub is an httptest server that echoes what the proxy sent it so
// the test can assert forwarding behaviour.
func upstreamStub(t *testing.T, name string) *httptest.Server {
	t.Helper()
	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "http://evil.example") // must be stripped by the gateway
		w.Header().Set("Content-Type", "application/json")
		if r.URL.Path == "/health" {
			fmt.Fprint(w, `{"status":"up"}`)
			return
		}
		out := map[string]string{
			"service":    name,
			"path":       r.URL.Path,
			"method":     r.Method,
			"fwd_for":    r.Header.Get("X-Forwarded-For"),
			"auth":       r.Header.Get("Authorization"),
			"svc_token":  r.Header.Get("X-Service-Token"),
			"user_agent": r.Header.Get("User-Agent"),
			"fwd_proto":  r.Header.Get("X-Forwarded-Proto"),
		}
		_ = json.NewEncoder(w).Encode(out)
	}))
	t.Cleanup(s.Close)
	return s
}

// newTestServer builds a real Server routing to httptest upstreams. The proxy
// tests must hit the gateway's http.Server for real: reverse proxying into a
// gin handler over an httptest.ResponseRecorder panics (gin asserts the
// http.CloseNotifier interface the recorder lacks).
func newTestServer(t *testing.T) *Server {
	t.Helper()
	event := upstreamStub(t, "event")
	notif := upstreamStub(t, "notifications")
	ml := upstreamStub(t, "ml")

	cfg := gateway.LoadConfig()
	for _, up := range cfg.Upstreams {
		switch up.Name {
		case "event":
			u, _ := url.Parse(event.URL)
			up.URL = u
		case "notifications":
			u, _ := url.Parse(notif.URL)
			up.URL = u
		case "ml":
			u, _ := url.Parse(ml.URL)
			up.URL = u
		default:
			up.URL.Scheme = "http"
			up.URL.Host = "127.0.0.1:1" // unreachable -> 502
		}
	}
	s := &Server{config: cfg, gateway: gateway.NewGateway(cfg)}
	s.http = &http.Server{Addr: "127.0.0.1:0", Handler: s.RegisterRoutes()}
	return s
}

// runGateway starts the gateway on an ephemeral port and returns its base URL.
func runGateway(t *testing.T, s *Server) string {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	go func() {
		_ = s.http.Serve(ln)
	}()
	t.Cleanup(func() {
		_ = s.http.Close()
	})
	return "http://" + ln.Addr().String()
}

func getJSON(t *testing.T, url, method string, header map[string]string) (int, map[string]string, http.Header) {
	t.Helper()
	req, err := http.NewRequest(method, url, strings.NewReader("{}"))
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	for k, v := range header {
		req.Header.Set(k, v)
	}
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("request: %v", err)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	out := map[string]string{}
	if len(body) > 0 {
		_ = json.Unmarshal(body, &out)
	}
	return resp.StatusCode, out, resp.Header
}

func TestProxyRoutesAndForwards(t *testing.T) {
	s := newTestServer(t)
	base := runGateway(t, s)

	status, out, _ := getJSON(t, base+"/api/v1/events/abc123", http.MethodGet, map[string]string{
		"Authorization": "Bearer test-token",
		"User-Agent":    "donjo-app/1.0",
	})

	if status != http.StatusOK {
		t.Fatalf("status = %d, want 200 (body %v)", status, out)
	}
	if out["service"] != "event" || out["path"] != "/api/v1/events/abc123" {
		t.Errorf("routed to wrong upstream: %+v", out)
	}
	if out["fwd_for"] != "127.0.0.1" {
		t.Errorf("X-Forwarded-For = %q, want the single socket client IP 127.0.0.1", out["fwd_for"])
	}
	if out["auth"] != "Bearer test-token" {
		t.Errorf("Authorization not preserved: %q", out["auth"])
	}
	if out["user_agent"] != "donjo-app/1.0" {
		t.Errorf("User-Agent not preserved: %q", out["user_agent"])
	}
	if out["fwd_proto"] != "http" {
		t.Errorf("X-Forwarded-Proto = %q, want http", out["fwd_proto"])
	}
}

func TestProxyStripsUpstreamCORS(t *testing.T) {
	s := newTestServer(t)
	base := runGateway(t, s)

	// With a browser Origin present, the gateway (single CORS source) must
	// echo its own allow-list, never the upstream's noise header.
	status, _, headers := getJSON(t, base+"/api/v1/events/abc123", http.MethodGet, map[string]string{
		"Origin": "http://localhost:5173",
	})
	if status != http.StatusOK {
		t.Fatalf("status = %d, want 200", status)
	}
	if got := headers.Get("Access-Control-Allow-Origin"); got != "http://localhost:5173" {
		t.Errorf("Access-Control-Allow-Origin = %q, want http://localhost:5173", got)
	}
}

func TestProxyForwardsServiceToken(t *testing.T) {
	s := newTestServer(t)
	base := runGateway(t, s)

	status, out, _ := getJSON(t, base+"/api/v1/notifications", http.MethodPost, map[string]string{
		"X-Service-Token": "s3cr3t",
	})

	if status != http.StatusOK {
		t.Fatalf("status = %d, want 200", status)
	}
	if out["svc_token"] != "s3cr3t" {
		t.Errorf("X-Service-Token not forwarded: %q", out["svc_token"])
	}
}

func TestProxyDownstreamUnavailable(t *testing.T) {
	s := newTestServer(t)
	base := runGateway(t, s)

	status, out, _ := getJSON(t, base+"/api/v1/auth/register", http.MethodPost, nil)

	if status != http.StatusBadGateway {
		t.Fatalf("status = %d, want 502 (body %v)", status, out)
	}
	if out["error"] != "service unavailable" {
		t.Errorf("error body = %v, want service unavailable", out)
	}
}

func TestProxyHealthThroughGateway(t *testing.T) {
	s := newTestServer(t)
	r := s.RegisterRoutes()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	var out struct {
		Status   string            `json:"status"`
		Services map[string]string `json:"services"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &out); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if out.Services["event"] != "up" || out.Services["notifications"] != "up" || out.Services["ml"] != "up" {
		t.Errorf("live upstreams misreported: %+v", out.Services)
	}
	if out.Services["auth"] != "down" {
		t.Errorf("dead upstream misreported: %+v", out.Services)
	}
	if w.Code != http.StatusServiceUnavailable {
		t.Errorf("status = %d, want 503 while some upstream is down", w.Code)
	}
}