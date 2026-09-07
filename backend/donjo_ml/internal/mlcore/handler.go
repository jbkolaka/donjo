package mlcore

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"donjo_ml/internal/auth"
)

// Handler exposes the ML service's HTTP surface (recommendations feed, similar
// events, profile, and interaction recording). Identity for per-user routes is
// read from the JWT set by the auth middleware.
type Handler struct {
	svc  *MLService
	auth *auth.Middleware
}

func NewHandler(svc *MLService, authMW *auth.Middleware) *Handler {
	return &Handler{svc: svc, auth: authMW}
}

// Auth exposes the shared JWT middleware so routes can protect per-user groups.
func (h *Handler) Auth() *auth.Middleware { return h.auth }

func userID(c *gin.Context) string {
	if v, ok := c.Get(auth.ContextUserID); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func limitParam(c *gin.Context, def, max int) int {
	n := def
	if raw := c.Query("limit"); raw != "" {
		if v, err := strconv.Atoi(raw); err == nil && v > 0 {
			n = v
		}
	}
	if n > max {
		return max
	}
	return n
}

// Recommendations serves the personalised feed for the authenticated user.
//
//	GET /api/v1/recommendations?type=upcoming|trending&limit=N
func (h *Handler) Recommendations(c *gin.Context) {
	typ := c.Query("type")
	res, err := h.svc.Recommendations(userID(c), typ, limitParam(c, 10, 50))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to produce recommendations"})
		return
	}
	c.JSON(http.StatusOK, res)
}

// SimilarEvents returns events most similar to the given one.
//
//	GET /api/v1/events/:id/similar?limit=N
func (h *Handler) SimilarEvents(c *gin.Context) {
	eventID := c.Param("id")
	items, err := h.svc.SimilarEvents(eventID, limitParam(c, 8, 20))
	if err != nil {
		if err == ErrEventNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "event not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to compute similar events"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"event_id": eventID, "items": items})
}

// GetEvent returns the ML service's stored copy of an event document.
//
//	GET /api/v1/events/:id
func (h *Handler) GetEvent(c *gin.Context) {
	ev, err := h.svc.Event(c.Param("id"))
	if err != nil {
		if err == ErrEventNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "event not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load event"})
		return
	}
	c.JSON(http.StatusOK, ev)
}

// Profile returns the authenticated user's learned preferences.
//
//	GET /api/v1/profile
func (h *Handler) Profile(c *gin.Context) {
	uid := userID(c)
	p, err := h.svc.Profile(uid)
	if err != nil {
		if err == ErrUserNotFound {
			c.JSON(http.StatusOK, gin.H{
				"user_id":           uid,
				"model_version":     ModelVersion,
				"interaction_count": 0,
				"preferences":       nil,
				"message":           "no profile yet; interactions and purchases will train the model",
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load profile"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"user_id":           p.UserID,
		"model_version":     ModelVersion,
		"interaction_count": p.InteractionCount,
		"preferences": gin.H{
			"categories": p.PreferredCategories,
			"venues":     p.PreferredVenues,
			"times":      p.PreferredTimes,
		},
		"last_calculated_at": p.LastCalculatedAt,
	})
}

// RecordInteraction ingests a user behaviour used to train the model.
//
//	POST /api/v1/interactions
func (h *Handler) RecordInteraction(c *gin.Context) {
	var in InteractionIn
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid interaction payload"})
		return
	}
	uid := userID(c)
	if err := h.svc.RecordInteraction(uid, in); err != nil {
		if err == ErrInteracted {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to record interaction"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{
		"user_id":          uid,
		"interaction_type": in.InteractionType,
		"status":           "recorded",
	})
}
