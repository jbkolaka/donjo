package uploads

import (
	"bytes"
	"image"
	"image/png"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type inMemoryFile struct {
	data []byte
	off  int64
}

func (m *inMemoryFile) Read(p []byte) (int, error) {
	if m.off >= int64(len(m.data)) {
		return 0, io.EOF
	}
	n := copy(p, m.data[m.off:])
	m.off += int64(n)
	return n, nil
}

func (m *inMemoryFile) Seek(offset int64, whence int) (int64, error) {
	switch whence {
	case 0:
		m.off = offset
	case 1:
		m.off += offset
	case 2:
		m.off = int64(len(m.data)) + offset
	}
	return m.off, nil
}

func (m *inMemoryFile) ReadAt(p []byte, off int64) (int, error) {
	if off >= int64(len(m.data)) {
		return 0, os.ErrClosed
	}
	n := copy(p, m.data[off:])
	return n, nil
}

func (m *inMemoryFile) Close() error { return nil }

func tinyPNG(t *testing.T) []byte {
	t.Helper()
	var b bytes.Buffer
	if err := png.Encode(&b, image.NewRGBA(image.Rect(0, 0, 1, 1))); err != nil {
		t.Fatal(err)
	}
	return b.Bytes()
}

func TestSaveValidPNG(t *testing.T) {
	dir := t.TempDir()
	file := &inMemoryFile{data: tinyPNG(t)}
	urlPath, err := Save(file, dir)
	if err != nil {
		t.Fatalf("save: %v", err)
	}
	if !strings.HasPrefix(urlPath, "/uploads/") || !strings.HasSuffix(urlPath, ".png") {
		t.Fatalf("unexpected url path: %q", urlPath)
	}
	name := strings.TrimPrefix(urlPath, "/uploads/")
	if _, err := os.Stat(filepath.Join(dir, name)); err != nil {
		t.Fatalf("file not persisted: %v", err)
	}
}

func TestSaveRejectsUnsupportedType(t *testing.T) {
	dir := t.TempDir()
	svg := &inMemoryFile{data: []byte(`<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>`)}
	if _, err := Save(svg, dir); err == nil {
		t.Fatal("expected SVG upload to be rejected")
	}
	entries, _ := os.ReadDir(dir)
	if len(entries) != 0 {
		t.Fatalf("no file should have been written, got %d", len(entries))
	}
}

func TestPublicURL(t *testing.T) {
	if got := PublicURL("http://localhost:8080/", "/uploads/abc.png"); got != "http://localhost:8080/uploads/abc.png" {
		t.Fatalf("unexpected url: %q", got)
	}
	if got := PublicURL("", "/uploads/abc.png"); got != "/uploads/abc.png" {
		t.Fatalf("unexpected url with empty base: %q", got)
	}
}

func TestRemove(t *testing.T) {
	dir := t.TempDir()
	name := "abc123.png"
	if err := os.WriteFile(filepath.Join(dir, name), []byte("x"), 0o640); err != nil {
		t.Fatal(err)
	}
	if err := Remove(dir, "/uploads/"+name); err != nil {
		t.Fatalf("remove: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, name)); !os.IsNotExist(err) {
		t.Fatal("expected file to be removed")
	}

	esc := filepath.Join(dir, "..", "donjo-should-not-delete.png")
	if err := os.WriteFile(esc, []byte("y"), 0o640); err != nil {
		t.Fatal(err)
	}
	if err := Remove(dir, "/uploads/../../donjo-should-not-delete.png"); err != nil {
		t.Fatalf("remove traversal should not error, got %v", err)
	}
	if _, err := os.Stat(esc); err != nil {
		t.Fatal("file outside upload dir must not be removed")
	}
}
