package mlcore

import (
	"testing"
	"time"
)

func TestEventSparseDeterministic(t *testing.T) {
	ev := &EventDoc{
		ID:           "e1",
		Title:        "Lamu Old Town Gala",
		Category:     "Concert",
		SubCategory:  "Live",
		EventType:    "physical",
		City:         "Lamu",
		Country:      "Kenya",
		MinTicketPrice: 3200,
		StartTime:    time.Date(2026, 9, 19, 18, 0, 0, 0, time.UTC),
	}

	a := EventSparse(ev, nil)
	if len(a) == 0 {
		t.Fatal("expected non-empty feature bag")
	}
	b := EventSparse(ev, nil)
	for i, w := range a {
		if b[i] != w {
			t.Fatalf("non-deterministic feature bag at %d: %v vs %v", i, w, b[i])
		}
	}

	dense := Dense(a)
	if len(dense) != EmbeddingDim {
		t.Fatalf("expected dense vector of %d dims, got %d", EmbeddingDim, len(dense))
	}
	var sum float64
	for _, x := range dense {
		sum += x * x
	}
	if sum < 0.999 || sum > 1.001 {
		t.Fatalf("expected L2-normalised dense vector, got norm^2 %v", sum)
	}
	if Cosine(dense, dense) < 0.999 {
		t.Errorf("identical vector should score ~1, got %v", Cosine(dense, dense))
	}
}

func TestSparseAddAndCosine(t *testing.T) {
	ev1 := &EventDoc{ID: "e1", Title: "Jazz Night", Category: "Jazz", City: "Mombasa", StartTime: time.Now()}
	ev2 := &EventDoc{ID: "e2", Title: "Jazz Brunch", Category: "Jazz", City: "Mombasa", StartTime: time.Now()}
	ev3 := &EventDoc{ID: "e3", Title: "Tech Conference", Category: "Tech", City: "Nairobi", StartTime: time.Now()}

	s1 := EventSparse(ev1, nil)
	s2 := EventSparse(ev2, nil)
	s3 := EventSparse(ev3, nil)

	user := Sparse{}
	SparseAdd(user, s1, 5)
	SparseAdd(user, s2, 5)

	u := Dense(user)
	d1 := Dense(s1)
	d3 := Dense(s3)

	if Cosine(u, d1) <= Cosine(u, d3) {
		t.Errorf("user heavy in jazz should match jazz event better than tech; got %v vs %v",
			Cosine(u, d1), Cosine(u, d3))
	}
}

func TestPriceBands(t *testing.T) {
	cases := map[float64]string{0: "free", 500: "b1", 1000: "b2", 2500: "b3", 12000: "b4"}
	for p, want := range cases {
		if got := priceBand(p); got != want {
			t.Errorf("priceBand(%v) = %q, want %q", p, got, want)
		}
	}
}