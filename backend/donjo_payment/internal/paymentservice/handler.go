package paymentservice

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"donjo_payment/internal/auth"
)

// Handler exposes the payment domain over HTTP.
type Handler struct {
	service *PaymentService
}

func NewHandler(service *PaymentService) *Handler {
	return &Handler{service: service}
}

func (h *Handler) err(c *gin.Context, err error) {
	switch err {
	case nil:
		return
	case ErrNotFound:
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
	default:
		log.Printf("[payment] error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "internal error"})
	}
}

// ListMyTransactions GET /transactions/me
func (h *Handler) ListMyTransactions(c *gin.Context) {
	uid := auth.UserID(c)
	ts, err := h.service.ListMyTransactions(uid)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"transactions": ts})
}

// TransactionDetail GET /transactions/:id
func (h *Handler) TransactionDetail(c *gin.Context) {
	uid, id := auth.UserID(c), c.Param("id")
	t, err := h.service.TransactionDetail(uid, id)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"transaction": t})
}

// EscrowDetail GET /escrows/:id
func (h *Handler) EscrowDetail(c *gin.Context) {
	uid, id := auth.UserID(c), c.Param("id")
	e, err := h.service.EscrowDetail(uid, id)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"escrow": e})
}

// MyWallet GET /wallet/me
func (h *Handler) MyWallet(c *gin.Context) {
	uid := auth.UserID(c)
	es, err := h.service.MyWallet(uid)
	if err != nil {
		h.err(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"entries": es})
}
