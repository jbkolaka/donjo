package totp

import (
	"crypto/rand"
	"log"
)

func randomBytes(n int) []byte {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		log.Fatalf("failed to read random bytes: %v", err)
	}
	return b
}
