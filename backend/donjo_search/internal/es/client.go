package es

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// Client is a minimal Elasticsearch REST client. It talks to a single
// node via plain JSON over HTTP and deliberately wraps only the handful of
// operations the search service needs (index, update, delete, search,
// health) so the write path stays transparent.
type Client struct {
	base    string
	user    string
	pass    string
	http    *http.Client
	indices map[string]string // index name -> mapping json (managed)
}

// New builds a client for a single-node Elasticsearch endpoint, e.g.
// http://localhost:9200. user/pass may be empty when security is disabled.
func New(endpoint, username, password string) *Client {
	return &Client{
		base: strings.TrimRight(endpoint, "/"),
		user: username,
		pass: password,
		http: &http.Client{Timeout: 10 * time.Second},
	}
}

// Indexes returns the managed index names in order.
func (c *Client) Indexes() []string {
	out := make([]string, 0, len(c.indices))
	for name := range c.indices {
		out = append(out, name)
	}
	return out
}

// Manage declares an index (and its startup mapping) as part of this client.
func (c *Client) Manage(index, mapping string) *Client {
	if c.indices == nil {
		c.indices = map[string]string{}
	}
	c.indices[index] = mapping
	return c
}

// Ping health-checks the cluster.
func (c *Client) Ping(ctx context.Context) (map[string]string, error) {
	resp, err := c.do(ctx, http.MethodGet, "/_cluster/health", nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var out struct {
		Status string `json:"status"`
		Number int    `json:"number_of_nodes"`
	}
	if err := decode(resp, &out); err != nil {
		return nil, err
	}
	return map[string]string{
		"status":          out.Status,
		"cluster_status":  out.Status,
		"number_of_nodes": strconv.Itoa(out.Number),
	}, nil
}

// EnsureIndices creates any managed index that does not yet exist (PUT with
// create=true), applying the startup mappings and custom analyzers.
func (c *Client) EnsureIndices(ctx context.Context) error {
	for name, mapping := range c.indices {
		exists, err := c.indexExists(ctx, name)
		if err != nil {
			return err
		}
		if exists {
			continue
		}
		// ES 8 dropped the ?create=true flag; the HEAD existence check above
		// already guarantees we only PUT a brand-new index.
		resp, err := c.do(ctx, http.MethodPut, "/"+url.PathEscape(name), []byte(mapping))
		if err != nil {
			return err
		}
		defer resp.Body.Close()
		if resp.StatusCode >= 400 {
			b, _ := io.ReadAll(resp.Body)
			return fmt.Errorf("create index %s: %s", name, string(b))
		}
	}
	return nil
}

func (c *Client) indexExists(ctx context.Context, name string) (bool, error) {
	resp, err := c.do(ctx, http.MethodHead, "/"+url.PathEscape(name), nil)
	if err != nil {
		return false, err
	}
	resp.Body.Close()
	return resp.StatusCode == http.StatusOK, nil
}

// Index writes or replaces the document at id.
func (c *Client) Index(ctx context.Context, index, id string, doc interface{}) error {
	body, err := json.Marshal(doc)
	if err != nil {
		return err
	}
	resp, err := c.do(ctx, http.MethodPut, "/"+url.PathEscape(index)+"/_doc/"+url.PathEscape(id), body)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("index %s/%s: %s", index, id, string(b))
	}
	return nil
}

// Update applies a partial doc (POST /<index>/_update/<id> with {doc: ...}),
// creating the document on first sight via upsert.
func (c *Client) Update(ctx context.Context, index, id string, doc map[string]interface{}) error {
	body, err := json.Marshal(map[string]interface{}{"doc": doc, "doc_as_upsert": true})
	if err != nil {
		return err
	}
	resp, err := c.do(ctx, http.MethodPost, "/"+url.PathEscape(index)+"/_update/"+url.PathEscape(id), body)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("update %s/%s: %s", index, id, string(b))
	}
	return nil
}

// ScriptUpdate runs a painless script against a document (POST
// /<index>/_update/<id> with {script: {lang/source/params}, upsert:{}}). An
// empty upsert lets a script apply to a document that may not exist yet
// without erroring.
func (c *Client) ScriptUpdate(ctx context.Context, index, id, source string, params map[string]interface{}) error {
	if params == nil {
		params = map[string]interface{}{}
	}
	p := map[string]interface{}{
		"script": map[string]interface{}{
			"source": source,
			"params": params,
		},
		"upsert": map[string]interface{}{},
	}
	body, err := json.Marshal(p)
	if err != nil {
		return err
	}
	resp, err := c.do(ctx, http.MethodPost, "/"+url.PathEscape(index)+"/_update/"+url.PathEscape(id), body)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("script update %s/%s: %s", index, id, string(b))
	}
	return nil
}

// UpdateByQuery runs an _update_by_query over index, applying a script to every
// doc matching queryBody. Used for cross-doc re-syncs (e.g. flipping
// event_is_published on all ticket docs for one event).
func (c *Client) UpdateByQuery(ctx context.Context, index string, queryBody map[string]interface{}) error {
	body, err := json.Marshal(queryBody)
	if err != nil {
		return err
	}
	resp, err := c.do(ctx, http.MethodPost, "/"+url.PathEscape(index)+"/_update_by_query?refresh=true", body)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("update_by_query %s: %s", index, string(b))
	}
	return nil
}

// Delete removes the document at id (no-op when absent).
func (c *Client) Delete(ctx context.Context, index, id string) error {
	resp, err := c.do(ctx, http.MethodDelete, "/"+url.PathEscape(index)+"/_doc/"+url.PathEscape(id), nil)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 && resp.StatusCode != http.StatusNotFound {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("delete %s/%s: %s", index, id, string(b))
	}
	return nil
}

// Hit is a single search hit with its source.
type Hit struct {
	ID     string          `json:"_id"`
	Score  float64         `json:"_score"`
	Index  string          `json:"_index"`
	Source json.RawMessage `json:"_source"`
}

// Result is the slice of the _search response the API cares about.
type Result struct {
	Total int
	Hits  []Hit
}

// Search runs a QueryDSL body against one index.
func (c *Client) Search(ctx context.Context, index string, body map[string]interface{}) (*Result, error) {
	payload, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	resp, err := c.do(ctx, http.MethodPost, "/"+url.PathEscape(index)+"/_search", payload)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		b, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("search %s: %s", index, string(b))
	}
	var out struct {
		Hits struct {
			Total struct {
				Value int `json:"value"`
			} `json:"total"`
			Hits []Hit `json:"hits"`
		} `json:"hits"`
	}
	if err := decode(resp, &out); err != nil {
		return nil, err
	}
	if out.Hits.Hits == nil {
		out.Hits.Hits = []Hit{}
	}
	return &Result{Total: out.Hits.Total.Value, Hits: out.Hits.Hits}, nil
}

func (c *Client) do(ctx context.Context, method, path string, body []byte) (*http.Response, error) {
	var rd io.Reader
	if body != nil {
		rd = bytes.NewReader(body)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.base+path, rd)
	if err != nil {
		return nil, err
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.user != "" {
		req.SetBasicAuth(c.user, c.pass)
	}
	return c.http.Do(req)
}

func decode(resp *http.Response, v interface{}) error {
	return json.NewDecoder(resp.Body).Decode(v)
}
