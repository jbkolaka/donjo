library;

/// Data models for the donjo_api_gateway microservice.
///
/// The gateway is a stateless reverse proxy; the only response shape it
/// produces is the health status at GET /health.
///
/// Mirrors the JSON contract of:
///   backend/donjo_api_gateway/internal/gateway/health.go

class GatewayHealthStatus {
  const GatewayHealthStatus({
    this.status = 'down',
    this.services = const {},
    this.checkedAt,
  });

  /// `up` or `degraded`.
  final String status;

  /// Upstream name (auth, event, booking, payment, search, ml,
  /// notifications) → `up`/`down`.
  final Map<String, String> services;
  final DateTime? checkedAt;

  bool get isUp => status == 'up';

  factory GatewayHealthStatus.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final services = rawServices is Map
        ? rawServices.map((k, v) => MapEntry(k.toString(), v.toString()))
        : const <String, String>{};

    return GatewayHealthStatus(
      status: json['status'] as String? ?? 'down',
      services: services,
      checkedAt: json['checked_at'] is String
          ? DateTime.tryParse(json['checked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'services': services,
        if (checkedAt != null) 'checked_at': checkedAt!.toIso8601String(),
      };
}
