library;

import 'package:donjo/feature/gateway/data/models/gateway_models.dart';

enum GatewayStatus {
  initial,
  checking,
  up,
  down,
  failure,
}

class GatewayError {
  const GatewayError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class GatewayState {
  const GatewayState({
    this.status = GatewayStatus.initial,
    this.health,
    this.error,
  });

  final GatewayStatus status;
  final GatewayHealthStatus? health;
  final GatewayError? error;

  bool get busy => status == GatewayStatus.checking;
  bool get isUp => status == GatewayStatus.up && (health?.isUp ?? false);

  GatewayState copyWith({
    GatewayStatus? status,
    GatewayHealthStatus? health,
    bool clearHealth = false,
    GatewayError? error,
    bool clearError = false,
  }) {
    return GatewayState(
      status: status ?? this.status,
      health: clearHealth ? null : health ?? this.health,
      error: clearError ? null : error ?? this.error,
    );
  }
}