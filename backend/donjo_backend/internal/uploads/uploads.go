package uploads

import (
	"fmt"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"donjo_backend/internal/security"
)

const MaxImageBytes = 5 << 20

var allowedTypes = map[string]string{
	"image/jpeg": ".jpg",
	"image/png":  ".png",
	"image/webp": ".webp",
	"image/gif":  ".gif",
}

func Save(file multipart.File, dir string) (string, error) {
	data := make([]byte, 512)
	n, err := file.Read(data)
	if err != nil && n == 0 {
		return "", fmt.Errorf("read upload: %w", err)
	}
	ctype := http.DetectContentType(data[:n])
	ext, ok := allowedTypes[ctype]
	if !ok {
		return "", fmt.Errorf("unsupported image type %q", ctype)
	}

	if _, err := file.Seek(0, 0); err != nil {
		return "", fmt.Errorf("rewind upload: %w", err)
	}

	if err := os.MkdirAll(dir, 0o750); err != nil {
		return "", fmt.Errorf("create upload dir: %w", err)
	}

	token, err := security.RandomToken(16)
	if err != nil {
		return "", err
	}
	name := token + ext
	dstPath := filepath.Join(dir, name)
	if err := writeTo(dstPath, file); err != nil {
		return "", err
	}

	return "/uploads/" + name, nil
}

func writeTo(path string, file multipart.File) error {
	dst, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o640)
	if err != nil {
		return fmt.Errorf("open upload destination: %w", err)
	}
	defer dst.Close()
	if _, err := dst.ReadFrom(file); err != nil {
		return fmt.Errorf("write upload: %w", err)
	}
	return nil
}

func PublicURL(base, urlPath string) string {
	return strings.TrimRight(base, "/") + urlPath
}

func Remove(dir, urlPath string) error {
	name := strings.TrimPrefix(urlPath, "/uploads/")
	if name == "" || strings.Contains(name, "/") || strings.Contains(name, "..") {
		return nil
	}
	p := filepath.Join(dir, filepath.Base(name))
	if err := os.Remove(p); err != nil && !os.IsNotExist(err) {
		return err
	}
	return nil
}
