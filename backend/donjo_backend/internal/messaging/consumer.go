package messaging

import (
	"context"
	"encoding/json"
	"log"

	"donjo_backend/internal/repository"
)

// Consumer wires the RabbitMQ handlers to user statistics updates.
type Consumer struct {
	users *repository.UserRepository
	bus   *Client
	ctx   context.Context
}

func NewConsumer(ctx context.Context, bus *Client, users *repository.UserRepository) *Consumer {
	return &Consumer{ctx: ctx, bus: bus, users: users}
}

// Start subscribes to the queues the auth service cares about. Each queue
// consumes in its own goroutine (Consume blocks until the context ends).
func (c *Consumer) Start() {
	go c.bus.Consume(c.ctx, QueueTicketSales, c.handleTicketSale)
	go c.bus.Consume(c.ctx, QueueEventCatalog, c.handleCatalog)
}

func (c *Consumer) handleTicketSale(env Envelope) error {
	if env.Key != KeyTicketPurchased {
		return nil
	}

	var tp TicketPurchased
	if err := json.Unmarshal(env.Data, &tp); err != nil {
		return err
	}
	if tp.Quantity <= 0 {
		return nil
	}

	// Buyer stats: tickets_sold, total_spent.
	if tp.UserID != "" {
		if err := c.users.IncrementTicketsBought(c.ctx, tp.UserID, tp.Quantity, tp.Amount); err != nil {
			log.Printf("[mq] increment buyer stats for %s: %v", tp.UserID, err)
		}
	}
	// Creator earnings: total_earned + wallet_balance.
	if tp.CreatorID != "" {
		if err := c.users.IncrementEarnings(c.ctx, tp.CreatorID, tp.Amount); err != nil {
			log.Printf("[mq] increment creator earnings for %s: %v", tp.CreatorID, err)
		}
	}
	return nil
}

func (c *Consumer) handleCatalog(env Envelope) error {
	switch env.Key {
	case KeyEventCreated:
		var e EventEnvelope
		if err := json.Unmarshal(env.Data, &e); err != nil {
			return err
		}
		if e.CreatorID != "" {
			_ = c.users.AdjustEventsCreated(c.ctx, e.CreatorID, 1)
		}
	case KeyEventDeleted:
		var e EventEnvelope
		if err := json.Unmarshal(env.Data, &e); err != nil {
			return err
		}
		if e.CreatorID != "" {
			_ = c.users.AdjustEventsCreated(c.ctx, e.CreatorID, -1)
		}
	case KeyVenueCreated:
		var v VenueEnvelope
		if err := json.Unmarshal(env.Data, &v); err != nil {
			return err
		}
		if v.CreatorID != "" {
			_ = c.users.AdjustVenuesListed(c.ctx, v.CreatorID, 1)
		}
	case KeyVenueDeleted:
		var v VenueEnvelope
		if err := json.Unmarshal(env.Data, &v); err != nil {
			return err
		}
		if v.CreatorID != "" {
			_ = c.users.AdjustVenuesListed(c.ctx, v.CreatorID, -1)
		}
	}
	return nil
}