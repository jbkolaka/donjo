package messaging

import (
	"context"
	"encoding/json"
	"log"

	amqp "github.com/rabbitmq/amqp091-go"
)

// ReleaseFunc releases reserved tickets back to availability.
type ReleaseFunc func(ticketID string, quantity int) error

// StartConsumers registers handlers for the queues this service reacts to.
// Handlers are started automatically whenever the RabbitMQ connection is up
// (including after reconnects), so this can be called before connecting.
func (c *Client) StartConsumers(ctx context.Context, release ReleaseFunc) {
	c.consumeCtx = ctx
	c.RegisterConsumer(QueueTicketSales, func(env Envelope) error {
		return c.handleTicketRelease(env, release)
	})
	c.RegisterConsumer(QueueEventCatalog, func(env Envelope) error {
		log.Printf("[rabbitmq] catalog event consumed: key=%s event_id=%s", env.Key, env.EventID)
		return nil
	})
	c.RegisterConsumer(QueueAuthSync, func(env Envelope) error {
		log.Printf("[rabbitmq] auth sync event consumed: key=%s", env.Key)
		return nil
	})
}

// CConsume blocks consuming messages from queue on channel ch, feeding decoded
// envelopes to handler. Returning an error from handler requeues that message.
func CConsume(ch *amqp.Channel, queue string, handler func(Envelope) error, ctx context.Context) error {
	if ch == nil {
		return ErrNotConnected
	}

	msgs, err := ch.Consume(
		queue,
		"",
		false, // manual ack so failures can be requeued
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		return err
	}

	log.Printf("[rabbitmq] consuming from %s", queue)
	for {
		select {
		case <-ctx.Done():
			return nil
		case msg, ok := <-msgs:
			if !ok {
				return ErrNotConnected
			}
			if err := handleDelivery(msg, handler); err != nil {
				log.Printf("[rabbitmq] handler error on %s: %v — requeueing", queue, err)
				_ = msg.Nack(false, true)
				continue
			}
			_ = msg.Ack(false)
		}
	}
}

func handleDelivery(msg amqp.Delivery, handler func(Envelope) error) error {
	env, err := unmarshalEnvelope(msg.Body)
	if err != nil {
		log.Printf("[rabbitmq] invalid message: %v — rejecting", err)
		_ = msg.Nack(false, false)
		return nil
	}
	return handler(env)
}

func (c *Client) handleTicketRelease(env Envelope, release ReleaseFunc) error {
	if release == nil {
		return nil
	}
	var rel struct {
		TicketID string `json:"ticket_id"`
		Quantity int    `json:"quantity"`
	}
	data, err := json.Marshal(env.Data)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &rel); err != nil {
		return err
	}
	if rel.TicketID == "" || rel.Quantity <= 0 {
		return nil
	}
	return release(rel.TicketID, rel.Quantity)
}