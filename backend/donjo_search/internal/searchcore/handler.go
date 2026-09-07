package searchcore

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// Handler wires the search API onto HTTP.
type Handler struct {
	svc *SearchService
}

func NewHandler(svc *SearchService) *Handler {
	return &Handler{svc: svc}
}

// Search handles GET /api/v1/search. The `type` param selects the index
// (events | tickets | venues); all other params are forwarded to the query
// builder. An unknown type falls back to events.
func (h *Handler) Search(c *gin.Context) {
	f := Filters{
		Q:         c.Query("q"),
		Category:  c.Query("category"),
		City:      c.Query("city"),
		Country:   c.Query("country"),
		EventType: c.Query("event_type"),
		Status:    c.Query("status"),
		Sort:      c.Query("sort"),
		DateFrom:  c.Query("date_from"),
		DateTo:    c.Query("date_to"),
		Page:      parsePage(c.Query("page")),
		Size:      parseSize(c.Query("size")),
	}
	f.IsVirtual = parseBool(c.Query("is_virtual"))
	f.MinPrice = parseFloat(c.Query("min_price"))
	f.MaxPrice = parseFloat(c.Query("max_price"))
	f.MinCapacity = parseInt(c.Query("min_capacity"))

	typ := c.DefaultQuery("type", "events")
	var (
		res *SearchResult
		err error
	)
	switch typ {
	case "tickets":
		res, err = h.svc.SearchTickets(f)
	case "venues":
		res, err = h.svc.SearchVenues(f)
	default:
		res, err = h.svc.SearchEvents(f)
	}
	if err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "search unavailable"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"total": res.Total,
		"page":  res.Page,
		"size":  res.Size,
		"hits":  res.Hits,
	})
}

func parsePage(v string) int {
	n, err := strconv.Atoi(v)
	if err != nil || n < 1 {
		return 1
	}
	return n
}

func parseSize(v string) int {
	n, err := strconv.Atoi(v)
	if err != nil || n < 1 {
		return 20
	}
	if n > 100 {
		return 100
	}
	return n
}

func parseBool(v string) *bool {
	if v == "" {
		return nil
	}
	b := v == "true" || v == "1" || v == "yes"
	return &b
}

func parseFloat(v string) *float64 {
	if v == "" {
		return nil
	}
	f, err := strconv.ParseFloat(v, 64)
	if err != nil {
		return nil
	}
	return &f
}

func parseInt(v string) *int {
	if v == "" {
		return nil
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return nil
	}
	return &n
}
