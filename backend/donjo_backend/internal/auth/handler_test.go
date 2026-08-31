package auth

import (
	"bytes"
	"encoding/json"
	"image"
	"image/png"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func doUpload(t *testing.T, h *Handler, userID string) string {
	t.Helper()
	var body bytes.Buffer
	w := multipart.NewWriter(&body)
	fw, err := w.CreateFormFile("image", "avatar.png")
	if err != nil {
		t.Fatal(err)
	}
	if err := png.Encode(fw, image.NewRGBA(image.Rect(0, 0, 1, 1))); err != nil {
		t.Fatal(err)
	}
	if err := w.Close(); err != nil {
		t.Fatal(err)
	}

	req := httptest.NewRequest(http.MethodPost, "/me/profile-image", &body)
	req.Header.Set("Content-Type", w.FormDataContentType())

	rw := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(rw)
	c.Request = req
	c.Set(ContextUserID, userID)
	h.UploadProfileImage(c)
	if rw.Code != http.StatusOK {
		t.Fatalf("upload failed: %d %s", rw.Code, rw.Body.String())
	}
	return rw.Body.String()
}

func TestUploadProfileImage(t *testing.T) {
	gin.SetMode(gin.TestMode)
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	user := registerTestUser(t, svc, ctx)

	uploadDir := t.TempDir()
	h := NewHandler(svc, uploadDir, "http://localhost:8080")

	resp := doUpload(t, h, user.ID)

	var out struct {
		ProfileImage string `json:"profile_image"`
	}
	if err := json.Unmarshal([]byte(resp), &out); err != nil {
		t.Fatalf("unmarshal response %q: %v", resp, err)
	}
	if !strings.HasPrefix(out.ProfileImage, "http://localhost:8080/uploads/") ||
		!strings.HasSuffix(out.ProfileImage, ".png") {
		t.Fatalf("unexpected profile_image URL: %q", out.ProfileImage)
	}

	updated, err := svc.GetByID(ctx, user.ID)
	if err != nil {
		t.Fatal(err)
	}
	if updated.ProfileImage == nil || *updated.ProfileImage != out.ProfileImage {
		t.Fatalf("profile_image not persisted, got %v", updated.ProfileImage)
	}

	name := strings.TrimPrefix(out.ProfileImage, "http://localhost:8080/uploads/")
	if _, err := os.Stat(filepath.Join(uploadDir, name)); err != nil {
		t.Fatalf("expected file on disk, got: %v", err)
	}
}

func TestUploadProfileImageReplacesOldFile(t *testing.T) {
	gin.SetMode(gin.TestMode)
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	user := registerTestUser(t, svc, ctx)

	uploadDir := t.TempDir()
	h := NewHandler(svc, uploadDir, "http://localhost:8080")

	first := doUpload(t, h, user.ID)
	entries, _ := os.ReadDir(uploadDir)
	if len(entries) != 1 {
		t.Fatalf("expected 1 file after first upload, got %d", len(entries))
	}

	second := doUpload(t, h, user.ID)
	entries, _ = os.ReadDir(uploadDir)
	if len(entries) != 1 {
		t.Fatalf("expected 1 file after replacement (old removed), got %d", len(entries))
	}
	if first == second {
		t.Fatal("expected a new filename on replacement")
	}
}

func TestUploadProfileImageRejectsMissingFile(t *testing.T) {
	gin.SetMode(gin.TestMode)
	svc, ctx := newTestService(t, "../../migrations/001_auth_schema.up.sql")
	user := registerTestUser(t, svc, ctx)

	h := NewHandler(svc, t.TempDir(), "http://localhost:8080")

	req := httptest.NewRequest(http.MethodPost, "/me/profile-image", bytes.NewReader([]byte("no file")))
	req.Header.Set("Content-Type", "multipart/form-data; boundary=xyz")

	rw := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(rw)
	c.Request = req
	c.Set(ContextUserID, user.ID)
	h.UploadProfileImage(c)

	if rw.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for missing file, got %d", rw.Code)
	}
}
