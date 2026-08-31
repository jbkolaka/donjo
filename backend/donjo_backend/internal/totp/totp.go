package totp

import (
	"crypto/hmac"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/base32"
	"encoding/binary"
	"fmt"
	"hash"
	"math"
	"strings"
	"time"
)

const (
	DefaultPeriod = 30
	DefaultDigits = 6
	DefaultIssuer = "Donjo"
)

type HashFunc func() hash.Hash

const (
	AlgSHA1   = "SHA1"
	AlgSHA256 = "SHA256"
	AlgSHA512 = "SHA512"
)

func hashFor(alg string) (HashFunc, error) {
	switch strings.ToUpper(alg) {
	case AlgSHA1:
		return sha1.New, nil
	case AlgSHA256:
		return sha256.New, nil
	case AlgSHA512:
		return sha512.New, nil
	default:
		return nil, fmt.Errorf("unsupported algorithm: %s", alg)
	}
}

func AccountName(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func URL(secret, email, issuer string) (string, error) {
	if issuer == "" {
		issuer = DefaultIssuer
	}
	base32Secret := strings.ToUpper(secret)

	scheme := "otpauth"
	host := "totp"
	label := AccountName(email)

	label = strings.ReplaceAll(label, ":", "%3A")
	issuerEnc := strings.ReplaceAll(issuer, ":", "%3A")

	params := fmt.Sprintf("secret=%s&issuer=%s&algorithm=%s&digits=%d&period=%d",
		base32Secret, issuerEnc, AlgSHA1, DefaultDigits, DefaultPeriod)

	return fmt.Sprintf("%s://%s/%s?%s", scheme, host, label, params), nil
}

func GenerateSecret(byteLength int) (string, error) {
	if byteLength <= 0 {
		byteLength = 20
	}
	raw := randomBytes(byteLength)
	return strings.ToUpper(base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(raw)), nil
}

func Code(secret string, t time.Time, alg string, digits, period int) (string, error) {
	if period <= 0 {
		period = DefaultPeriod
	}
	if digits <= 0 {
		digits = DefaultDigits
	}

	h, err := hashFor(alg)
	if err != nil {
		return "", err
	}

	key, err := decodeSecret(secret)
	if err != nil {
		return "", err
	}

	counter := uint64(t.Unix() / int64(period))
	code, err := hmacCode(h, key, counter, digits)
	if err != nil {
		return "", err
	}
	return code, nil
}

func Validate(secret, candidate string, t time.Time, skew int) (bool, error) {
	candidate = strings.TrimSpace(candidate)
	for step := -skew; step <= skew; step++ {
		check := t.Add(time.Duration(step) * DefaultPeriod * time.Second)
		code, err := Code(secret, check, AlgSHA1, DefaultDigits, DefaultPeriod)
		if err != nil {
			return false, err
		}
		if constantTimeEquals(code, candidate) {
			return true, nil
		}
	}
	return false, nil
}

func hmacCode(h HashFunc, key []byte, counter uint64, digits int) (string, error) {
	mac := hmac.New(h, key)
	var buf [8]byte
	binary.BigEndian.PutUint64(buf[:], counter)
	mac.Write(buf[:])
	sum := mac.Sum(nil)

	offset := sum[len(sum)-1] & 0x0f
	binaryVal := (uint32(sum[offset])&0x7f)<<24 |
		(uint32(sum[offset+1])&0xff)<<16 |
		(uint32(sum[offset+2])&0xff)<<8 |
		(uint32(sum[offset+3]) & 0xff)

	mod := uint32(math.Pow(10, float64(digits)))
	code := binaryVal % mod
	fmtStr := "%0" + fmt.Sprintf("%d", digits) + "d"
	return fmt.Sprintf(fmtStr, code), nil
}

func decodeSecret(secret string) ([]byte, error) {
	s := strings.ToUpper(strings.TrimSpace(secret))
	s = strings.ReplaceAll(s, " ", "")
	s = strings.ReplaceAll(s, "-", "")
	return base32.StdEncoding.WithPadding(base32.NoPadding).DecodeString(s)
}

func constantTimeEquals(a, b string) bool {
	if len(a) != len(b) {
		return false
	}
	var v byte
	for i := 0; i < len(a); i++ {
		v |= a[i] ^ b[i]
	}
	return v == 0
}
