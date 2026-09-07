package notificationservice

import (
	"testing"

	"donjo_notifications/internal/messaging"
)

func TestRenderTemplate(t *testing.T) {
	tmpl := &NotificationTemplate{
		SubjectTemplate: "Your tickets are confirmed",
		ContentTemplate: "You're going to {{event_title}}! {{quantity}} x {{ticket_name}} (order {{order_id}}).",
	}
	subject, content := RenderTemplate(tmpl, map[string]interface{}{
		"event_title": "Summer Picnic",
		"quantity":    2,
		"ticket_name": "General",
		"order_id":    "ORD-1",
	})
	if subject != "Your tickets are confirmed" {
		t.Errorf("subject = %q, want %q", subject, "Your tickets are confirmed")
	}
	want := "You're going to Summer Picnic! 2 x General (order ORD-1)."
	if content != want {
		t.Errorf("content = %q, want %q", content, want)
	}
}

func TestRenderTemplateUnknownVariableLeftIntact(t *testing.T) {
	tmpl := &NotificationTemplate{ContentTemplate: "Hi {{name}}, see {{missing}}"}
	_, content := RenderTemplate(tmpl, map[string]interface{}{"name": "Ada"})
	if content != "Hi Ada, see {{missing}}" {
		t.Errorf("content = %q", content)
	}
}

func TestDecodePurchase(t *testing.T) {
	in := &messaging.TicketPurchased{
		OrderID:    "ORD-9",
		UserID:     "u-1",
		CreatorID:  "u-2",
		EventTitle: "Jazz Night",
		Quantity:   3,
		Amount:     7500,
		Currency:   "IDR",
	}
	p, err := decodePurchase(in)
	if err != nil {
		t.Fatalf("decode purchase: %v", err)
	}
	if p.UserID != "u-1" || p.CreatorID != "u-2" || p.EventTitle != "Jazz Night" {
		t.Errorf("decoded purchase mismatch: %+v", p)
	}
	if p.Quantity != 3 || p.Amount != 7500 || p.Currency != "IDR" {
		t.Errorf("decoded money fields mismatch: %+v", p)
	}
}

func TestDecodeEventPublished(t *testing.T) {
	in := &messaging.EventPublished{
		EventID: "evt-42",
		Slug:    "summer-picnic",
		Title:   "Summer Picnic",
	}
	ev, err := decodeEventPublished(in)
	if err != nil {
		t.Fatalf("decode event: %v", err)
	}
	if ev.EventID != "evt-42" || ev.Slug != "summer-picnic" || ev.Title != "Summer Picnic" {
		t.Errorf("decoded event mismatch: %+v", ev)
	}
}

func TestFeedPriority(t *testing.T) {
	if got := feedPriority(nil); got != 0 {
		t.Errorf("nil priority = %d, want 0", got)
	}
	p := 3
	if got := feedPriority(&p); got != 3 {
		t.Errorf("priority = %d, want 3", got)
	}
}