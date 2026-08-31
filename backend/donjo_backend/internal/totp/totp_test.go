package totp

import (
	"encoding/base32"
	"strings"
	"testing"
	"time"
)

func TestRFC6238SHA1(t *testing.T) {
	secret := base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString([]byte("12345678901234567890"))

	vectors := []struct {
		unix   int64
		digits int
		want   string
	}{
		{59, 8, "94287082"},
		{1111111109, 8, "07081804"},
		{1111111111, 8, "14050471"},
		{1234567890, 8, "89005924"},
		{2000000000, 8, "69279037"},
		{20000000000, 8, "65353130"},
	}

	for _, v := range vectors {
		got, err := Code(secret, time.Unix(v.unix, 0), AlgSHA1, v.digits, 30)
		if err != nil {
			t.Fatalf("Code(%d): %v", v.unix, err)
		}
		if got != v.want {
			t.Errorf("Code(%d) = %s, want %s", v.unix, got, v.want)
		}
	}
}

func TestGoogleAuthenticator6Digit(t *testing.T) {
	secret, err := GenerateSecret(20)
	if err != nil {
		t.Fatal(err)
	}

	now := time.Now()
	code, err := Code(secret, now, AlgSHA1, DefaultDigits, DefaultPeriod)
	if err != nil {
		t.Fatal(err)
	}

	if len(code) != 6 {
		t.Fatalf("expected 6 digits, got %q", code)
	}
	for _, r := range code {
		if r < '0' || r > '9' {
			t.Fatalf("code contains non-digit: %q", code)
		}
	}

	if ok, err := Validate(secret, code, now, 1); err != nil || !ok {
		t.Fatalf("Validate() = %v, err=%v; want true", ok, err)
	}
	if ok, _ := Validate(secret, "000000", now, 1); ok {
		t.Fatalf("Validate() accepted wrong code")
	}
}

func TestGenerateSecretBase32(t *testing.T) {
	secret, err := GenerateSecret(20)
	if err != nil {
		t.Fatal(err)
	}
	allowed := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	for _, r := range secret {
		if !strings.ContainsRune(allowed, r) {
			t.Fatalf("secret contains invalid base32 char %q", r)
		}
	}
}

func TestURLFormat(t *testing.T) {
	secret, _ := GenerateSecret(20)
	url, err := URL(secret, "test@donjo.com", "Donjo")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(url, "otpauth://totp/test@donjo.com?") {
		t.Fatalf("unexpected url: %s", url)
	}
	if !strings.Contains(url, "secret=") || !strings.Contains(url, "issuer=Donjo") {
		t.Fatalf("url missing params: %s", url)
	}
	if !strings.Contains(url, "period=30") || !strings.Contains(url, "digits=6") {
		t.Fatalf("url missing totp params: %s", url)
	}
}

func TestValidateClockSkew(t *testing.T) {
	secret, _ := GenerateSecret(20)
	now := time.Now()

	past := now.Add(-time.Minute)
	pastCode, err := Code(secret, past, AlgSHA1, DefaultDigits, DefaultPeriod)
	if err != nil {
		t.Fatal(err)
	}
	if ok, _ := Validate(secret, pastCode, now, 1); ok {
		t.Fatalf("should not accept code outside skew")
	}
	if ok, _ := Validate(secret, pastCode, now, 2); !ok {
		t.Fatalf("should accept code within skew")
	}
}
