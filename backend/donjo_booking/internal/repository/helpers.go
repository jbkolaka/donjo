package repository

import (
	"database/sql"
	"encoding/json"
	"time"
)

var nullTimeValue = time.Time{}

func scanStrings(v sql.NullString) []string {
	if !v.Valid || v.String == "" {
		return nil
	}
	var out []string
	if err := json.Unmarshal([]byte(v.String), &out); err != nil {
		return nil
	}
	return out
}

func mustTime(s string) time.Time {
	if s == "" {
		return time.Time{}
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		if t2, err2 := time.Parse("2006-01-02 15:04:05", s); err2 == nil {
			return t2
		}
		return time.Time{}
	}
	return t
}

func scanTime(v sql.NullString) *time.Time {
	if !v.Valid || v.String == "" {
		return nil
	}
	t, err := time.Parse(time.RFC3339, v.String)
	if err != nil {
		if t2, err2 := time.Parse("2006-01-02 15:04:05", v.String); err2 == nil {
			return &t2
		}
		return nil
	}
	return &t
}

func intPtrIf(valid bool, n int) *int {
	if !valid {
		return nil
	}
	return &n
}

func nullStr(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

func jsonStr(v interface{}) interface{} {
	if v == nil {
		return nil
	}
	b, err := json.Marshal(v)
	if err != nil {
		return nil
	}
	return string(b)
}

func boolInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

func fmtTime(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.Format(time.RFC3339)
}

func fmtTimePtr(t *time.Time) interface{} {
	if t == nil {
		return nil
	}
	return t.Format(time.RFC3339)
}

func intVal(p *int) interface{} {
	if p == nil {
		return nil
	}
	return *p
}

type queryer interface {
	QueryRow(query string, args ...interface{}) *sql.Row
}

func newID(db queryer) (string, error) {
	var id string
	err := db.QueryRow(`SELECT lower(hex(randomblob(16)))`).Scan(&id)
	return id, err
}
