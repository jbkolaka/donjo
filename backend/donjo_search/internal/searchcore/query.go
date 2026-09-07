package searchcore

// Query building for the /events endpoint. The parameterized multi_match
// query is assembled here so the HTTP handler stays thin.

// Filters are the user-supplied query clauses. Zero values are ignored.
type Filters struct {
	Q           string // free text across title/description/category/tags
	Category    string // exact category
	City        string // exact city
	Country     string // exact country
	EventType   string // physical / virtual / ...
	IsVirtual   *bool
	MinPrice    *float64
	MaxPrice    *float64
	MinCapacity *int
	DateFrom    string // RFC3339
	DateTo      string // RFC3339
	Status      string // default published
	Sort        string // relevance | date | price_asc | price_desc
	Page, Size  int
}

// PageSize clamps the requested page size into sane bounds.
func (f Filters) pageSize() int {
	if f.Size <= 0 {
		return 20
	}
	if f.Size > 100 {
		return 100
	}
	return f.Size
}

func (f Filters) from() int {
	if f.Page <= 0 {
		f.Page = 1
	}
	return (f.Page - 1) * f.pageSize()
}

// BuildEventQuery converts filters into an ES QueryDSL body for the events
// index.
func (f Filters) BuildEventQuery() map[string]interface{} {
	boolQ := map[string]interface{}{
		"filter": []interface{}{},
	}
	must := []interface{}{}

	if f.Q != "" {
		must = append(must, map[string]interface{}{
			"multi_match": map[string]interface{}{
				"query":  f.Q,
				"fields": []string{"title^4", "description^1.5", "short_description^2", "category^2", "sub_category", "tags", "venue_name", "location", "organizer_name"},
				"type":   "best_fields",
			},
		})
	}

	filters := []interface{}{}
	// Only published, not private events by default.
	status := f.Status
	if status == "" {
		status = "published"
	}
	filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"status": status}})
	filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"is_published": true}})
	filters = append(filters, map[string]interface{}{"range": map[string]interface{}{"end_time": map[string]interface{}{"gte": "now"}}})

	if f.Category != "" {
		filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"category": f.Category}})
	}
	if f.City != "" {
		filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"city": f.City}})
	}
	if f.Country != "" {
		filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"country": f.Country}})
	}
	if f.EventType != "" {
		filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"event_type": f.EventType}})
	}
	if f.IsVirtual != nil {
		filters = append(filters, map[string]interface{}{"term": map[string]interface{}{"is_virtual": *f.IsVirtual}})
	}
	if f.MinPrice != nil || f.MaxPrice != nil {
		rng := map[string]interface{}{"range": map[string]interface{}{"min_ticket_price": map[string]interface{}{}}}
		inner := rng["range"].(map[string]interface{})["min_ticket_price"].(map[string]interface{})
		if f.MinPrice != nil {
			inner["gte"] = *f.MinPrice
		}
		if f.MaxPrice != nil {
			inner["lte"] = *f.MaxPrice
		}
		filters = append(filters, rng)
	}
	if f.MinCapacity != nil {
		rng := map[string]interface{}{"range": map[string]interface{}{"total_capacity": map[string]interface{}{"gte": *f.MinCapacity}}}
		filters = append(filters, rng)
	}
	if f.DateFrom != "" || f.DateTo != "" {
		rng := map[string]interface{}{"range": map[string]interface{}{"start_time": map[string]interface{}{}}}
		inner := rng["range"].(map[string]interface{})["start_time"].(map[string]interface{})
		if f.DateFrom != "" {
			inner["gte"] = f.DateFrom
		}
		if f.DateTo != "" {
			inner["lte"] = f.DateTo
		}
		filters = append(filters, rng)
	}
	if len(must) > 0 {
		boolQ["must"] = must
	}
	boolQ["filter"] = filters

	body := map[string]interface{}{
		"from":  f.from(),
		"size":  f.pageSize(),
		"query": map[string]interface{}{"bool": boolQ},
	}

	if sort := f.sortClause(); sort != nil {
		body["sort"] = sort
	}

	return body
}

func (f Filters) sortClause() []interface{} {
	switch f.Sort {
	case "date":
		return []interface{}{map[string]interface{}{"start_time": "asc"}}
	case "price_asc":
		return []interface{}{map[string]interface{}{"min_ticket_price": "asc"}}
	case "price_desc":
		return []interface{}{map[string]interface{}{"min_ticket_price": "desc"}}
	case "relevance":
		return []interface{}{"_score"}
	default:
		return nil
	}
}
