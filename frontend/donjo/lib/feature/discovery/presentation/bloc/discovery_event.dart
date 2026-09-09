library;

import 'package:donjo/feature/discovery/data/models/discovery_models.dart';

sealed class DiscoveryEvent {
  const DiscoveryEvent();
}

final class RecommendationsLoaded extends DiscoveryEvent {
  const RecommendationsLoaded({
    this.type = RecType.upcoming,
    this.limit = 10,
  });
  final String type;
  final int limit;
}

final class ProfileLoaded extends DiscoveryEvent {
  const ProfileLoaded();
}

final class SimilarEventsLoaded extends DiscoveryEvent {
  const SimilarEventsLoaded({required this.eventId, this.limit = 8});
  final String eventId;
  final int limit;
}

final class InteractionRecorded extends DiscoveryEvent {
  const InteractionRecorded({required this.request});
  final InteractionRequest request;
}

final class DiscoveryErrorCleared extends DiscoveryEvent {
  const DiscoveryErrorCleared();
}