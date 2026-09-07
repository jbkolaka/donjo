package messaging

import (
	"context"
	"encoding/json"
	"log"

	amqp "github.com/rabbitmq/amqp091-go"
)

// PurchaseHandler receives one completed purchase event from donjo_event.
type PurchaseHandler func(purchase TicketPurchased) error

// PaymentHandler receives one payment.processed event from donjo_payment.
type PaymentHandler func(processed PaymentProcessed) error

// StartConsumers registers the handlers for queue QueueBookingSales. They are
// started automatically whenever the RabbitMQ connection is up (including
// after reconnects), so this can be called before connecting.
func (c *Client) StartConsumers(ctx context.Context, onPurchase PurchaseHandler, onPayment PaymentHandler) {
	c.consumeCtx = ctx
	c.RegisterConsumer(QueueBookingSales, func(env Envelope) error {
		switch env.Key {
		case KeyTicketPurchased:
			return c.handleTicketPurchased(env, onPurchase)
		case KeyPaymentProcessed:
			return c.handlePaymentProcessed(env, onPayment)
		}
		return nil
	})
}

func (c *Client) handleTicketPurchased(env Envelope, onPurchase PurchaseHandler) error {
	if onPurchase == nil {
		return nil
	}
	var p TicketPurchased
	data, err := json.Marshal(env.Data)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &p); err != nil {
		return err
	}
	if p.EventID == "" || p.TicketID == "" || p.UserID == "" || p.Quantity <= 0 {
		log.Printf("[rabbitmq] ticket.purchased ignored: incomplete data")
		return nil
	}
	return onPurchase(p)
}

func (c *Client) handlePaymentProcessed(env Envelope, onPayment PaymentHandler) error {
	if onPayment == nil {
		return nil
	}
	var p PaymentProcessed
	data, err := json.Marshal(env.Data)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(data, &p); err != nil {
		return err
	}
	if p.OrderID == "" || p.TransactionID == "" || p.EscrowID == "" {
		log.Printf("[rabbitmq] payment.processed ignored: incomplete data")
		return nil
	}
	return onPayment(p)
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