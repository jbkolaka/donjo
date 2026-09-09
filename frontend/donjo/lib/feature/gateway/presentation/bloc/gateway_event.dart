library;

sealed class GatewayEvent {
  const GatewayEvent();
}

final class GatewayPingRequested extends GatewayEvent {
  const GatewayPingRequested();
}

final class GatewayErrorCleared extends GatewayEvent {
  const GatewayErrorCleared();
}