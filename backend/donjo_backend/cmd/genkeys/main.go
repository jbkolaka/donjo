package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
)

func main() {
	enc, err := randomHex(32)
	if err != nil {
		log.Fatal(err)
	}
	idx, err := randomHex(32)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Add these to your environment (.env):")
	fmt.Println()
	fmt.Println("DATA_ENCRYPTION_KEY=" + enc)
	fmt.Println("DATA_INDEX_KEY=" + idx)
}

func randomHex(n int) (string, error) {
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
