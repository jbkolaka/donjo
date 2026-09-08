library;

/// Data models for the donjo_search microservice (Elasticsearch search).
///
/// Mirrors the JSON contract of:
///   backend/donjo_search/internal/searchcore/models.go
///   backend/donjo_search/internal/searchcore/search.go
///   backend/donjo_search/internal/searchcore/partials.go
///
/// NOTE: in the search index, `coordinates` is a [lon, lat] array (not an
/// object), and `start_time`/`end_time` are RFC3339 strings.

class SearchEventDoc {
  const SearchEventDoc({
    this.type = SearchType.events,
    required this.id,
    required this.creatorId,
    required this.title,
    required this.slug,
    this.description,
    this.shortDescription,
    this.category,
    this.subCategory,
    this.tags = const [],
    this.eventType,
    this.isVirtual = false,
    this.virtualLink,
    this.virtualPlatform,
    this.venueId,
    this.venueName,
    this.location,
    this.address,
    this.city,
    this.county,
    this.country,
    this.coordinates,
    this.startTime,
    this.endTime,
    this.timezone,
    this.totalCapacity = 0,
    this.availableTickets,
    this.minTicketPrice = 0,
    this.maxTicketPrice = 0,
    this.isFree = false,
    this.status,
    this.isPublished = false,
    this.isPrivate = false,
    this.inviteOnly = false,
    this.organizerName,
    this.views = 0,
    this.likes = 0,
    this.ticketsSold = 0,
    this.revenue = 0,
    this.tickets = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String type;
  final String id;
  final String creatorId;
  final String title;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? category;
  final String? subCategory;
  final List<String> tags;
  final String? eventType;
  final bool isVirtual;
  final String? virtualLink;
  final String? virtualPlatform;
  final String? venueId;
  final String? venueName;
  final String? location;
  final String? address;
  final String? city;
  final String? county;
  final String? country;
  final List<double>? coordinates;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? timezone;
  final int totalCapacity;
  final int? availableTickets;
  final double minTicketPrice;
  final double maxTicketPrice;
  final bool isFree;
  final String? status;
  final bool isPublished;
  final bool isPrivate;
  final bool inviteOnly;
  final String? organizerName;
  final int views;
  final int likes;
  final int ticketsSold;
  final double revenue;
  final List<SearchTicketNested> tickets;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory SearchEventDoc.fromJson(Map<String, dynamic> json) {
    return SearchEventDoc(
      type: json['type'] as String? ?? SearchType.events,
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      category: json['category'] as String?,
      subCategory: json['sub_category'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      eventType: json['event_type'] as String?,
      isVirtual: json['is_virtual'] as bool? ?? false,
      virtualLink: json['virtual_link'] as String?,
      virtualPlatform: json['virtual_platform'] as String?,
      venueId: json['venue_id'] as String?,
      venueName: json['venue_name'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      county: json['county'] as String?,
      country: json['country'] as String?,
      coordinates: (json['coordinates'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      startTime: _parseDate(json['start_time']),
      endTime: _parseDate(json['end_time']),
      timezone: json['timezone'] as String?,
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 0,
      availableTickets: (json['available_tickets'] as num?)?.toInt(),
      minTicketPrice: (json['min_ticket_price'] as num?)?.toDouble() ?? 0,
      maxTicketPrice: (json['max_ticket_price'] as num?)?.toDouble() ?? 0,
      isFree: json['is_free'] as bool? ?? false,
      status: json['status'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      inviteOnly: json['invite_only'] as bool? ?? false,
      organizerName: json['organizer_name'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      ticketsSold: (json['tickets_sold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      tickets: json['tickets'] is List
          ? (json['tickets'] as List)
              .whereType<Map>()
              .map((e) =>
                  SearchTicketNested.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'creator_id': creatorId,
        'title': title,
        'slug': slug,
        if (description != null) 'description': description,
        if (shortDescription != null)
          'short_description': shortDescription,
        if (category != null) 'category': category,
        if (subCategory != null) 'sub_category': subCategory,
        if (tags.isNotEmpty) 'tags': tags,
        if (eventType != null) 'event_type': eventType,
        'is_virtual': isVirtual,
        if (virtualLink != null) 'virtual_link': virtualLink,
        if (virtualPlatform != null) 'virtual_platform': virtualPlatform,
        if (venueId != null) 'venue_id': venueId,
        if (venueName != null) 'venue_name': venueName,
        if (location != null) 'location': location,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (county != null) 'county': county,
        if (country != null) 'country': country,
        if (coordinates != null) 'coordinates': coordinates,
        if (startTime != null) 'start_time': startTime!.toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toIso8601String(),
        if (timezone != null) 'timezone': timezone,
        'total_capacity': totalCapacity,
        if (availableTickets != null) 'available_tickets': availableTickets,
        'min_ticket_price': minTicketPrice,
        'max_ticket_price': maxTicketPrice,
        'is_free': isFree,
        if (status != null) 'status': status,
        'is_published': isPublished,
        'is_private': isPrivate,
        'invite_only': inviteOnly,
        if (organizerName != null) 'organizer_name': organizerName,
        'views': views,
        'likes': likes,
        'tickets_sold': ticketsSold,
        'revenue': revenue,
        if (tickets.isNotEmpty)
          'tickets': tickets.map((t) => t.toJson()).toList(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class SearchTicketNested {
  const SearchTicketNested({
    required this.id,
    required this.name,
    this.type,
    this.tier,
    required this.price,
    this.serviceFee = 0,
    this.processingFee = 0,
    required this.quantity,
    this.sold = 0,
    this.reserved = 0,
    required this.availability,
    this.isActive = true,
    this.isHidden = false,
    this.salesStart,
    this.salesEnd,
  });

  final String id;
  final String name;
  final String? type;
  final String? tier;
  final double price;
  final double serviceFee;
  final double processingFee;
  final int quantity;
  final int sold;
  final int reserved;
  final int availability;
  final bool isActive;
  final bool isHidden;
  final DateTime? salesStart;
  final DateTime? salesEnd;

  factory SearchTicketNested.fromJson(Map<String, dynamic> json) {
    return SearchTicketNested(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      tier: json['tier'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
      processingFee: (json['processing_fee'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      availability: (json['availability'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isHidden: json['is_hidden'] as bool? ?? false,
      salesStart: json['sales_start'] is String
          ? DateTime.tryParse(json['sales_start'] as String)
          : null,
      salesEnd: json['sales_end'] is String
          ? DateTime.tryParse(json['sales_end'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (type != null) 'type': type,
        if (tier != null) 'tier': tier,
        'price': price,
        'service_fee': serviceFee,
        'processing_fee': processingFee,
        'quantity': quantity,
        'sold': sold,
        'reserved': reserved,
        'availability': availability,
        'is_active': isActive,
        'is_hidden': isHidden,
        if (salesStart != null) 'sales_start': salesStart!.toIso8601String(),
        if (salesEnd != null) 'sales_end': salesEnd!.toIso8601String(),
      };
}

class SearchTicketDoc {
  const SearchTicketDoc({
    this.type = SearchType.tickets,
    required this.id,
    required this.name,
    this.description,
    this.ticketType,
    this.tier,
    required this.price,
    this.originalPrice,
    this.serviceFee = 0,
    this.processingFee = 0,
    required this.quantity,
    this.sold = 0,
    this.reserved = 0,
    required this.availability,
    this.isActive = true,
    this.isHidden = false,
    this.isTransferable = true,
    this.isRefundable = false,
    this.requiresIdCheck = false,
    required this.eventId,
    this.eventTitle,
    this.eventSlug,
    this.eventCategory,
    this.eventCity,
    this.eventStartTime,
    this.eventIsPublished = false,
    this.createdAt,
    this.updatedAt,
  });

  final String type;
  final String id;
  final String name;
  final String? description;
  final String? ticketType;
  final String? tier;
  final double price;
  final double? originalPrice;
  final double serviceFee;
  final double processingFee;
  final int quantity;
  final int sold;
  final int reserved;
  final int availability;
  final bool isActive;
  final bool isHidden;
  final bool isTransferable;
  final bool isRefundable;
  final bool requiresIdCheck;
  final String eventId;
  final String? eventTitle;
  final String? eventSlug;
  final String? eventCategory;
  final String? eventCity;
  final DateTime? eventStartTime;
  final bool eventIsPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory SearchTicketDoc.fromJson(Map<String, dynamic> json) {
    return SearchTicketDoc(
      type: json['type'] as String? ?? SearchType.tickets,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      ticketType: json['ticket_type'] as String?,
      tier: json['tier'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
      processingFee: (json['processing_fee'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      availability: (json['availability'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isHidden: json['is_hidden'] as bool? ?? false,
      isTransferable: json['is_transferable'] as bool? ?? true,
      isRefundable: json['is_refundable'] as bool? ?? false,
      requiresIdCheck: json['requires_id_check'] as bool? ?? false,
      eventId: json['event_id'] as String? ?? '',
      eventTitle: json['event_title'] as String?,
      eventSlug: json['event_slug'] as String?,
      eventCategory: json['event_category'] as String?,
      eventCity: json['event_city'] as String?,
      eventStartTime: _parseDate(json['event_start_time']),
      eventIsPublished: json['event_is_published'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (ticketType != null) 'ticket_type': ticketType,
        if (tier != null) 'tier': tier,
        'price': price,
        if (originalPrice != null) 'original_price': originalPrice,
        'service_fee': serviceFee,
        'processing_fee': processingFee,
        'quantity': quantity,
        'sold': sold,
        'reserved': reserved,
        'availability': availability,
        'is_active': isActive,
        'is_hidden': isHidden,
        'is_transferable': isTransferable,
        'is_refundable': isRefundable,
        'requires_id_check': requiresIdCheck,
        'event_id': eventId,
        if (eventTitle != null) 'event_title': eventTitle,
        if (eventSlug != null) 'event_slug': eventSlug,
        if (eventCategory != null) 'event_category': eventCategory,
        if (eventCity != null) 'event_city': eventCity,
        if (eventStartTime != null)
          'event_start_time': eventStartTime!.toIso8601String(),
        'event_is_published': eventIsPublished,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class SearchVenueDoc {
  const SearchVenueDoc({
    this.type = SearchType.venues,
    required this.id,
    required this.creatorId,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    this.venueType,
    this.venueCategory,
    required this.address,
    this.city,
    this.county,
    this.country,
    this.coordinates,
    this.amenities = const [],
    this.capacity = 0,
    this.basePrice = 0,
    this.pricingType,
    this.isAvailable = true,
    this.status,
    this.rating = 0,
    this.reviewCount = 0,
    this.eventsHosted = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String type;
  final String id;
  final String creatorId;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String? venueType;
  final String? venueCategory;
  final String address;
  final String? city;
  final String? county;
  final String? country;
  final List<double>? coordinates;
  final List<String> amenities;
  final int capacity;
  final double basePrice;
  final String? pricingType;
  final bool isAvailable;
  final String? status;
  final double rating;
  final int reviewCount;
  final int eventsHosted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SearchVenueDoc.fromJson(Map<String, dynamic> json) {
    return SearchVenueDoc(
      type: json['type'] as String? ?? SearchType.venues,
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      venueType: json['venue_type'] as String?,
      venueCategory: json['venue_category'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String?,
      county: json['county'] as String?,
      country: json['country'] as String?,
      coordinates: (json['coordinates'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      amenities: (json['amenities'] as List?)?.cast<String>() ?? const [],
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      pricingType: json['pricing_type'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      status: json['status'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      eventsHosted: (json['events_hosted'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] is String
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'creator_id': creatorId,
        'name': name,
        'slug': slug,
        if (description != null) 'description': description,
        if (shortDescription != null)
          'short_description': shortDescription,
        if (venueType != null) 'venue_type': venueType,
        if (venueCategory != null) 'venue_category': venueCategory,
        'address': address,
        if (city != null) 'city': city,
        if (county != null) 'county': county,
        if (country != null) 'country': country,
        if (coordinates != null) 'coordinates': coordinates,
        if (amenities.isNotEmpty) 'amenities': amenities,
        'capacity': capacity,
        'base_price': basePrice,
        if (pricingType != null) 'pricing_type': pricingType,
        'is_available': isAvailable,
        if (status != null) 'status': status,
        'rating': rating,
        'review_count': reviewCount,
        'events_hosted': eventsHosted,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// A single result entry in the search response.
class SearchHit {
  const SearchHit({
    required this.id,
    required this.type,
    this.score = 0,
    this.source = const {},
  });

  final String id;

  /// One of `events`, `tickets`, `venues`.
  final String type;
  final double score;

  /// Raw Elasticsearch document body. Map to [SearchEventDoc],
  /// [SearchTicketDoc] or [SearchVenueDoc] based on [type].
  final Map<String, dynamic> source;

  factory SearchHit.fromJson(Map<String, dynamic> json) {
    return SearchHit(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      source: json['source'] is Map
          ? (json['source'] as Map).cast<String, dynamic>()
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'score': score,
        'source': source,
      };
}

/// Response of GET /api/v1/search.
class SearchResult {
  const SearchResult({
    this.total = 0,
    this.page = 1,
    this.size = 20,
    this.hits = const [],
  });

  final int total;
  final int page;
  final int size;
  final List<SearchHit> hits;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 20,
      hits: json['hits'] is List
          ? (json['hits'] as List)
              .whereType<Map>()
              .map((e) => SearchHit.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'page': page,
        'size': size,
        'hits': hits.map((h) => h.toJson()).toList(),
      };
}

/// Query parameters for GET /api/v1/search.
class SearchFilters {
  const SearchFilters({
    this.q,
    this.type = SearchType.events,
    this.category,
    this.city,
    this.country,
    this.eventType,
    this.isVirtual,
    this.minPrice,
    this.maxPrice,
    this.minCapacity,
    this.dateFrom,
    this.dateTo,
    this.status,
    this.sort,
    this.page = 1,
    this.size = 20,
  });

  final String? q;

  /// `events`, `tickets` or `venues`.
  final String type;
  final String? category;
  final String? city;
  final String? country;
  final String? eventType;
  final bool? isVirtual;
  final double? minPrice;
  final double? maxPrice;
  final int? minCapacity;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? status;
  final String? sort;
  final int page;
  final int size;

  Map<String, String> toQueryParameters() => {
        if (q != null && q!.isNotEmpty) 'q': q!,
        'type': type,
        'category': ?category,
        'city': ?city,
        'country': ?country,
        'event_type': ?eventType,
        if (isVirtual != null) 'is_virtual': isVirtual.toString(),
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
        if (minCapacity != null) 'min_capacity': minCapacity.toString(),
        if (dateFrom != null) 'date_from': dateFrom!.toIso8601String(),
        if (dateTo != null) 'date_to': dateTo!.toIso8601String(),
        'status': ?status,
        'sort': ?sort,
        'page': page.toString(),
        'size': size.toString(),
      };
}

/// String constants matching the donjo_search backend values.
abstract final class SearchType {
  static const events = 'events';
  static const tickets = 'tickets';
  static const venues = 'venues';
}

abstract final class SearchSort {
  static const relevance = 'relevance';
  static const date = 'date';
  static const priceAsc = 'price_asc';
  static const priceDesc = 'price_desc';
}
