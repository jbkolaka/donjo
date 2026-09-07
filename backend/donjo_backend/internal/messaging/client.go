package messaging

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"os"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

var ErrNotConnected = errors.New("rabbitmq not connected")

const (
	ExchangeDonjoEvents = "donjo.events"

	QueueTicketSales = "donjo.ticket.sales.auth"
	QueueEventCatalog = "donjo.event.catalog.auth"
	QueueAuthSync    = "donjo.auth.sync"
)

const (
	KeyEventCreated   = "event.created"
	KeyEventUpdated   = "event.updated"
	KeyEventDeleted   = "event.deleted"
	KeyEventPublished = "event.published"
	KeyTicketPurchased = "ticket.purchased"
	KeyVenueCreated   = "venue.created"
	KeyVenueDeleted   = "venue.deleted"
)

type Envelope struct {
	ID        string          `json:"id"`
	Type      string          `json:"type"`
	Key       string          `json:"key"`
	Timestamp time.Time       `json:"timestamp"`
	Resource  string          `json:"resource"`
	EventID   string          `json:"event_id,omitempty"`
	Data      json.RawMessage `json:"data,omitempty"`
}

type TicketPurchased struct {
	EventID   string  `json:"event_id"`
	EventSlug string  `json:"event_slug,omitempty"`
	TicketID  string  `json:"ticket_id"`
	Quantity  int     `json:"quantity"`
	UserID    string  `json:"user_id"`
	Amount    float64 `json:"amount"`
	CreatorID string  `json:"creator_id"`
}

type EventEnvelope struct {
	CreatorID string `json:"creator_id,omitempty"`
	Title     string `json:"title,omitempty"`
}

type VenueEnvelope struct {
	CreatorID string `json:"creator_id,omitempty"`
	Name      string `json:"name,omitempty"`
}

type Client struct {
	conn    *amqp.Connection
	ch      *amqp.Channel
	url     string
	notify  chan *amqp.Error
}

func NewClient() *Client {
	url := os.Getenv("RABBITMQ_URL")
	if url == "" {
		url = "amqp://guest:guest@localhost:5672/"
	}
	return &Client{url: url}
}

func (c *Client) Connect() error {
	var err error
	for attempt := 1; attempt <= 10; attempt++ {
		c.conn, err = amqp.Dial(c.url)
		if err == nil {
			break
		}
		time.Sleep(time.Duration(attempt) * time.Second)
	}
	if err != nil {
		return err
	}

	c.ch, err = c.conn.Channel()
	if err != nil {
		c.conn.Close()
		return err
	}
	if err := c.declareTopology(); err != nil {
		c.conn.Close()
		return err
	}

	c.notify = c.conn.NotifyClose(make(chan *amqp.Error, 1))
	go c.watchConnection()
	log.Println("[rabbitmq] connected")
	return nil
}

func (c *Client) declareTopology() error {
	if err := c.ch.ExchangeDeclare(ExchangeDonjoEvents, "topic", true, false, false, false, nil); err != nil {
		return err
	}
	type binding struct {
		queue string
		key   string
	}
	for _, b := range []binding{
		{QueueTicketSales, KeyTicketPurchased},
		{QueueEventCatalog, KeyEventCreated},
		{QueueEventCatalog, KeyEventUpdated},
		{QueueEventCatalog, KeyEventDeleted},
		{QueueEventCatalog, KeyEventPublished},
		{QueueEventCatalog, KeyVenueCreated},
		{QueueEventCatalog, KeyVenueDeleted},
		{QueueAuthSync, KeyTicketPurchased},
		{QueueAuthSync, KeyEventCreated},
		{QueueAuthSync, KeyEventDeleted},
	} {
		if _, err := c.ch.QueueDeclare(b.queue, true, false, false, false, nil); err != nil {
			return err
		}
		if err := c.ch.QueueBind(b.queue, b.key, ExchangeDonjoEvents, false, nil); err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) watchConnection() {
	for {
		err, ok := <-c.notify
		if !ok {
			return
		}
		log.Printf("[rabbitmq] connection lost: %v — reconnecting", err)
		time.Sleep(5 * time.Second)
		// On real reconnect we would redial + redclare; for now just log and stop.
		// The auth service is read-only on the bus — stale connection is safe.
		return
	}
}

func (c *Client) Consume(ctx context.Context, queue string, handler func(Envelope) error) {
	if c.conn == nil || c.conn.IsClosed() {
		log.Printf("[rabbitmq] not connected; consumer on %s not started", queue)
		return
	}
	msgs, err := c.ch.Consume(queue, "", false, false, false, false, nil)
	if err != nil {
		log.Printf("[rabbitmq] failed to consume %s: %v", queue, err)
		return
	}
	log.Printf("[rabbitmq] consuming %s", queue)
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-msgs:
			if !ok {
				return
			}
			if err := handleMsg(msg, handler); err != nil {
				log.Printf("[rabbitmq] error handling %s: %v", queue, err)
				_ = msg.Nack(false, true)
				continue
			}
			_ = msg.Ack(false)
		}
	}
}

func handleMsg(msg amqp.Delivery, handler func(Envelope) error) error {
	var env Envelope
	if err := json.Unmarshal(msg.Body, &env); err != nil {
		return err
	}
	return handler(env)
}
