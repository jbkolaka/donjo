library;

import 'package:donjo/feature/events/data/models/event_models.dart';

/// Data models for the donjo_ml microservice (recommendations, similar
/// events, interactions/profile).
///
/// Mirrors the JSON contract of:
///   backend/donjo_ml/internal/mlcore/models.go
///   backend/donjo_ml/internal/mlcore/handler.go
///
/// The ML service returns a stored copy of the event-service `Event`
/// document, so [RecItem.event] reuses [Event] from the events feature.

/// A single recommendation entry.
class RecItem {
  const RecItem({
    required this.eventId,
    this.score = 0,
    this.reasons = const [],
    this.event,
  });

  final String eventId;
  final double score;
  final List<String> reasons;
  final Event? event;

  factory RecItem.fromJson(Map<String, dynamic> json) {
    return RecItem(
      eventId: json['event_id'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      reasons: (json['reasons'] as List?)?.cast<String>() ?? const [],
      event: json['event'] is Map
          ? Event.fromJson((json['event'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'score': score,
        'reasons': reasons,
        if (event != null) 'event': event!.toJson(),
      };
}

/// Response of GET /api/v1/recommendations.
class RecResult {
  const RecResult({
    this.modelVersion = 'v1',
    this.type = RecType.upcoming,
    this.userId,
    this.items = const [],
  });

  final String modelVersion;
  final String type;
  final String? userId;
  final List<RecItem> items;

  factory RecResult.fromJson(Map<String, dynamic> json) {
    return RecResult(
      modelVersion: json['model_version'] as String? ?? 'v1',
      type: json['type'] as String? ?? RecType.upcoming,
      userId: json['user_id'] as String?,
      items: json['items'] is List
          ? (json['items'] as List)
              .whereType<Map>()
              .map((e) => RecItem.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'model_version': modelVersion,
        'type': type,
        if (userId != null) 'user_id': userId,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// A similar-event list entry (GET /api/v1/events/:id/similar).
class SimilarEvent {
  const SimilarEvent({
    required this.eventId,
    this.title,
    this.slug,
    this.score = 0,
  });

  final String eventId;
  final String? title;
  final String? slug;
  final double score;

  factory SimilarEvent.fromJson(Map<String, dynamic> json) {
    return SimilarEvent(
      eventId: json['event_id'] as String? ?? '',
      title: json['title'] as String?,
      slug: json['slug'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        if (title != null) 'title': title,
        if (slug != null) 'slug': slug,
        'score': score,
      };
}

/// Body of POST /api/v1/interactions.
class InteractionRequest {
  const InteractionRequest({
    this.eventId,
    this.venueId,
    required this.interactionType,
    this.weight,
    this.sessionId,
    this.durationSeconds,
    this.position,
    this.deviceType,
    this.ipAddress,
  });

  final String? eventId;
  final String? venueId;
  final String interactionType;
  final int? weight;
  final String? sessionId;
  final int? durationSeconds;
  final int? position;
  final String? deviceType;
  final String? ipAddress;

  Map<String, dynamic> toJson() => {
        if (eventId != null) 'event_id': eventId,
        if (venueId != null) 'venue_id': venueId,
        'interaction_type': interactionType,
        if (weight != null) 'weight': weight,
        if (sessionId != null) 'session_id': sessionId,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (position != null) 'position': position,
        if (deviceType != null) 'device_type': deviceType,
        if (ipAddress != null) 'ip_address': ipAddress,
      };
}

/// Learned user preferences returned by GET /api/v1/profile.
///
/// The handler renders a flat response of the user_embeddings row:
/// `preferences` holds the learned categories (list) and venue/time
/// affinities (category -> weight maps).
class UserProfile {
  const UserProfile({
    this.userId,
    this.modelVersion = 'v1',
    this.interactionCount = 0,
    this.preferredCategories = const [],
    this.preferredVenues = const {},
    this.preferredTimes = const {},
    this.lastCalculatedAt,
  });

  final String? userId;
  final String modelVersion;
  final int interactionCount;
  final List<String> preferredCategories;
  final Map<String, double> preferredVenues;
  final Map<String, double> preferredTimes;
  final DateTime? lastCalculatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final preferences = json['preferences'] is Map
        ? (json['preferences'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final venues = preferences['venues'] is Map
        ? (preferences['venues'] as Map)
            .map<String, double>((k, v) => MapEntry(
                  k.toString(),
                  (v as num?)?.toDouble() ?? 0,
                ))
        : <String, double>{};
    final times = preferences['times'] is Map
        ? (preferences['times'] as Map).map<String, double>((k, v) => MapEntry(
              k.toString(),
              (v as num?)?.toDouble() ?? 0,
            ))
        : <String, double>{};
    return UserProfile(
      userId: json['user_id'] as String?,
      modelVersion: json['model_version'] as String? ?? 'v1',
      interactionCount: (json['interaction_count'] as num?)?.toInt() ?? 0,
      preferredCategories:
          (preferences['categories'] as List?)?.cast<String>() ?? const [],
      preferredVenues: venues,
      preferredTimes: times,
      lastCalculatedAt: json['last_calculated_at'] is String
          ? DateTime.tryParse(json['last_calculated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (userId != null) 'user_id': userId,
        'model_version': modelVersion,
        'interaction_count': interactionCount,
        'preferences': {
          if (preferredCategories.isNotEmpty)
            'categories': preferredCategories,
          if (preferredVenues.isNotEmpty) 'venues': preferredVenues,
          if (preferredTimes.isNotEmpty) 'times': preferredTimes,
        },
        if (lastCalculatedAt != null)
          'last_calculated_at': lastCalculatedAt!.toIso8601String(),
      };
}

/// String constants matching the donjo_ml backend values.
abstract final class RecType {
  static const upcoming = 'upcoming';
  static const trending = 'trending';
}

abstract final class InteractionType {
  static const view = 'view';
  static const click = 'click';
  static const save = 'save';
  static const share = 'share';
  static const like = 'like';
  static const purchase = 'purchase';

  /// Server-side weights (donjo_ml `interactionWeights`).
  static int weightOf(String type) => switch (type) {
        view || click => 1,
        save => 4,
        share => 3,
        like => 3,
        purchase => 5,
        _ => 1,
      };
}
