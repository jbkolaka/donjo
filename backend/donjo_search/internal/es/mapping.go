package es

// The three searchable read-model indices. Each doc is indexed with the full
// payload the source service published, so a hit can be rendered without
// calling back into the owning service.

// Room for the shared settings block.
const commonSettings = `"analysis":{
  "analyzer":{
    "asciifold":{"type":"custom","tokenizer":"standard","filter":["lowercase","asciifolding"]},
    "search_ngram":{"type":"custom","tokenizer":"standard","filter":["lowercase","asciifolding"]}
  }
}`

// text maps a human-searchable field: full-text with an lscii-folding
// analyzer plus a .keyword subfield for faceting/sorting.
func text() string {
	return `{"type":"text","analyzer":"asciifold","search_analyzer":"asciifold","fields":{"keyword":{"type":"keyword","ignore_above":256}}}`
}

func keyword() string {
	return `{"type":"keyword"}`
}

func integer() string {
	return `{"type":"integer"}`
}

func float() string {
	return `{"type":"float"}`
}

func boolean() string {
	return `{"type":"boolean"}`
}

func date() string {
	return `{"type":"date"}`
}

func ngram() string {
	return `{"type":"text","analyzer":"search_ngram","search_analyzer":"asciifold","fields":{"keyword":{"type":"keyword","ignore_above":256}}}`
}

// EventsMapping builds the donjo_events index mapping.
func EventsMapping() string {
	return `{
  "settings": { ` + commonSettings + ` },
  "mappings": {
    "properties": {
      "type": { "type": "constant_keyword", "value": "event" },
      "title": ` + text() + `,
      "slug": ` + keyword() + `,
      "short_description": ` + text() + `,
      "description": ` + text() + `,
      "category": ` + keyword() + `,
      "sub_category": ` + keyword() + `,
      "tags": ` + keyword() + `,
      "event_type": ` + keyword() + `,
      "is_virtual": ` + boolean() + `,
      "venue_name": ` + text() + `,
      "location": ` + text() + `,
      "address": ` + text() + `,
      "city": ` + keyword() + `,
      "county": ` + keyword() + `,
      "country": ` + keyword() + `,
      "coordinates": { "type": "geo_point" },
      "start_time": ` + date() + `,
      "end_time": ` + date() + `,
      "timezone": ` + keyword() + `,
      "total_capacity": ` + integer() + `,
      "available_tickets": ` + integer() + `,
      "min_ticket_price": ` + float() + `,
      "max_ticket_price": ` + float() + `,
      "is_free": ` + boolean() + `,
      "is_published": ` + boolean() + `,
      "status": ` + keyword() + `,
      "is_private": ` + boolean() + `,
      "invite_only": ` + boolean() + `,
      "organizer_name": ` + text() + `,
      "creator_id": ` + keyword() + `,
      "views": ` + integer() + `,
      "likes": ` + integer() + `,
      "tickets_sold": ` + integer() + `,
      "revenue": ` + float() + `,
      "tickets": {
        "type": "nested",
        "properties": {
          "id": ` + keyword() + `,
          "name": ` + text() + `,
          "type": ` + keyword() + `,
          "price": ` + float() + `,
          "quantity": ` + integer() + `,
          "sold": ` + integer() + `,
          "reserved": ` + integer() + `,
          "availability": ` + integer() + `,
          "is_active": ` + boolean() + `,
          "is_hidden": ` + boolean() + `,
          "sales_start": ` + date() + `,
          "sales_end": ` + date() + `
        }
      },
      "created_at": ` + date() + `,
      "updated_at": ` + date() + `
    }
  }
}`
}

// TicketsMapping builds the donjo_tickets index mapping.
func TicketsMapping() string {
	return `{
  "settings": { ` + commonSettings + ` },
  "mappings": {
    "properties": {
      "type": { "type": "constant_keyword", "value": "ticket" },
      "name": ` + text() + `,
      "description": ` + text() + `,
      "tier": ` + keyword() + `,
      "price": ` + float() + `,
      "original_price": ` + float() + `,
      "service_fee": ` + float() + `,
      "processing_fee": ` + float() + `,
      "quantity": ` + integer() + `,
      "sold": ` + integer() + `,
      "reserved": ` + integer() + `,
      "availability": ` + integer() + `,
      "is_active": ` + boolean() + `,
      "is_hidden": ` + boolean() + `,
      "is_transferable": ` + boolean() + `,
      "is_refundable": ` + boolean() + `,
      "requires_id_check": ` + boolean() + `,
      "event_id": ` + keyword() + `,
      "event_title": ` + text() + `,
      "event_slug": ` + keyword() + `,
      "event_category": ` + keyword() + `,
      "event_city": ` + keyword() + `,
      "event_start_time": ` + date() + `,
      "event_is_published": ` + boolean() + `,
      "created_at": ` + date() + `,
      "updated_at": ` + date() + `
    }
  }
}`
}

// VenuesMapping builds the donjo_venues index mapping.
func VenuesMapping() string {
	return `{
  "settings": { ` + commonSettings + ` },
  "mappings": {
    "properties": {
      "type": { "type": "constant_keyword", "value": "venue" },
      "name": ` + ngram() + `,
      "slug": ` + keyword() + `,
      "description": ` + text() + `,
      "short_description": ` + text() + `,
      "venue_type": ` + keyword() + `,
      "venue_category": ` + keyword() + `,
      "address": ` + text() + `,
      "city": ` + keyword() + `,
      "county": ` + keyword() + `,
      "country": ` + keyword() + `,
      "coordinates": { "type": "geo_point" },
      "amenities": ` + keyword() + `,
      "capacity": ` + integer() + `,
      "base_price": ` + float() + `,
      "pricing_type": ` + keyword() + `,
      "is_available": ` + boolean() + `,
      "status": ` + keyword() + `,
      "rating": ` + float() + `,
      "review_count": ` + integer() + `,
      "events_hosted": ` + integer() + `,
      "creator_id": ` + keyword() + `,
      "created_at": ` + date() + `,
      "updated_at": ` + date() + `
    }
  }
}`
}
