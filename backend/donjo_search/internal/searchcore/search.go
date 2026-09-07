package searchcore

import (
	"donjo_search/internal/es"
)

// SearchHit is the API-facing shape of one search result.
type SearchHit struct {
	ID     string         `json:"id"`
	Type   string         `json:"type"`
	Score  float64        `json:"score"`
	Source map[string]any `json:"source"`
}

// SearchResult is the merged page returned by the /search endpoint.
type SearchResult struct {
	Total int         `json:"total"`
	Page  int         `json:"page"`
	Size  int         `json:"size"`
	Hits  []SearchHit `json:"hits"`
}

// SearchEvents runs an events query.
func (s *SearchService) SearchEvents(f Filters) (*SearchResult, error) {
	res, err := s.es.Search(s.ctx, IndexEvents, f.BuildEventQuery())
	if err != nil {
		return nil, err
	}
	return toResult("event", f, res), nil
}

// SearchVenues runs a venues query (name + location match).
func (s *SearchService) SearchVenues(f Filters) (*SearchResult, error) {
	var must interface{}
	if f.Q != "" {
		must = []interface{}{
			map[string]interface{}{
				"multi_match": map[string]interface{}{
					"query":  f.Q,
					"fields": []string{"name^4", "city^2", "address", "description", "venue_type"},
					"type":   "best_fields",
				},
			},
		}
	} else {
		must = []interface{}{map[string]interface{}{"match_all": map[string]interface{}{}}}
	}
	body := map[string]interface{}{
		"from": f.from(),
		"size": f.pageSize(),
		"query": map[string]interface{}{
			"bool": map[string]interface{}{
				"must": must,
			},
		},
	}
	res, err := s.es.Search(s.ctx, IndexVenues, body)
	if err != nil {
		return nil, err
	}
	return toResult("venue", f, res), nil
}

// SearchTickets runs a ticket query (name + event context).
func (s *SearchService) SearchTickets(f Filters) (*SearchResult, error) {
	var must interface{}
	if f.Q != "" {
		must = []interface{}{
			map[string]interface{}{
				"multi_match": map[string]interface{}{
					"query":  f.Q,
					"fields": []string{"name^3", "event_title^4", "description"},
					"type":   "best_fields",
				},
			},
		}
	} else {
		must = []interface{}{map[string]interface{}{"match_all": map[string]interface{}{}}}
	}
	body := map[string]interface{}{
		"from": f.from(),
		"size": f.pageSize(),
		"query": map[string]interface{}{
			"bool": map[string]interface{}{
				"must": must,
				"filter": []interface{}{
					map[string]interface{}{"term": map[string]interface{}{"is_active": true}},
					map[string]interface{}{"range": map[string]interface{}{"availability": map[string]interface{}{"gt": 0}}},
				},
			},
		},
	}
	res, err := s.es.Search(s.ctx, IndexTickets, body)
	if err != nil {
		return nil, err
	}
	return toResult("ticket", f, res), nil
}

func toResult(kind string, f Filters, res *es.Result) *SearchResult {
	hits := make([]SearchHit, 0, len(res.Hits))
	for _, h := range res.Hits {
		var src map[string]any
		_ = jsonUnmarshal(h.Source, &src)
		hits = append(hits, SearchHit{ID: h.ID, Type: kind, Score: h.Score, Source: src})
	}
	page := f.Page
	if page <= 0 {
		page = 1
	}
	return &SearchResult{Total: res.Total, Page: page, Size: f.pageSize(), Hits: hits}
}
