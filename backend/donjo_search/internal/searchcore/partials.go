package searchcore

import "encoding/json"

// These builders convert the donor-facing docs into the flat partial maps sent
// as {doc: {...}} to Elasticsearch. Keeping them as maps (not the struct)
// means only the fields we want are (over)written by _update, and fields like
// coordinates that must be embedded as a geo_point get the right shape.

func jsonUnmarshal(b []byte, v interface{}) error {
	return json.Unmarshal(b, v)
}

func (d *DocIn) eventPartial() map[string]interface{} {
	partial := map[string]interface{}{
		"type":              "event",
		"id":                d.ID,
		"creator_id":        d.CreatorID,
		"title":             d.Title,
		"slug":              d.Slug,
		"description":       d.Description,
		"short_description": d.ShortDescription,
		"category":          d.Category,
		"sub_category":      d.SubCategory,
		"tags":              d.Tags,
		"event_type":        d.EventType,
		"is_virtual":        d.IsVirtual,
		"virtual_link":      d.VirtualLink,
		"virtual_platform":  d.VirtualPlatform,
		"venue_id":          d.VenueID,
		"venue_name":        d.VenueName,
		"location":          d.Location,
		"address":           d.Address,
		"city":              d.City,
		"county":            d.County,
		"country":           d.Country,
		"start_time":        ts(d.StartTime),
		"end_time":          ts(d.EndTime),
		"timezone":          d.Timezone,
		"total_capacity":    d.TotalCapacity,
		"min_ticket_price":  d.MinTicketPrice,
		"max_ticket_price":  d.MaxTicketPrice,
		"is_free":           d.IsFree,
		"status":            d.Status,
		"is_published":      d.IsPublished,
		"is_private":        d.IsPrivate,
		"invite_only":       d.InviteOnly,
		"organizer_name":    d.OrganizerName,
		"views":             d.Views,
		"likes":             d.Likes,
		"tickets_sold":      d.TicketsSold,
		"revenue":           d.Revenue,
		"created_at":        ts(d.CreatedAt),
		"updated_at":        ts(d.UpdatedAt),
	}
	if d.Coordinates != nil {
		partial["coordinates"] = []float64{d.Coordinates.Longitude, d.Coordinates.Latitude}
	}
	// Aggregate availability from the nested tickets (informed zero).
	var avail int
	var minP, maxP float64
	var have bool
	nested := make([]map[string]interface{}, 0, len(d.Tickets))
	for _, t := range d.Tickets {
		if !t.IsActive || t.IsHidden {
			continue
		}
		avail += t.availability()
		if !have || t.Price < minP {
			minP = t.Price
		}
		if !have || t.Price > maxP {
			maxP = t.Price
		}
		have = true
		nested = append(nested, map[string]interface{}{
			"id":             t.ID,
			"name":           t.Name,
			"type":           t.Type,
			"tier":           t.Tier,
			"price":          t.Price,
			"service_fee":    t.ServiceFee,
			"processing_fee": t.ProcessingFee,
			"quantity":       t.Quantity,
			"sold":           t.Sold,
			"reserved":       t.Reserved,
			"availability":   t.availability(),
			"is_active":      t.IsActive,
			"is_hidden":      t.IsHidden,
			"sales_start":    ts(t.SalesStart),
			"sales_end":      ts(t.SalesEnd),
		})
	}
	if avail < 0 {
		avail = 0
	}
	partial["available_tickets"] = avail
	if have {
		partial["min_ticket_price"] = minP
		partial["max_ticket_price"] = maxP
	}
	if len(nested) > 0 {
		partial["tickets"] = nested
	}
	return partial
}

func ticketPartial(t *TicketDoc) map[string]interface{} {
	partial := map[string]interface{}{
		"type":               "ticket",
		"id":                 t.ID,
		"name":               t.Name,
		"description":        t.Description,
		"ticket_type":        t.TypeName,
		"tier":               t.Tier,
		"price":              t.Price,
		"original_price":     t.OriginalPrice,
		"service_fee":        t.ServiceFee,
		"processing_fee":     t.ProcessingFee,
		"quantity":           t.Quantity,
		"sold":               t.Sold,
		"reserved":           t.Reserved,
		"availability":       t.Availability,
		"is_active":          t.IsActive,
		"is_hidden":          t.IsHidden,
		"is_transferable":    t.IsTransferable,
		"is_refundable":      t.IsRefundable,
		"requires_id_check":  t.RequiresIDCheck,
		"event_id":           t.EventID,
		"event_title":        t.EventTitle,
		"event_slug":         t.EventSlug,
		"event_category":     t.EventCategory,
		"event_city":         t.EventCity,
		"event_start_time":   t.EventStartTime,
		"event_is_published": t.EventIsPublished,
		"created_at":         t.CreatedAt,
		"updated_at":         t.UpdatedAt,
	}
	dropEmptyDates(partial, "event_start_time", "created_at", "updated_at")
	return partial
}

// dropEmptyDates removes map keys whose values are empty strings. ES date
// fields reject "", so omitted is better than empty for the optional dates.
func dropEmptyDates(m map[string]interface{}, keys ...string) {
	for _, k := range keys {
		if v, ok := m[k].(string); ok && v == "" {
			delete(m, k)
		}
	}
}

func venuePartial(v VenueDoc) map[string]interface{} {
	partial := map[string]interface{}{
		"type":              "venue",
		"id":                v.ID,
		"creator_id":        v.CreatorID,
		"name":              v.Name,
		"slug":              v.Slug,
		"description":       v.Description,
		"short_description": v.ShortDescription,
		"venue_type":        v.VenueType,
		"venue_category":    v.VenueCategory,
		"address":           v.Address,
		"city":              v.City,
		"county":            v.County,
		"country":           v.Country,
		"amenities":         v.Amenities,
		"capacity":          v.Capacity,
		"base_price":        v.BasePrice,
		"pricing_type":      v.PricingType,
		"is_available":      v.IsAvailable,
		"status":            v.Status,
		"rating":            v.Rating,
		"review_count":      v.ReviewCount,
		"events_hosted":     v.EventsHosted,
		"created_at":        v.CreatedAt,
		"updated_at":        v.UpdatedAt,
	}
	if len(v.Coordinates) == 2 {
		partial["coordinates"] = v.Coordinates
	}
	return partial
}
