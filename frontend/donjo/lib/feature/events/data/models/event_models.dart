library;

/// Data models for the donjo_event microservice (Event / Venue / Ticket).
///
/// Mirrors the JSON contract of:
///   backend/donjo_event/internal/models/event.go
///   backend/donjo_event/internal/server/routes.go
///
/// All optional Go fields (json:",omitempty") are serialized only when non-null.

class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class Event {
  const Event({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.category,
    this.subCategory,
    this.tags = const [],
    required this.eventType,
    this.isVirtual = false,
    this.virtualLink,
    this.virtualPlatform,
    this.venueId,
    this.location,
    this.address,
    this.city,
    this.county,
    required this.country,
    this.coordinates,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    this.setupTime,
    this.teardownTime,
    required this.totalCapacity,
    this.availableTickets,
    this.minTicketPrice = 0,
    this.maxTicketPrice = 0,
    this.isFree = false,
    this.ticketSalesStart,
    this.ticketSalesEnd,
    this.ticketTransferAllowed = true,
    this.refundDeadline,
    this.status = EventStatus.draft,
    this.isPublished = false,
    this.publishedAt,
    this.isPrivate = false,
    this.inviteOnly = false,
    this.eventPassword,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.bannerImage,
    this.galleryImages = const [],
    this.videoUrl,
    this.organizerName,
    this.organizerEmail,
    this.organizerPhone,
    this.views = 0,
    this.likes = 0,
    this.shares = 0,
    this.ticketsSold = 0,
    this.revenue = 0,
    this.allowWaitlist = true,
    this.requiresAgeVerification = false,
    this.minimumAge,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.tickets = const [],
  });

  final String id;
  final String creatorId;
  final String title;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String category;
  final String? subCategory;
  final List<String> tags;
  final String eventType;
  final bool isVirtual;
  final String? virtualLink;
  final String? virtualPlatform;
  final String? venueId;
  final String? location;
  final String? address;
  final String? city;
  final String? county;
  final String country;
  final Coordinates? coordinates;
  final DateTime startTime;
  final DateTime endTime;
  final String timezone;
  final DateTime? setupTime;
  final DateTime? teardownTime;
  final int totalCapacity;
  final int? availableTickets;
  final double minTicketPrice;
  final double maxTicketPrice;
  final bool isFree;
  final DateTime? ticketSalesStart;
  final DateTime? ticketSalesEnd;
  final bool ticketTransferAllowed;
  final DateTime? refundDeadline;
  final String status;
  final bool isPublished;
  final DateTime? publishedAt;
  final bool isPrivate;
  final bool inviteOnly;
  final String? eventPassword;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final String? bannerImage;
  final List<String> galleryImages;
  final String? videoUrl;
  final String? organizerName;
  final String? organizerEmail;
  final String? organizerPhone;
  final int views;
  final int likes;
  final int shares;
  final int ticketsSold;
  final double revenue;
  final bool allowWaitlist;
  final bool requiresAgeVerification;
  final int? minimumAge;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<Ticket> tickets;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      category: json['category'] as String? ?? '',
      subCategory: json['sub_category'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      eventType: json['event_type'] as String? ?? EventType.inPerson,
      isVirtual: json['is_virtual'] as bool? ?? false,
      virtualLink: json['virtual_link'] as String?,
      virtualPlatform: json['virtual_platform'] as String?,
      venueId: json['venue_id'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      county: json['county'] as String?,
      country: json['country'] as String? ?? 'Kenya',
      coordinates: json['coordinates'] is Map
          ? Coordinates.fromJson(
              (json['coordinates'] as Map).cast<String, dynamic>(),
            )
          : null,
      startTime: _parseDate(json['start_time']) ?? DateTime.now(),
      endTime: _parseDate(json['end_time']) ?? DateTime.now(),
      timezone: json['timezone'] as String? ?? 'Africa/Nairobi',
      setupTime: _parseDate(json['setup_time']),
      teardownTime: _parseDate(json['teardown_time']),
      totalCapacity: (json['total_capacity'] as num?)?.toInt() ?? 0,
      availableTickets: (json['available_tickets'] as num?)?.toInt(),
      minTicketPrice: (json['min_ticket_price'] as num?)?.toDouble() ?? 0,
      maxTicketPrice: (json['max_ticket_price'] as num?)?.toDouble() ?? 0,
      isFree: json['is_free'] as bool? ?? false,
      ticketSalesStart: _parseDate(json['ticket_sales_start']),
      ticketSalesEnd: _parseDate(json['ticket_sales_end']),
      ticketTransferAllowed: json['ticket_transfer_allowed'] as bool? ?? true,
      refundDeadline: _parseDate(json['refund_deadline']),
      status: json['status'] as String? ?? EventStatus.draft,
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: _parseDate(json['published_at']),
      isPrivate: json['is_private'] as bool? ?? false,
      inviteOnly: json['invite_only'] as bool? ?? false,
      eventPassword: json['event_password'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: _parseDate(json['verified_at']),
      verificationNotes: json['verification_notes'] as String?,
      bannerImage: json['banner_image'] as String?,
      galleryImages:
          (json['gallery_images'] as List?)?.cast<String>() ?? const [],
      videoUrl: json['video_url'] as String?,
      organizerName: json['organizer_name'] as String?,
      organizerEmail: json['organizer_email'] as String?,
      organizerPhone: json['organizer_phone'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      shares: (json['shares'] as num?)?.toInt() ?? 0,
      ticketsSold: (json['tickets_sold'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      allowWaitlist: json['allow_waitlist'] as bool? ?? true,
      requiresAgeVerification:
          json['requires_age_verification'] as bool? ?? false,
      minimumAge: (json['minimum_age'] as num?)?.toInt(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDate(json['deleted_at']),
      tickets: json['tickets'] is List
          ? (json['tickets'] as List)
                .whereType<Map>()
                .map((e) => Ticket.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creator_id': creatorId,
    'title': title,
    'slug': slug,
    if (description != null) 'description': description,
    if (shortDescription != null) 'short_description': shortDescription,
    'category': category,
    if (subCategory != null) 'sub_category': subCategory,
    if (tags.isNotEmpty) 'tags': tags,
    'event_type': eventType,
    'is_virtual': isVirtual,
    if (virtualLink != null) 'virtual_link': virtualLink,
    if (virtualPlatform != null) 'virtual_platform': virtualPlatform,
    if (venueId != null) 'venue_id': venueId,
    if (location != null) 'location': location,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (county != null) 'county': county,
    'country': country,
    if (coordinates != null) 'coordinates': coordinates!.toJson(),
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'timezone': timezone,
    if (setupTime != null) 'setup_time': setupTime!.toIso8601String(),
    if (teardownTime != null) 'teardown_time': teardownTime!.toIso8601String(),
    'total_capacity': totalCapacity,
    if (availableTickets != null) 'available_tickets': availableTickets,
    'min_ticket_price': minTicketPrice,
    'max_ticket_price': maxTicketPrice,
    'is_free': isFree,
    if (ticketSalesStart != null)
      'ticket_sales_start': ticketSalesStart!.toIso8601String(),
    if (ticketSalesEnd != null)
      'ticket_sales_end': ticketSalesEnd!.toIso8601String(),
    'ticket_transfer_allowed': ticketTransferAllowed,
    if (refundDeadline != null)
      'refund_deadline': refundDeadline!.toIso8601String(),
    'status': status,
    'is_published': isPublished,
    if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
    'is_private': isPrivate,
    'invite_only': inviteOnly,
    if (eventPassword != null && eventPassword!.isNotEmpty)
      'event_password': eventPassword,
    'is_verified': isVerified,
    if (verifiedBy != null) 'verified_by': verifiedBy,
    if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
    if (verificationNotes != null) 'verification_notes': verificationNotes,
    if (bannerImage != null) 'banner_image': bannerImage,
    if (galleryImages.isNotEmpty) 'gallery_images': galleryImages,
    if (videoUrl != null) 'video_url': videoUrl,
    if (organizerName != null) 'organizer_name': organizerName,
    if (organizerEmail != null) 'organizer_email': organizerEmail,
    if (organizerPhone != null) 'organizer_phone': organizerPhone,
    'views': views,
    'likes': likes,
    'shares': shares,
    'tickets_sold': ticketsSold,
    'revenue': revenue,
    'allow_waitlist': allowWaitlist,
    'requires_age_verification': requiresAgeVerification,
    if (minimumAge != null) 'minimum_age': minimumAge,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    if (tickets.isNotEmpty) 'tickets': tickets.map((t) => t.toJson()).toList(),
  };
}

class Venue {
  const Venue({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.slug,
    this.description,
    this.shortDescription,
    required this.venueType,
    this.venueCategory,
    required this.address,
    this.city,
    this.county,
    required this.country,
    this.coordinates,
    this.mapEmbedUrl,
    this.directions,
    required this.capacity,
    this.maxCapacity,
    required this.basePrice,
    this.pricingType = VenuePricingType.hourly,
    this.minBookingHours = 2,
    this.maxBookingHours = 12,
    this.securityDeposit = 0,
    this.cleaningFee = 0,
    this.isAvailable = true,
    this.availabilitySchedule,
    this.unavailableDates = const [],
    this.amenities = const [],
    this.equipment = const [],
    this.capacityFeatures,
    this.restrictions = const [],
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.status = VenueStatus.pendingVerification,
    this.coverImage,
    this.galleryImages = const [],
    this.virtualTourUrl,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.eventsHosted = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String creatorId;
  final String name;
  final String slug;
  final String? description;
  final String? shortDescription;
  final String venueType;
  final String? venueCategory;
  final String address;
  final String? city;
  final String? county;
  final String country;
  final Coordinates? coordinates;
  final String? mapEmbedUrl;
  final String? directions;
  final int capacity;
  final int? maxCapacity;
  final double basePrice;
  final String pricingType;
  final int minBookingHours;
  final int maxBookingHours;
  final double securityDeposit;
  final double cleaningFee;
  final bool isAvailable;
  final Map<String, dynamic>? availabilitySchedule;
  final List<String> unavailableDates;
  final List<String> amenities;
  final List<String> equipment;
  final Map<String, dynamic>? capacityFeatures;
  final List<String> restrictions;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final String status;
  final String? coverImage;
  final List<String> galleryImages;
  final String? virtualTourUrl;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final int eventsHosted;
  final double rating;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['short_description'] as String?,
      venueType: json['venue_type'] as String? ?? '',
      venueCategory: json['venue_category'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String?,
      county: json['county'] as String?,
      country: json['country'] as String? ?? 'Kenya',
      coordinates: json['coordinates'] is Map
          ? Coordinates.fromJson(
              (json['coordinates'] as Map).cast<String, dynamic>(),
            )
          : null,
      mapEmbedUrl: json['map_embed_url'] as String?,
      directions: json['directions'] as String?,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['max_capacity'] as num?)?.toInt(),
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0,
      pricingType: json['pricing_type'] as String? ?? VenuePricingType.hourly,
      minBookingHours: (json['min_booking_hours'] as num?)?.toInt() ?? 2,
      maxBookingHours: (json['max_booking_hours'] as num?)?.toInt() ?? 12,
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0,
      cleaningFee: (json['cleaning_fee'] as num?)?.toDouble() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      availabilitySchedule: json['availability_schedule'] is Map
          ? (json['availability_schedule'] as Map).cast<String, dynamic>()
          : null,
      unavailableDates:
          (json['unavailable_dates'] as List?)?.cast<String>() ?? const [],
      amenities: (json['amenities'] as List?)?.cast<String>() ?? const [],
      equipment: (json['equipment'] as List?)?.cast<String>() ?? const [],
      capacityFeatures: json['capacity_features'] is Map
          ? (json['capacity_features'] as Map).cast<String, dynamic>()
          : null,
      restrictions: (json['restrictions'] as List?)?.cast<String>() ?? const [],
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: _parseDate(json['verified_at']),
      verificationNotes: json['verification_notes'] as String?,
      status: json['status'] as String? ?? VenueStatus.pendingVerification,
      coverImage: json['cover_image'] as String?,
      galleryImages:
          (json['gallery_images'] as List?)?.cast<String>() ?? const [],
      virtualTourUrl: json['virtual_tour_url'] as String?,
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      eventsHosted: (json['events_hosted'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDate(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'creator_id': creatorId,
    'name': name,
    'slug': slug,
    if (description != null) 'description': description,
    if (shortDescription != null) 'short_description': shortDescription,
    'venue_type': venueType,
    if (venueCategory != null) 'venue_category': venueCategory,
    'address': address,
    if (city != null) 'city': city,
    if (county != null) 'county': county,
    'country': country,
    if (coordinates != null) 'coordinates': coordinates!.toJson(),
    if (mapEmbedUrl != null) 'map_embed_url': mapEmbedUrl,
    if (directions != null) 'directions': directions,
    'capacity': capacity,
    if (maxCapacity != null) 'max_capacity': maxCapacity,
    'base_price': basePrice,
    'pricing_type': pricingType,
    'min_booking_hours': minBookingHours,
    'max_booking_hours': maxBookingHours,
    'security_deposit': securityDeposit,
    'cleaning_fee': cleaningFee,
    'is_available': isAvailable,
    if (availabilitySchedule != null)
      'availability_schedule': availabilitySchedule,
    if (unavailableDates.isNotEmpty) 'unavailable_dates': unavailableDates,
    if (amenities.isNotEmpty) 'amenities': amenities,
    if (equipment.isNotEmpty) 'equipment': equipment,
    if (capacityFeatures != null) 'capacity_features': capacityFeatures,
    if (restrictions.isNotEmpty) 'restrictions': restrictions,
    'is_verified': isVerified,
    if (verifiedBy != null) 'verified_by': verifiedBy,
    if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
    if (verificationNotes != null) 'verification_notes': verificationNotes,
    'status': status,
    if (coverImage != null) 'cover_image': coverImage,
    if (galleryImages.isNotEmpty) 'gallery_images': galleryImages,
    if (virtualTourUrl != null) 'virtual_tour_url': virtualTourUrl,
    if (contactName != null) 'contact_name': contactName,
    if (contactPhone != null) 'contact_phone': contactPhone,
    if (contactEmail != null) 'contact_email': contactEmail,
    'events_hosted': eventsHosted,
    'rating': rating,
    'review_count': reviewCount,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };
}

class Ticket {
  const Ticket({
    required this.id,
    required this.eventId,
    required this.type,
    this.tier,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.serviceFee = 0,
    this.processingFee = 0,
    required this.quantity,
    this.sold = 0,
    this.reserved = 0,
    this.maxPerUser = 10,
    this.minPerUser = 1,
    this.salesStart,
    this.salesEnd,
    this.earlyBirdDeadline,
    this.isTransferable = true,
    this.isRefundable = false,
    this.requiresIdCheck = false,
    this.customFields,
    this.benefits = const [],
    this.isActive = true,
    this.isHidden = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String eventId;
  final String type;
  final String? tier;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final double serviceFee;
  final double processingFee;
  final int quantity;
  final int sold;
  final int reserved;
  final int maxPerUser;
  final int minPerUser;
  final DateTime? salesStart;
  final DateTime? salesEnd;
  final DateTime? earlyBirdDeadline;
  final bool isTransferable;
  final bool isRefundable;
  final bool requiresIdCheck;
  final Map<String, dynamic>? customFields;
  final List<String> benefits;
  final bool isActive;
  final bool isHidden;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      tier: json['tier'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0,
      processingFee: (json['processing_fee'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      sold: (json['sold'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      maxPerUser: (json['max_per_user'] as num?)?.toInt() ?? 10,
      minPerUser: (json['min_per_user'] as num?)?.toInt() ?? 1,
      salesStart: _parseDate(json['sales_start']),
      salesEnd: _parseDate(json['sales_end']),
      earlyBirdDeadline: _parseDate(json['early_bird_deadline']),
      isTransferable: json['is_transferable'] as bool? ?? true,
      isRefundable: json['is_refundable'] as bool? ?? false,
      requiresIdCheck: json['requires_id_check'] as bool? ?? false,
      customFields: json['custom_fields'] is Map
          ? (json['custom_fields'] as Map).cast<String, dynamic>()
          : null,
      benefits: (json['benefits'] as List?)?.cast<String>() ?? const [],
      isActive: json['is_active'] as bool? ?? true,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_id': eventId,
    'type': type,
    if (tier != null) 'tier': tier,
    'name': name,
    if (description != null) 'description': description,
    'price': price,
    if (originalPrice != null) 'original_price': originalPrice,
    'service_fee': serviceFee,
    'processing_fee': processingFee,
    'quantity': quantity,
    'sold': sold,
    'reserved': reserved,
    'max_per_user': maxPerUser,
    'min_per_user': minPerUser,
    if (salesStart != null) 'sales_start': salesStart!.toIso8601String(),
    if (salesEnd != null) 'sales_end': salesEnd!.toIso8601String(),
    if (earlyBirdDeadline != null)
      'early_bird_deadline': earlyBirdDeadline!.toIso8601String(),
    'is_transferable': isTransferable,
    'is_refundable': isRefundable,
    'requires_id_check': requiresIdCheck,
    if (customFields != null) 'custom_fields': customFields,
    if (benefits.isNotEmpty) 'benefits': benefits,
    'is_active': isActive,
    'is_hidden': isHidden,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

/// Request body for POST /api/v1/events (and reused for PUT /:id as an
/// incremental update — null fields are omitted).
///
/// The backend binds `models.Event` directly; identity, slug, counters and
/// timestamps are assigned server-side and are therefore not client fields.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.totalCapacity,
    this.description,
    this.shortDescription,
    this.subCategory,
    this.tags = const [],
    this.eventType = EventType.inPerson,
    this.isVirtual = false,
    this.virtualLink,
    this.virtualPlatform,
    this.venueId,
    this.location,
    this.address,
    this.city,
    this.county,
    this.country = 'Kenya',
    this.coordinates,
    this.timezone = 'Africa/Nairobi',
    this.setupTime,
    this.teardownTime,
    this.minTicketPrice,
    this.maxTicketPrice,
    this.isFree = false,
    this.ticketSalesStart,
    this.ticketSalesEnd,
    this.ticketTransferAllowed = true,
    this.refundDeadline,
    this.isPrivate = false,
    this.inviteOnly = false,
    this.eventPassword,
    this.bannerImage,
    this.galleryImages = const [],
    this.videoUrl,
    this.organizerName,
    this.organizerEmail,
    this.organizerPhone,
    this.allowWaitlist = true,
    this.requiresAgeVerification = false,
    this.minimumAge,
  });

  final String title;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final int totalCapacity;
  final String? description;
  final String? shortDescription;
  final String? subCategory;
  final List<String> tags;
  final String eventType;
  final bool isVirtual;
  final String? virtualLink;
  final String? virtualPlatform;
  final String? venueId;
  final String? location;
  final String? address;
  final String? city;
  final String? county;
  final String country;
  final Coordinates? coordinates;
  final String timezone;
  final DateTime? setupTime;
  final DateTime? teardownTime;
  final double? minTicketPrice;
  final double? maxTicketPrice;
  final bool isFree;
  final DateTime? ticketSalesStart;
  final DateTime? ticketSalesEnd;
  final bool ticketTransferAllowed;
  final DateTime? refundDeadline;
  final bool isPrivate;
  final bool inviteOnly;
  final String? eventPassword;
  final String? bannerImage;
  final List<String> galleryImages;
  final String? videoUrl;
  final String? organizerName;
  final String? organizerEmail;
  final String? organizerPhone;
  final bool allowWaitlist;
  final bool requiresAgeVerification;
  final int? minimumAge;

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'total_capacity': totalCapacity,
        if (description != null) 'description': description,
        if (shortDescription != null) 'short_description': shortDescription,
        if (subCategory != null) 'sub_category': subCategory,
        if (tags.isNotEmpty) 'tags': tags,
        'event_type': eventType,
        'is_virtual': isVirtual,
        if (virtualLink != null) 'virtual_link': virtualLink,
        if (virtualPlatform != null) 'virtual_platform': virtualPlatform,
        if (venueId != null) 'venue_id': venueId,
        if (location != null) 'location': location,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (county != null) 'county': county,
        'country': country,
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        'timezone': timezone,
        if (setupTime != null) 'setup_time': setupTime!.toIso8601String(),
        if (teardownTime != null)
          'teardown_time': teardownTime!.toIso8601String(),
        if (minTicketPrice != null) 'min_ticket_price': minTicketPrice,
        if (maxTicketPrice != null) 'max_ticket_price': maxTicketPrice,
        'is_free': isFree,
        if (ticketSalesStart != null)
          'ticket_sales_start': ticketSalesStart!.toIso8601String(),
        if (ticketSalesEnd != null)
          'ticket_sales_end': ticketSalesEnd!.toIso8601String(),
        'ticket_transfer_allowed': ticketTransferAllowed,
        if (refundDeadline != null)
          'refund_deadline': refundDeadline!.toIso8601String(),
        'is_private': isPrivate,
        'invite_only': inviteOnly,
        if (eventPassword != null && eventPassword!.isNotEmpty)
          'event_password': eventPassword,
        if (bannerImage != null) 'banner_image': bannerImage,
        if (galleryImages.isNotEmpty) 'gallery_images': galleryImages,
        if (videoUrl != null) 'video_url': videoUrl,
        if (organizerName != null) 'organizer_name': organizerName,
        if (organizerEmail != null) 'organizer_email': organizerEmail,
        if (organizerPhone != null) 'organizer_phone': organizerPhone,
        'allow_waitlist': allowWaitlist,
        'requires_age_verification': requiresAgeVerification,
        if (minimumAge != null) 'minimum_age': minimumAge,
      };
}

/// Request body for POST /api/v1/venues (and reused for PUT /:id).
class VenueDraft {
  const VenueDraft({
    required this.name,
    required this.venueType,
    required this.address,
    required this.country,
    required this.capacity,
    required this.basePrice,
    this.description,
    this.shortDescription,
    this.venueCategory,
    this.city,
    this.county,
    this.coordinates,
    this.mapEmbedUrl,
    this.directions,
    this.maxCapacity,
    this.pricingType = VenuePricingType.hourly,
    this.minBookingHours = 2,
    this.maxBookingHours = 12,
    this.securityDeposit,
    this.cleaningFee,
    this.isAvailable = true,
    this.availabilitySchedule,
    this.unavailableDates = const [],
    this.amenities = const [],
    this.equipment = const [],
    this.capacityFeatures,
    this.restrictions = const [],
    this.coverImage,
    this.galleryImages = const [],
    this.virtualTourUrl,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
  });

  final String name;
  final String venueType;
  final String address;
  final String country;
  final int capacity;
  final double basePrice;
  final String? description;
  final String? shortDescription;
  final String? venueCategory;
  final String? city;
  final String? county;
  final Coordinates? coordinates;
  final String? mapEmbedUrl;
  final String? directions;
  final int? maxCapacity;
  final String pricingType;
  final int minBookingHours;
  final int maxBookingHours;
  final double? securityDeposit;
  final double? cleaningFee;
  final bool isAvailable;
  final Map<String, dynamic>? availabilitySchedule;
  final List<String> unavailableDates;
  final List<String> amenities;
  final List<String> equipment;
  final Map<String, dynamic>? capacityFeatures;
  final List<String> restrictions;
  final String? coverImage;
  final List<String> galleryImages;
  final String? virtualTourUrl;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;

  Map<String, dynamic> toJson() => {
        'name': name,
        'venue_type': venueType,
        'address': address,
        'country': country,
        'capacity': capacity,
        'base_price': basePrice,
        if (description != null) 'description': description,
        if (shortDescription != null) 'short_description': shortDescription,
        if (venueCategory != null) 'venue_category': venueCategory,
        if (city != null) 'city': city,
        if (county != null) 'county': county,
        if (coordinates != null) 'coordinates': coordinates!.toJson(),
        if (mapEmbedUrl != null) 'map_embed_url': mapEmbedUrl,
        if (directions != null) 'directions': directions,
        if (maxCapacity != null) 'max_capacity': maxCapacity,
        'pricing_type': pricingType,
        'min_booking_hours': minBookingHours,
        'max_booking_hours': maxBookingHours,
        if (securityDeposit != null) 'security_deposit': securityDeposit,
        if (cleaningFee != null) 'cleaning_fee': cleaningFee,
        'is_available': isAvailable,
        if (availabilitySchedule != null)
          'availability_schedule': availabilitySchedule,
        if (unavailableDates.isNotEmpty) 'unavailable_dates': unavailableDates,
        if (amenities.isNotEmpty) 'amenities': amenities,
        if (equipment.isNotEmpty) 'equipment': equipment,
        if (capacityFeatures != null) 'capacity_features': capacityFeatures,
        if (restrictions.isNotEmpty) 'restrictions': restrictions,
        if (coverImage != null) 'cover_image': coverImage,
        if (galleryImages.isNotEmpty) 'gallery_images': galleryImages,
        if (virtualTourUrl != null) 'virtual_tour_url': virtualTourUrl,
        if (contactName != null) 'contact_name': contactName,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (contactEmail != null) 'contact_email': contactEmail,
      };
}

/// Request body for POST /api/v1/events/:id/tickets (and PUT .../:ticket_id).
class TicketDraft {
  const TicketDraft({
    required this.type,
    required this.name,
    required this.price,
    required this.quantity,
    this.tier,
    this.description,
    this.originalPrice,
    this.serviceFee,
    this.processingFee,
    this.maxPerUser,
    this.minPerUser,
    this.salesStart,
    this.salesEnd,
    this.earlyBirdDeadline,
    this.isTransferable,
    this.isRefundable,
    this.requiresIdCheck,
    this.customFields,
    this.benefits = const [],
    this.isActive = true,
    this.isHidden = false,
  });

  final String type;
  final String name;
  final double price;
  final int quantity;
  final String? tier;
  final String? description;
  final double? originalPrice;
  final double? serviceFee;
  final double? processingFee;
  final int? maxPerUser;
  final int? minPerUser;
  final DateTime? salesStart;
  final DateTime? salesEnd;
  final DateTime? earlyBirdDeadline;
  final bool? isTransferable;
  final bool? isRefundable;
  final bool? requiresIdCheck;
  final Map<String, dynamic>? customFields;
  final List<String> benefits;
  final bool isActive;
  final bool isHidden;

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'price': price,
        'quantity': quantity,
        if (tier != null) 'tier': tier,
        if (description != null) 'description': description,
        if (originalPrice != null) 'original_price': originalPrice,
        if (serviceFee != null) 'service_fee': serviceFee,
        if (processingFee != null) 'processing_fee': processingFee,
        if (maxPerUser != null) 'max_per_user': maxPerUser,
        if (minPerUser != null) 'min_per_user': minPerUser,
        if (salesStart != null) 'sales_start': salesStart!.toIso8601String(),
        if (salesEnd != null) 'sales_end': salesEnd!.toIso8601String(),
        if (earlyBirdDeadline != null)
          'early_bird_deadline': earlyBirdDeadline!.toIso8601String(),
        if (isTransferable != null) 'is_transferable': isTransferable,
        if (isRefundable != null) 'is_refundable': isRefundable,
        if (requiresIdCheck != null) 'requires_id_check': requiresIdCheck,
        if (customFields != null) 'custom_fields': customFields,
        if (benefits.isNotEmpty) 'benefits': benefits,
        'is_active': isActive,
        'is_hidden': isHidden,
      };
}

/// Request body for POST /api/v1/events/:id/tickets/:ticket_id/purchase.
class PurchaseTicketRequest {
  const PurchaseTicketRequest({required this.quantity});

  final int quantity;

  Map<String, dynamic> toJson() => {'quantity': quantity};
}

/// String constants matching the donjo_event backend values.
abstract final class EventStatus {
  static const draft = 'draft';
  static const active = 'active';
}

abstract final class EventType {
  static const inPerson = 'in_person';
  static const virtual = 'virtual';
}

abstract final class VenueStatus {
  static const pendingVerification = 'pending_verification';
  static const active = 'active';
}

abstract final class VenuePricingType {
  static const hourly = 'hourly';
  static const fixed = 'fixed';
}
