library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/discovery/data/repositories/discovery_repository.dart';
import 'package:donjo/feature/discovery/presentation/bloc/discovery_event.dart';
import 'package:donjo/feature/discovery/presentation/bloc/discovery_state.dart';

export 'discovery_event.dart';
export 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  DiscoveryBloc({required this.discoveryRepository})
    : super(const DiscoveryState()) {
    on<RecommendationsLoaded>(_onRecommendationsLoaded);
    on<ProfileLoaded>(_onProfileLoaded);
    on<SimilarEventsLoaded>(_onSimilarEventsLoaded);
    on<InteractionRecorded>(_onInteractionRecorded);
    on<DiscoveryErrorCleared>(_onErrorCleared);
  }

  final DiscoveryRepository discoveryRepository;

  Future<void> _onRecommendationsLoaded(
    RecommendationsLoaded event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(state.copyWith(status: DiscoveryStatus.loading, clearError: true));
    try {
      final recommendations = await discoveryRepository.recommendations(
        type: event.type,
        limit: event.limit,
      );
      emit(
        state.copyWith(
          status: DiscoveryStatus.loaded,
          recommendations: recommendations,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onProfileLoaded(
    ProfileLoaded event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(state.copyWith(status: DiscoveryStatus.loading, clearError: true));
    try {
      final profile = await discoveryRepository.profile();
      emit(
        state.copyWith(status: DiscoveryStatus.loaded, profile: profile),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onSimilarEventsLoaded(
    SimilarEventsLoaded event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(state.copyWith(status: DiscoveryStatus.loading, clearError: true));
    try {
      final similar = await discoveryRepository.similarEvents(
        event.eventId,
        limit: event.limit,
      );
      emit(state.copyWith(status: DiscoveryStatus.loaded, similar: similar));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onInteractionRecorded(
    InteractionRecorded event,
    Emitter<DiscoveryState> emit,
  ) async {
    emit(state.copyWith(status: DiscoveryStatus.loading, clearError: true));
    try {
      await discoveryRepository.recordInteraction(event.request);
      emit(
        state.copyWith(
          status: DiscoveryStatus.loaded,
          interactionRecorded: true,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DiscoveryStatus.failure,
          error: DiscoveryError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(DiscoveryErrorCleared event, Emitter<DiscoveryState> emit) {
    emit(state.copyWith(clearError: true, interactionRecorded: false));
  }
}