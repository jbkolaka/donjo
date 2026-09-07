package notificationservice

import (
	"crypto/subtle"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"

	"donjo_notifications/internal/auth"
)

// Handler exposes the notification service's HTTP surface (notifications,
// feed, push devices and templates). Identity for per-user routes is read
// from the JWT set by the auth middleware; a shared service token grants
// privileged cross-service pushes.
type Handler struct {
	svc    *Service
	auth   *auth.Middleware
	token  string
}

func NewHandler(svc *Service, authMW *auth.Middleware) *Handler {
	return &Handler{svc: svc, auth: authMW, token: os.Getenv("SERVICE_TOKEN")}
}

// Auth exposes the shared JWT middleware so routes can protect per-user groups.
func (h *Handler) Auth() *auth.Middleware { return h.auth }

// isServiceToken does a constant-time comparison against the configured value.
func (h *Handler) isServiceToken(given string) bool {
	return h.token != "" && subtle.ConstantTimeCompare([]byte(given), []byte(h.token)) == 1
}

func currentUserID(c *gin.Context) string {
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

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

// CreateNotification creates a notification (and optional feed item) for the
// authenticated user, or for any user when a valid service token is supplied.
//
//	POST /api/v1/notifications
func (h *Handler) CreateNotification(c *gin.Context) {
	var in NotifyIn
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid notification payload"})
		return
	}
	uid := currentUserID(c)
	if h.token != "" && h.isServiceToken(c.GetHeader("X-Service-Token")) && in.TargetUserID != "" {
		uid = in.TargetUserID
	}
	if uid == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "no user identity"})
		return
	}
	n, err := h.svc.CreateNotification(uid, &in)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, n)
}

// ListNotifications returns the caller's notifications.
//
//	GET /api/v1/notifications?status=&limit=
func (h *Handler) ListNotifications(c *gin.Context) {
	items, err := h.svc.ListNotifications(currentUserID(c), c.Query("status"), limitParam(c, 20, 100))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load notifications"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

// UnreadCount returns the number of unread notifications.
//
//	GET /api/v1/notifications/unread-count
func (h *Handler) UnreadCount(c *gin.Context) {
	n, err := h.svc.UnreadCount(currentUserID(c))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to count notifications"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"count": n})
}

// MarkRead flags a notification as read.
//
//	PATCH /api/v1/notifications/:id/read
func (h *Handler) MarkRead(c *gin.Context) {
	if err := h.svc.MarkRead(currentUserID(c), c.Param("id")); err != nil {
		notFoundOr500(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "read"})
}

// MarkClicked flags a notification as clicked.
//
//	PATCH /api/v1/notifications/:id/clicked
func (h *Handler) MarkClicked(c *gin.Context) {
	if err := h.svc.MarkClicked(currentUserID(c), c.Param("id")); err != nil {
		notFoundOr500(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "clicked"})
}

// ---------------------------------------------------------------------------
// Feed
// ---------------------------------------------------------------------------

// GetFeed returns the caller's feed items.
//
//	GET /api/v1/feed?limit=&unread=true
func (h *Handler) GetFeed(c *gin.Context) {
	unreadOnly := c.Query("unread") == "true"
	items, err := h.svc.Feed(currentUserID(c), limitParam(c, 20, 100), unreadOnly)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load feed"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

// MarkFeedViewed marks a feed item as seen.
//
//	PATCH /api/v1/feed/:id/view
func (h *Handler) MarkFeedViewed(c *gin.Context) {
	if err := h.svc.MarkFeedViewed(currentUserID(c), c.Param("id")); err != nil {
		notFoundOr500(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "viewed"})
}

// MarkFeedClicked marks a feed item as opened.
//
//	PATCH /api/v1/feed/:id/click
func (h *Handler) MarkFeedClicked(c *gin.Context) {
	if err := h.svc.MarkFeedClicked(currentUserID(c), c.Param("id")); err != nil {
		notFoundOr500(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "clicked"})
}

// MarkFeedInteracted marks a feed item as interacted with.
//
//	PATCH /api/v1/feed/:id/interact
func (h *Handler) MarkFeedInteracted(c *gin.Context) {
	if err := h.svc.MarkFeedInteracted(currentUserID(c), c.Param("id")); err != nil {
		notFoundOr500(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "interacted"})
}

// ---------------------------------------------------------------------------
// Push devices
// ---------------------------------------------------------------------------

// RegisterDevice upserts a push device for the caller.
//
//	POST /api/v1/devices
func (h *Handler) RegisterDevice(c *gin.Context) {
	var in DeviceIn
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid device payload"})
		return
	}
	d, err := h.svc.RegisterDevice(currentUserID(c), &in)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, d)
}

// ListDevices returns the caller's push devices.
//
//	GET /api/v1/devices/me
func (h *Handler) ListDevices(c *gin.Context) {
	items, err := h.svc.Devices(currentUserID(c))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load devices"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

// DeleteDevice deactivates a device.
//
//	DELETE /api/v1/devices/:id
func (h *Handler) DeleteDevice(c *gin.Context) {
	if err := h.svc.DeleteDevice(currentUserID(c), c.Param("id")); err != nil {
		notFoundOr500(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "deactivated"})
}

// ---------------------------------------------------------------------------
// Templates
// ---------------------------------------------------------------------------

// ListTemplates returns the active templates (public).
//
//	GET /api/v1/templates
func (h *Handler) ListTemplates(c *gin.Context) {
	items, err := h.svc.Templates()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to load templates"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"items": items})
}

func notFoundOr500(c *gin.Context, err error) {
	if err == ErrNotFound {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusInternalServerError, gin.H{"error": "request failed"})
}