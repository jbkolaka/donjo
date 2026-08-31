package mailer

import (
	"crypto/tls"
	"errors"
	"fmt"
	"log"
	"net"
	"net/smtp"
	"os"
	"strings"
)

type Sender interface {
	Send(to, subject, body string) error
}

type Mailer struct {
	host     string
	port     string
	username string
	password string
	from     string

	noop bool
}

func New() *Mailer {
	host := os.Getenv("SMTP_HOST")
	port := os.Getenv("SMTP_PORT")
	if port == "" {
		port = "587"
	}
	return &Mailer{
		host:     host,
		port:     port,
		username: os.Getenv("SMTP_USER"),
		password: os.Getenv("SMTP_PASS"),
		from:     os.Getenv("SMTP_FROM"),
		noop:     strings.TrimSpace(host) == "",
	}
}

func (m *Mailer) Send(to, subject, body string) error {
	if m == nil || m.noop {
		log.Printf("[mailer:noop] to=%s subject=%q body=%q", to, subject, body)
		return nil
	}
	if m.from == "" {
		return errors.New("mailer: SMTP_FROM is required when SMTP_HOST is set")
	}

	addr := net.JoinHostPort(m.host, m.port)
	msg := []byte("From: " + m.from + "\r\n" +
		"To: " + to + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/plain; charset=UTF-8\r\n" +
		"\r\n" + body + "\r\n")

	var auth smtp.Auth
	if m.username != "" {
		auth = smtp.PlainAuth("", m.username, m.password, m.host)
	}

	if err := m.sendWithTLS(addr, auth, m.from, []string{to}, msg); err != nil {
		return m.sendPlain(addr, auth, m.from, []string{to}, msg)
	}
	return nil
}

func (m *Mailer) sendWithTLS(addr string, auth smtp.Auth, from string, to []string, msg []byte) error {
	c, err := smtp.Dial(addr)
	if err != nil {
		return err
	}
	defer c.Close()
	if ok, _ := c.Extension("STARTTLS"); ok {
		if err := c.StartTLS(&tls.Config{ServerName: m.host}); err != nil {
			return err
		}
	}
	return m.send(c, auth, from, to, msg)
}

func (m *Mailer) sendPlain(addr string, auth smtp.Auth, from string, to []string, msg []byte) error {
	c, err := smtp.Dial(addr)
	if err != nil {
		return err
	}
	defer c.Close()
	return m.send(c, auth, from, to, msg)
}

func (m *Mailer) send(c *smtp.Client, auth smtp.Auth, from string, to []string, msg []byte) error {
	if err := c.Mail(from); err != nil {
		return fmt.Errorf("mailer: MAIL: %w", err)
	}
	for _, addr := range to {
		if err := c.Rcpt(addr); err != nil {
			return fmt.Errorf("mailer: RCPT %s: %w", addr, err)
		}
	}
	w, err := c.Data()
	if err != nil {
		return fmt.Errorf("mailer: DATA: %w", err)
	}
	if _, err := w.Write(msg); err != nil {
		return fmt.Errorf("mailer: write body: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("mailer: close data: %w", err)
	}
	return c.Quit()
}
