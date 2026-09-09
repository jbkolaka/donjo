import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend endpoints for the Donjo microservice fleet.
///
/// Every request flows through the stateless API gateway
/// (donjo_api_gateway) on port 8080, which routes `/api/v1/*` prefixes to
/// the owning microservice and exposes `/health` for liveness. See:
///   backend/donjo_api_gateway/internal/gateway/gateway.go
class BackendUri {
  const BackendUri._();

  /// Gateway base URL used by the API client when no explicit base URL is
  /// supplied.
  static String get backendUri {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
  }

  /// Shared API version segment for every gateway route.
  static const String apiVersion = '/api/v1';

  // donjo_api_gateway
  /// Gateway liveness probe (GET /health).
  static const String health = '/health';

  // donjo_backend (authentication)
  static const String auth = '/api/v1/auth';
  static const String me = '/api/v1/me';
  static const String twoFactor = '/api/v1/2fa';
  static const String sessions = '/api/v1/sessions';

  // donjo_event (events & venues)
  static const String events = '/api/v1/events';
  static const String venues = '/api/v1/venues';

  // donjo_booking (bookings, ticket instances, waitlist)
  static const String bookings = '/api/v1/bookings';
  static const String instances = '/api/v1/instances';
  static const String waitlist = '/api/v1/waitlist';
  static const String scanLocations = '/api/v1/scan-locations';

  // donjo_payment (transactions, escrows, wallet)
  static const String transactions = '/api/v1/transactions';
  static const String escrows = '/api/v1/escrows';
  static const String wallet = '/api/v1/wallet';

  // donjo_search
  static const String search = '/api/v1/search';

  // donjo_ml (recommendations, profile, interactions)
  static const String recommendations = '/api/v1/recommendations';
  static const String profile = '/api/v1/profile';
  static const String interactions = '/api/v1/interactions';

  // donjo_notifications (notifications, feed, push devices, templates)
  static const String notifications = '/api/v1/notifications';
  static const String feed = '/api/v1/feed';
  static const String devices = '/api/v1/devices';
  static const String templates = '/api/v1/templates';
}

class AppConfig {
  // Use different base URLs for web vs mobile
  static String get baseUrl {
    // For web testing - use CORS proxy
    if (kIsWeb) {
      return 'https://cors-anywhere.herokuapp.com/https://keepsafe-backend.onrender.com';
    }
    // For mobile (Android/iOS) - use direct URL
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://keepsafe-backend.onrender.com',
    );
  }

  static const int passwordMinLength = 8;
  static const String emailRegex = r'^[\w\-\.]+@([\w\-]+)+\.[\w\-]{2,4}$';
}
