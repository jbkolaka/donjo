package security

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"os"
	"strings"
)

var (
	ErrInvalidCiphertext = errors.New("invalid ciphertext")
	ErrInvalidKey        = errors.New("invalid security key length")
)

func Field(plaintext string) (string, error) {
	key, err := encKey()
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return "", err
	}

	sealed := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(sealed), nil
}

func Fingerprint(plaintext string) (string, error) {
	key, err := indexKey()
	if err != nil {
		return "", err
	}

	mac := hmac.New(sha256.New, key)
	mac.Write([]byte(strings.ToLower(strings.TrimSpace(plaintext))))
	return hex.EncodeToString(mac.Sum(nil)), nil
}

func RandomToken(byteLength int) (string, error) {
	if byteLength <= 0 {
		byteLength = 32
	}
	buf := make([]byte, byteLength)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func TokenHash(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func Decrypt(encoded string) (string, error) {
	key, err := encKey()
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	data, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return "", ErrInvalidCiphertext
	}
	if len(data) < gcm.NonceSize() {
		return "", ErrInvalidCiphertext
	}

	nonce, ciphertext := data[:gcm.NonceSize()], data[gcm.NonceSize():]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", ErrInvalidCiphertext
	}

	return string(plaintext), nil
}

func encKey() ([]byte, error) {
	return keyFromEnv("DATA_ENCRYPTION_KEY", 32)
}

func indexKey() ([]byte, error) {
	return keyFromEnv("DATA_INDEX_KEY", 32)
}

func keyFromEnv(name string, size int) ([]byte, error) {
	val := os.Getenv(name)
	if val == "" {
		return nil, errors.New("missing required security key: " + name)
	}
	key, err := hex.DecodeString(val)
	if err != nil || len(key) != size {
		return nil, ErrInvalidKey
	}
	return key, nil
}
