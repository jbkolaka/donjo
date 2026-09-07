package gateway

import (
	"testing"
)

func TestTargetForRouting(t *testing.T) {
	g := NewGateway(LoadConfig())

	cases := []struct {
		path string
		want RouterKey
	}{
		// events + venues -> donjo_event; similar is the ML service.
		{"/api/v1/events", "event"},
		{"/api/v1/events/slug/summer-picnic", "event"},
		{"/api/v1/events/abc123/tickets", "event"},
		{"/api/v1/events/abc123/tickets/t-1/purchase", "event"},
		{"/api/v1/events/abc123/similar", "ml"},
		{"/api/v1/venues", "event"},
		{"/api/v1/venues/xyz", "event"},

		// auth identity + user + sessions
		{"/api/v1/auth/login", "auth"},
		{"/api/v1/auth/refresh", "auth"},
		{"/api/v1/me", "auth"},
		{"/api/v1/me/profile-image", "auth"},
		{"/api/v1/2fa/status", "auth"},
		{"/api/v1/sessions", "auth"},
		{"/api/v1/sessions/abc/revoke", "auth"},
		{"/uploads/abc.png", "auth"},

		// booking
		{"/api/v1/bookings/me", "booking"},
		{"/api/v1/bookings/abc", "booking"},
		{"/api/v1/instances/me", "booking"},
		{"/api/v1/instances/abc/assign", "booking"},
		{"/api/v1/instances/checkin", "booking"},
		{"/api/v1/instances/marketplace", "booking"},
		{"/api/v1/waitlist", "booking"},
		{"/api/v1/scan-locations", "booking"},

		// payment
		{"/api/v1/transactions/me", "payment"},
		{"/api/v1/transactions/abc", "payment"},
		{"/api/v1/escrows/abc", "payment"},
		{"/api/v1/wallet/me", "payment"},

		// search
		{"/api/v1/search", "search"},

		// ml
		{"/api/v1/recommendations", "ml"},
		{"/api/v1/profile", "ml"},
		{"/api/v1/interactions", "ml"},

		// notifications
		{"/api/v1/notifications", "notifications"},
		{"/api/v1/notifications/unread-count", "notifications"},
		{"/api/v1/feed", "notifications"},
		{"/api/v1/devices", "notifications"},
		{"/api/v1/devices/me", "notifications"},
		{"/api/v1/templates", "notifications"},

		// unknown or infra paths do not route
		{"/api/v1/nope", ""},
		{"/", ""},
		{"/health", ""},
		{"/api/v1", ""},
	}

	for _, tc := range cases {
		got := g.targetFor(tc.path)
		if got != tc.want {
			t.Errorf("targetFor(%q) = %q, want %q", tc.path, got, tc.want)
		}
	}
}

// TestTargetForSpecificity ensures shared-prefix rules resolve to the correct
// owner (ml wins for /events/:id/similar before donjo_event grabs /events).
func TestTargetForSpecificity(t *testing.T) {
	g := NewGateway(LoadConfig())
	if got := g.targetFor("/api/v1/events/abc/similar"); got != "ml" {
		t.Errorf("/events/:id/similar = %q, want ml", got)
	}
	if got := g.targetFor("/api/v1/events/abc/tickets"); got != "event" {
		t.Errorf("/events/:id/tickets = %q, want event", got)
	}
}

func TestClientIP(t *testing.T) {
	cases := map[string]string{
		"127.0.0.1:8080": "127.0.0.1",
		"10.0.0.5:443":   "10.0.0.5",
		"[::1]:8080":     "::1",
		"192.168.1.1":    "192.168.1.1",
	}
	for in, want := range cases {
		if got := clientIP(in); got != want {
			t.Errorf("clientIP(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestSplitCSV(t *testing.T) {
	got := splitCSV("a, b ,c,,")
	if len(got) != 3 || got[0] != "a" || got[1] != "b" || got[2] != "c" {
		t.Errorf("splitCSV = %v, want [a b c]", got)
	}
	if got := splitCSV(""); len(got) != 0 {
		t.Errorf("splitCSV(\"\") = %v, want empty", got)
	}
	if got := splitCSV("http://localhost:5173"); len(got) != 1 || got[0] != "http://localhost:5173" {
		t.Errorf("splitCSV single = %v, want single origin", got)
	}
}