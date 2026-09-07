import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend endpoint for the Donjo API.
class BackendUri {
  const BackendUri._();

  /// Base URL used by the API client when no explicit base URL is supplied.
  static String get backendUri {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
  }
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
