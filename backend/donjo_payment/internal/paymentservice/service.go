package paymentservice

import (
	"errors"
	"log"

	"donjo_payment/internal/messaging"
	"donjo_payment/internal/models"
	"donjo_payment/internal/repository"
)

var (
	// ErrNotFound is returned when the caller does not own the resource.
	ErrNotFound = errors.New("not found")
	// ErrInternal is the catch-all for unexpected failures.
	ErrInternal = errors.New("internal error")
)

// Bus publishes payment.processed back to the rabbit exchange so the other
// services (donjo_booking) can backfill the transaction/escrow ids.
type Bus interface {
	Publish(routingKey string, envelope messaging.Envelope) error
}

// PaymentService owns the payment domain: recording purchases as
// transaction + escrow + wallet ledger, and serving them back to the buyer.
type PaymentService struct {
	txns   *repository.TransactionRepository
	wallet *repository.WalletRepository
	bus    Bus
}

func New(txns *repository.TransactionRepository, wallet *repository.WalletRepository, bus Bus) *PaymentService {
	return &PaymentService{txns: txns, wallet: wallet, bus: bus}
}

// HandlePurchase is the RabbitMQ intake: one completed purchase lands as a
// paid transaction + a held escrow + an organizer credit in the wallet ledger,
// committed atomically. Afterward a payment.processed message announces the
// ids (best-effort publish; the database is the source of truth).
func (s *PaymentService) HandlePurchase(p messaging.TicketPurchased) error {
	if s.txns == nil {
		return nil
	}
	tr, esc, err := s.txns.RecordPurchase(snapshot(p))
	if err != nil {
		log.Printf("[payment] record order %s: %v", p.OrderID, err)
		return err
	}
	log.Printf("[payment] order %s → txn %s (%s) + escrow %s (%s)",
		p.OrderID, tr.ID, tr.Status, esc.ID, esc.Status)

	if s.bus != nil {
		if err := s.bus.Publish(messaging.KeyPaymentProcessed, messaging.Envelope{
			Resource: "payment",
			Data: messaging.PaymentProcessed{
				OrderID:           p.OrderID,
				TransactionID:     tr.ID,
				TransactionStatus: tr.Status,
				EscrowID:          esc.ID,
				EscrowStatus:      esc.Status,
				EscrowAmount:      esc.TotalAmount,
				PlatformFee:       esc.PlatformFee,
				OrganizerAmount:   esc.OrganizerAmount,
				PaymentMethod:     tr.PaymentMethod,
				Currency:          tr.Currency,
			},
		}); err != nil {
			log.Printf("[payment] publish payment.processed for %s: %v", p.OrderID, err)
		}
	}
	return nil
}

func snapshot(p messaging.TicketPurchased) models.PurchaseSnapshot {
	return models.PurchaseSnapshot{
		OrderID:       p.OrderID,
		EventID:       p.EventID,
		EventSlug:     p.EventSlug,
		EventTitle:    p.EventTitle,
		TicketID:      p.TicketID,
		TicketType:    p.TicketType,
		TicketName:    p.TicketName,
		Quantity:      p.Quantity,
		UnitPrice:     p.UnitPrice,
		ServiceFee:    p.ServiceFee,
		ProcessingFee: p.ProcessingFee,
		Amount:        p.Amount,
		Currency:      p.Currency,
		UserID:        p.UserID,
		UserEmail:     p.UserEmail,
		CreatorID:     p.CreatorID,
	}
}

// ListMyTransactions returns the buyer's transactions, newest first.
func (s *PaymentService) ListMyTransactions(userID string) ([]*models.Transaction, error) {
	ts, err := s.txns.ListByUser(userID)
	if err != nil {
		log.Printf("[payment] list %s: %v", userID, err)
		return nil, ErrInternal
	}
	return ts, nil
}

// TransactionDetail returns one transaction owned by the caller, or nil/nil
// style with ErrNotFound when absent or foreign.
func (s *PaymentService) TransactionDetail(userID, id string) (*models.Transaction, error) {
	t, err := s.txns.GetForUser(id, userID)
	if err != nil {
		log.Printf("[payment] get txn %s: %v", id, err)
		return nil, ErrInternal
	}
	if t == nil {
		return nil, ErrNotFound
	}
	return t, nil
}

// EscrowDetail returns an escrow the caller owns (via their transaction), or
// ErrNotFound.
func (s *PaymentService) EscrowDetail(userID, id string) (*models.Escrow, error) {
	e, err := s.txns.GetEscrowForUser(id, userID)
	if err != nil {
		log.Printf("[payment] get escrow %s: %v", id, err)
		return nil, ErrInternal
	}
	if e == nil {
		return nil, ErrNotFound
	}
	return e, nil
}

// MyWallet returns the caller's wallet ledger.
func (s *PaymentService) MyWallet(userID string) ([]*models.WalletEntry, error) {
	es, err := s.wallet.ListByUser(userID)
	if err != nil {
		log.Printf("[payment] wallet %s: %v", userID, err)
		return nil, ErrInternal
	}
	return es, nil
}
