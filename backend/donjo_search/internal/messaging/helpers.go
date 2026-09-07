package messaging

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
)

var ErrNotConnected = errors.New("rabbitmq not connected")

func marshalEnvelope(env Envelope) ([]byte, error) {
	return json.Marshal(env)
}

func unmarshalEnvelope(body []byte) (Envelope, error) {
	var env Envelope
	err := json.Unmarshal(body, &env)
	return env, err
}

func newUUID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return hex.EncodeToString(b)
}
