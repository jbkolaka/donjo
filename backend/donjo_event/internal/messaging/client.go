package messaging

import (
	"context"
	"log"
	"os"
	"sync"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type consumerRegistration struct {
	queue   string
	handler func(Envelope) error
}

type Client struct {
	mu     sync.Mutex
	conn   *amqp.Connection
	ch     *amqp.Channel
	url    string
	closed bool

	notifyClose chan *amqp.Error

	consumers []consumerRegistration
	consumeCtx context.Context
}

func NewClient() *Client {
	url := os.Getenv("RABBITMQ_URL")
	if url == "" {
		url = "amqp://guest:guest@localhost:5672/"
	}
	return &Client{url: url, notifyClose: make(chan *amqp.Error, 1)}
}

// Start launches the background connection loop. It does not block: the HTTP
// server serves immediately and messaging comes online once RabbitMQ is up.
func (c *Client) Start() {
	go c.connectLoop()
}

// connectLoop is the single place that (re)establishes the connection and then
// watches it, so both the initial connect and reconnects share the same glue.
func (c *Client) connectLoop() {
	backoff := 1 * time.Second
	for {
		if c.isClosed() {
			return
		}
		if err := c.connect(); err != nil {
			log.Printf("[rabbitmq] connection failed: %v — retrying in %s", err, backoff)
			select {
			case <-time.After(backoff):
			}
			if backoff < 30*time.Second {
				backoff *= 2
			}
			continue
		}
		backoff = 5 * time.Second
		c.watchConnection()
	}
}

// connect performs a single dial + channel + topology setup.
func (c *Client) connect() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.closed {
		return ErrNotConnected
	}

	conn, err := amqp.Dial(c.url)
	if err != nil {
		return err
	}
	ch, err := conn.Channel()
	if err != nil {
		conn.Close()
		return err
	}
	if err := ch.Qos(50, 0, false); err != nil {
		log.Printf("[rabbitmq] failed to set prefetch: %v", err)
	}
	if err := c.declareTopology(ch); err != nil {
		ch.Close()
		conn.Close()
		return err
	}

	c.conn = conn
	c.ch = ch
	c.notifyClose = conn.NotifyClose(make(chan *amqp.Error, 1))

	log.Printf("[rabbitmq] connected to %s", c.url)

	// (Re)start consumers so they survive reconnect cycles.
	for _, reg := range c.consumers {
		go c.consumeLoop(reg)
	}

	return nil
}

func (c *Client) declareTopology(ch *amqp.Channel) error {
	if err := ch.ExchangeDeclare(
		ExchangeDonjoEvents,
		"topic",
		true,
		false,
		false,
		false,
		nil,
	); err != nil {
		return err
	}

	type binding struct {
		queue string
		keys  []string
	}
	bindings := []binding{
		{QueueEventCatalog, []string{KeyEventCreated, KeyEventUpdated, KeyEventDeleted, KeyEventPublished}},
		{QueueTicketSales, []string{KeyTicketReserved, KeyTicketPurchased, KeyTicketSaleReleased}},
		{QueueAuthSync, []string{KeyTicketPurchased, KeyEventDeleted}},
		{QueueFanout, []string{"#"}},
	}

	for _, b := range bindings {
		if _, err := ch.QueueDeclare(b.queue, true, false, false, false, nil); err != nil {
			return err
		}
		if b.queue == QueueFanout {
			if err := ch.QueueBind(b.queue, "#", ExchangeDonjoEvents, false, nil); err != nil {
				return err
			}
			continue
		}
		for _, k := range b.keys {
			if err := ch.QueueBind(b.queue, k, ExchangeDonjoEvents, false, nil); err != nil {
				return err
			}
		}
	}
	return nil
}

// watchConnection blocks while the connection is healthy, then returns so the
// connectLoop can re-establish it.
func (c *Client) watchConnection() {
	for {
		if c.isClosed() {
			return
		}
		err, ok := <-c.notifyClose
		if !ok {
			return
		}
		log.Printf("[rabbitmq] connection lost: %v — reconnecting", err)
		return
	}
}

// Publish publishes an envelope to the donjo.events topic exchange.
// It is best-effort: if the connection is down the message is dropped and logged.
func (c *Client) Publish(routingKey string, envelope Envelope) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.closed || c.conn == nil || c.ch == nil || c.conn.IsClosed() {
		log.Printf("[rabbitmq] skip publish %s: not connected", routingKey)
		return nil
	}
	if envelope.ID == "" {
		envelope.ID = newUUID()
	}
	if envelope.Type == "" {
		envelope.Type = routingKey
	}
	if envelope.Key == "" {
		envelope.Key = routingKey
	}
	if envelope.Timestamp.IsZero() {
		envelope.Timestamp = time.Now().UTC()
	}

	body, err := marshalEnvelope(envelope)
	if err != nil {
		return err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	return c.ch.PublishWithContext(
		ctx,
		ExchangeDonjoEvents,
		routingKey,
		false,
		false,
		amqp.Publishing{
			ContentType:  "application/json",
			DeliveryMode: amqp.Persistent,
			Timestamp:    envelope.Timestamp,
			Body:         body,
		},
	)
}

// RegisterConsumer stores a consumer handler so it can be (re)started
// whenever the connection comes up.
func (c *Client) RegisterConsumer(queue string, handler func(Envelope) error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.consumers = append(c.consumers, consumerRegistration{queue: queue, handler: handler})
}

// consumeLoop runs the blocking Consume for a registration.
func (c *Client) consumeLoop(reg consumerRegistration) {
	for {
		if c.isClosed() {
			return
		}
		c.mu.Lock()
		connected := !c.closed && c.conn != nil && c.ch != nil && !c.conn.IsClosed()
		ch := c.ch
		c.mu.Unlock()
		if !connected {
			return
		}
		err := CConsume(ch, reg.queue, reg.handler, c.consumeCtx)
		if err != nil {
			log.Printf("[rabbitmq] consumer on %s stopped: %v", reg.queue, err)
			return
		}
	}
}

func (c *Client) isClosed() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.closed
}

func (c *Client) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.closed = true
	if c.ch != nil {
		_ = c.ch.Close()
	}
	if c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

func (c *Client) IsConnected() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return !c.closed && c.conn != nil && c.ch != nil && !c.conn.IsClosed()
}