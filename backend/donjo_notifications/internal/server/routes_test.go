package server

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestHelloWorldHandler(t *testing.T) {
	s := &Server{}

	r := gin.New()
	r.GET("/", s.HelloWorldHandler)

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status OK; got %v", w.Code)
	}

	var body map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("error unmarshalling response body: %v", err)
	}
	if body["message"] != "Donjo Notification Service API" {
		t.Errorf("expected message 'Donjo Notification Service API'; got %q", body["message"])
	}
}