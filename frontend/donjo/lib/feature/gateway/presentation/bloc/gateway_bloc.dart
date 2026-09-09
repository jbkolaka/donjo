library;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/gateway/data/repositories/gateway_repository.dart';
import 'package:donjo/feature/gateway/presentation/bloc/gateway_event.dart';
import 'package:donjo/feature/gateway/presentation/bloc/gateway_state.dart';

export 'gateway_event.dart';
export 'gateway_state.dart';

class GatewayBloc extends Bloc<GatewayEvent, GatewayState> {
  GatewayBloc({required this.gatewayRepository}) : super(const GatewayState()) {
    on<GatewayPingRequested>(_onPingRequested);
    on<GatewayErrorCleared>(_onErrorCleared);
  }

  final GatewayRepository gatewayRepository;

  Future<void> _onPingRequested(
    GatewayPingRequested event,
    Emitter<GatewayState> emit,
  ) async {
    emit(state.copyWith(status: GatewayStatus.checking, clearError: true));
    try {
      final health = await gatewayRepository.health();
      emit(
        state.copyWith(
          status: health.isUp ? GatewayStatus.up : GatewayStatus.down,
          health: health,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: GatewayStatus.failure,
          error: GatewayError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GatewayStatus.failure,
          error: GatewayError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(GatewayErrorCleared event, Emitter<GatewayState> emit) {
    emit(state.copyWith(clearError: true));
  }
}