library;

import 'package:donjo/feature/discovery/data/models/discovery_models.dart';
import 'package:donjo/feature/discovery/data/repositories/discovery_repository.dart';

enum DiscoveryStatus {
  initial,
  loading,
  loaded,
  failure,
}

class DiscoveryError {
  const DiscoveryError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class DiscoveryState {
  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.recommendations,
    this.profile,
    this.similar,
    this.interactionRecorded = false,
    this.error,
  });

  final DiscoveryStatus status;
  final RecResult? recommendations;
  final UserProfile? profile;
  final SimilarEventsResult? similar;
  final bool interactionRecorded;
  final DiscoveryError? error;

  bool get busy => status == DiscoveryStatus.loading;

  DiscoveryState copyWith({
    DiscoveryStatus? status,
    RecResult? recommendations,
    bool clearRecommendations = false,
    UserProfile? profile,
    bool clearProfile = false,
    SimilarEventsResult? similar,
    bool clearSimilar = false,
    bool? interactionRecorded,
    DiscoveryError? error,
    bool clearError = false,
  }) {
    return DiscoveryState(
      status: status ?? this.status,
      recommendations: clearRecommendations
          ? null
          : recommendations ?? this.recommendations,
      profile: clearProfile ? null : profile ?? this.profile,
      similar: clearSimilar ? null : similar ?? this.similar,
      interactionRecorded: interactionRecorded ?? this.interactionRecorded,
      error: clearError ? null : error ?? this.error,
    );
  }
}