package messaging

import (
	"context"
	"encoding/json"
	"log"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

// Handler is a single processed message: the envelope plus the key it arrived
// under. A handler that returns an error requeues the message.
type Handler func(env Envelope) error

// StartConsumers registers the handler for queue QueueNotificationSync. It is started
// automatically whenever the RabbitMQ connection is up (including after
// reconnects), so this can be called before connecting.
func (c *Client) StartConsumers(ctx context.Context, onMessage Handler) {
	c.consumeCtx = ctx
	c.RegisterConsumer(QueueNotificationSync, onMessage)
}

// Decode marshals env.Data back into a typed struct. Data is decoded from
// json.RawMessage internally, so this round-trip normalises it.
func Decode(env Envelope, out interface{}) error {
	data, err := json.Marshal(env.Data)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, out)
}

// maxConsecutiveFailures bounds how many times a failing message is requeued
// before the queue drops it. A downstream outage or malformed message must not
// turn into a hot requeue loop.
const maxConsecutiveFailures = 20

// CConsume blocks consuming messages from queue on channel ch, feeding decoded
// envelopes to handler. Returning an error from handler requeues that message
// with a short backoff; after maxConsecutiveFailures the message is dropped.
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
	failures := 0
	for {
		select {
		case <-ctx.Done():
			return nil
		case msg, ok := <-msgs:
			if !ok {
				return ErrNotConnected
			}
			if err := handleDelivery(msg, handler); err != nil {
				failures++
				if failures > maxConsecutiveFailures {
					log.Printf("[rabbitmq] handler error on %s: %v — dropping message after %d failures", queue, err, maxConsecutiveFailures)
					failures = 0
					_ = msg.Ack(false)
					continue
				}
				log.Printf("[rabbitmq] handler error on %s: %v — requeueing (%d/%d)", queue, err, failures, maxConsecutiveFailures)
				_ = msg.Nack(false, true)
				select {
				case <-time.After(250 * time.Millisecond):
				case <-ctx.Done():
					return nil
				}
				continue
			}
			failures = 0
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
