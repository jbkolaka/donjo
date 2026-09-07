package bookingservice

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"donjo_booking/internal/auth"
	"donjo_booking/internal/models"
)

// Handler exposes the booking domain over HTTP.
type Handler struct {
	service *BookingService
}

// NewHandler wires the service onto HTTP.
func NewHandler(service *BookingService) *Handler {
	return &Handler{service: service}
}

// FromClaim extracts the authenticated identity.
func FromClaim(c *gin.Context) (string, string) {
	return auth.UserID(c), auth.Email(c)
}

func (h *Handler) err(c *gin.Context, err error) {
	switch err {
	case nil:
		return
	case ErrNotFound:
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
	case ErrForbidden:
		c.JSON(http.StatusForbidden, gin.H{"error": "forbidden"})
	case ErrConflict:
		c.JSON(http.StatusConflict, gin.H{"error": "conflict"})
	case ErrBadRequest:
		c.JSON(http.StatusBadRequest, gin.H{"error": "bad request"})
	default:
		log.Printf("[booking] error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}

// ---- bookings -----------------------------------------------------------------

// ListMyBookings GET /bookings/me
func (h *Handler) ListMyBookings(c *gin.Context) {
	uid, _ := FromClaim(c)
	bs, err := h.service.ListMyBookings(uid)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"bookings": bs})
}

// BookingDetail GET /bookings/:id
func (h *Handler) BookingDetail(c *gin.Context) {
	uid, _ := FromClaim(c)
	b, err := h.service.BookingDetail(uid, c.Param("id"))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, b)
}

// ---- instances + group assignment -------------------------------------------------

// ListMyInstances GET /instances/me
func (h *Handler) ListMyInstances(c *gin.Context) {
	uid, _ := FromClaim(c)
	insts, err := h.service.InstancesForUser(uid)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"instances": insts})
}

type assignRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
	Phone string `json:"phone"`
}

// AssignHolder POST /instances/:id/assign — names the person a group ticket is for.
func (h *Handler) AssignHolder(c *gin.Context) {
	uid, _ := FromClaim(c)
	var req assignRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Name) == "" {
		h.err(c, ErrBadRequest)
		return
	}
	inst, err := h.service.AssignHolder(uid, c.Param("id"), strings.TrimSpace(req.Name), strings.TrimSpace(req.Email), strings.TrimSpace(req.Phone))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, inst)
}

// ---- transfer (share / claim) ------------------------------------------------------

type shareRequest struct {
	Email string `json:"email"`
}

// ShareTicket POST /instances/:id/share
func (h *Handler) ShareTicket(c *gin.Context) {
	uid, _ := FromClaim(c)
	var req shareRequest
	if err := c.ShouldBindJSON(&req); err != nil || !strings.Contains(req.Email, "@") {
		h.err(c, ErrBadRequest)
		return
	}
	inst, err := h.service.ShareTicket(uid, c.Param("id"), strings.ToLower(strings.TrimSpace(req.Email)))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"instance": inst, "message": "Ticket offered; the claimer rotates in a new code."})
}

// ClaimTicket POST /instances/claim
func (h *Handler) ClaimTicket(c *gin.Context) {
	uid, _ := FromClaim(c)
	var req shareRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Email) == "" {
		h.err(c, ErrBadRequest)
		return
	}
	inst, err := h.service.ClaimTicket(uid, strings.ToLower(strings.TrimSpace(req.Email)), strings.TrimSpace(c.Query("code")))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, inst)
}

// CancelShare DELETE /instances/:id/share
func (h *Handler) CancelShare(c *gin.Context) {
	uid, _ := FromClaim(c)
	inst, err := h.service.CancelShare(uid, c.Param("id"))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, inst)
}

// ---- resale ------------------------------------------------------------------------

type resaleRequest struct {
	Price float64 `json:"price"`
}

// ListForResale POST /instances/:id/resale
func (h *Handler) ListForResale(c *gin.Context) {
	uid, _ := FromClaim(c)
	var req resaleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.err(c, ErrBadRequest)
		return
	}
	inst, err := h.service.ListForResale(uid, c.Param("id"), req.Price)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, inst)
}

// UnlistResale DELETE /instances/:id/resale
func (h *Handler) UnlistResale(c *gin.Context) {
	uid, _ := FromClaim(c)
	inst, err := h.service.UnlistResale(uid, c.Param("id"))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, inst)
}

// Marketplace GET /instances/marketplace
func (h *Handler) Marketplace(c *gin.Context) {
	insts, err := h.service.Marketplace()
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"instances": insts})
}

// BuyResale POST /instances/:id/buy
func (h *Handler) BuyResale(c *gin.Context) {
	uid, _ := FromClaim(c)
	inst, err := h.service.BuyResale(uid, c.Param("id"))
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, inst)
}

// ---- check-in -----------------------------------------------------------------------

type checkinRequest struct {
	Code     string `json:"code" binding:"required"`
	Location string `json:"location"`
}

// Checkin POST /instances/checkin — gated (scanners only) and rate limited.
func (h *Handler) Checkin(c *gin.Context) {
	uid, _ := FromClaim(c)
	var req checkinRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.err(c, ErrBadRequest)
		return
	}
	res, err := h.service.Checkin(uid, c.ClientIP(), c.Request.UserAgent(), strings.TrimSpace(req.Location), strings.TrimSpace(req.Code))
	if err != nil {
		h.err(c, err)
		return
	}
	status := http.StatusOK
	if !res.Allowed {
		status = http.StatusUnprocessableEntity
	}
	c.JSON(status, res)
}

// ---- waitlist + scan locations --------------------------------------------------------

type waitlistRequest struct {
	EventID    string `json:"event_id" binding:"required"`
	TicketType string `json:"ticket_type"`
	Quantity   int    `json:"quantity"`
}

// JoinWaitlist POST /waitlist
func (h *Handler) JoinWaitlist(c *gin.Context) {
	uid, _ := FromClaim(c)
	var req waitlistRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.err(c, ErrBadRequest)
		return
	}
	if req.Quantity == 0 {
		req.Quantity = 1
	}
	if err := h.service.JoinWaitlist(uid, req.EventID, req.TicketType, req.Quantity); err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusCreated, gin.H{"status": "ok"})
}

// LeaveWaitlist DELETE /waitlist
func (h *Handler) LeaveWaitlist(c *gin.Context) {
	uid, _ := FromClaim(c)
	eventID := c.Query("event_id")
	if eventID == "" {
		h.err(c, ErrBadRequest)
		return
	}
	if err := h.service.LeaveWaitlist(uid, eventID); err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// Waitlist GET /waitlist?event_id=
func (h *Handler) Waitlist(c *gin.Context) {
	eventID := c.Query("event_id")
	if eventID == "" {
		h.err(c, ErrBadRequest)
		return
	}
	es, n, err := h.service.Waitlist(eventID)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"event_id": eventID, "count": n, "entries": es})
}

// CreateScanLocation POST /scan-locations
func (h *Handler) CreateScanLocation(c *gin.Context) {
	var l models.ScanLocation
	if err := c.ShouldBindJSON(&l); err != nil {
		h.err(c, ErrBadRequest)
		return
	}
	if err := h.service.CreateScanLocation(&l); err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusCreated, l)
}

// ScanLocations GET /scan-locations?event_id=
func (h *Handler) ScanLocations(c *gin.Context) {
	eventID := c.Query("event_id")
	if eventID == "" {
		h.err(c, ErrBadRequest)
		return
	}
	locs, err := h.service.ScanLocations(eventID)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"event_id": eventID, "locations": locs})
}