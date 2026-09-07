package eventservice

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"donjo_event/internal/auth"
	"donjo_event/internal/models"
	"donjo_event/internal/repository"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// ---- Events ----

func (h *Handler) CreateEvent(c *gin.Context) {
	var in models.Event
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	created, err := h.svc.CreateEvent(auth.UserID(c), &in)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, created)
}

func (h *Handler) GetEvent(c *gin.Context) {
	e, err := h.svc.GetEvent(c.Param("id"))
	if err != nil {
		respondError(c, err)
		return
	}
	h.svc.IncrementViews(e.ID)
	c.JSON(http.StatusOK, e)
}

func (h *Handler) GetEventBySlug(c *gin.Context) {
	e, err := h.svc.GetEventBySlug(c.Param("slug"))
	if err != nil {
		respondError(c, err)
		return
	}
	h.svc.IncrementViews(e.ID)
	c.JSON(http.StatusOK, e)
}

func (h *Handler) ListEvents(c *gin.Context) {
	f := repository.EventFilter{
		CreatorID: c.Query("creator_id"),
		Category:  c.Query("category"),
		Status:    c.Query("status"),
		City:      c.Query("city"),
		Upcoming:  c.Query("upcoming") == "true",
	}
	if v := c.Query("limit"); v != "" {
		f.Limit, _ = strconv.Atoi(v)
	}
	if v := c.Query("offset"); v != "" {
		f.Offset, _ = strconv.Atoi(v)
	}

	events, err := h.svc.ListEvents(auth.UserID(c), f)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"events": events})
}

func (h *Handler) UpdateEvent(c *gin.Context) {
	var in models.Event
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updated, err := h.svc.UpdateEvent(auth.UserID(c), c.Param("id"), &in)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, updated)
}

func (h *Handler) DeleteEvent(c *gin.Context) {
	if err := h.svc.DeleteEvent(auth.UserID(c), c.Param("id")); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "event deleted"})
}

func (h *Handler) PublishEvent(c *gin.Context) {
	updated, err := h.svc.PublishEvent(auth.UserID(c), c.Param("id"))
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, updated)
}

func (h *Handler) UnpublishEvent(c *gin.Context) {
	if err := h.svc.UnpublishEvent(auth.UserID(c), c.Param("id")); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "event unpublished"})
}

func (h *Handler) LikeEvent(c *gin.Context) {
	if err := h.svc.LikeEvent(c.Param("id")); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "liked"})
}

// ---- Venues ----

func (h *Handler) CreateVenue(c *gin.Context) {
	var in models.Venue
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	created, err := h.svc.CreateVenue(auth.UserID(c), &in)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, created)
}

func (h *Handler) GetVenue(c *gin.Context) {
	v, err := h.svc.GetVenue(c.Param("id"))
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, v)
}

func (h *Handler) ListVenues(c *gin.Context) {
	f := repository.VenueFilter{
		CreatorID: c.Query("creator_id"),
		VenueType: c.Query("venue_type"),
		City:      c.Query("city"),
		Status:    c.Query("status"),
	}
	if v := c.Query("limit"); v != "" {
		f.Limit, _ = strconv.Atoi(v)
	}
	if v := c.Query("offset"); v != "" {
		f.Offset, _ = strconv.Atoi(v)
	}
	venues, err := h.svc.ListVenues(f)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"venues": venues})
}

func (h *Handler) UpdateVenue(c *gin.Context) {
	var in models.Venue
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updated, err := h.svc.UpdateVenue(auth.UserID(c), c.Param("id"), &in)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, updated)
}

func (h *Handler) DeleteVenue(c *gin.Context) {
	if err := h.svc.DeleteVenue(auth.UserID(c), c.Param("id")); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "venue deleted"})
}

// ---- Tickets ----

func (h *Handler) CreateTicket(c *gin.Context) {
	var in models.Ticket
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	created, err := h.svc.CreateTicket(auth.UserID(c), c.Param("id"), &in)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusCreated, created)
}

func (h *Handler) ListTickets(c *gin.Context) {
	tickets, err := h.svc.ListTickets(c.Param("id"))
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"tickets": tickets})
}

func (h *Handler) UpdateTicket(c *gin.Context) {
	var in models.Ticket
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updated, err := h.svc.UpdateTicket(auth.UserID(c), c.Param("id"), &in)
	if err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, updated)
}

func (h *Handler) DeleteTicket(c *gin.Context) {
	if err := h.svc.DeleteTicket(auth.UserID(c), c.Param("id")); err != nil {
		respondError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "ticket deleted"})
}

type purchaseRequest struct {
	Quantity int `json:"quantity" binding:"required"`
}

func (h *Handler) PurchaseTicket(c *gin.Context) {
	var req purchaseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updated, err := h.svc.PurchaseTicket(c.Param("id"), c.Param("ticket_id"), auth.UserID(c), auth.Email(c), req.Quantity)
	if err != nil {
		respondError(c, err)
		return
	}
	// Admission codes are issued by the booking service asynchronously:
	// buyers fetch them from GET /instances/me once the order lands.
	c.JSON(http.StatusOK, gin.H{
		"ticket":   updated,
		"quantity": req.Quantity,
		"message":  "purchase confirmed",
	})
}

func respondError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrUnauthorized):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, ErrConflict):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, ErrSoldOut):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, ErrNotPublished):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, ErrInvalidInput):
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal server error"})
	}
}
