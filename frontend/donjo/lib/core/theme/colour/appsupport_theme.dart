import 'package:flutter/material.dart';

// Support (semantic) colors from the design system.
// These cover success, error and informational states across themes.

class AppSupportColors {
  const AppSupportColors._();

  // Baseline semantic palette.
  static const Color brand = Color(0xFFC1F879); // Brand green
  static const Color error = Color(0xFFDA1E28); // Red 60
  static const Color danger = Color(0xFFED4956);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF1C21B); // Yellow 30

  // Light theme (White / Grey 10).
  static const Color lightError = Color(0xFFDA1E28); // Red 60
  static const Color lightSuccess = Color(0xFF24A148); // Green 50
  static const Color lightWarning = Color(0xFFF1C21B); // Yellow 30
  static const Color lightInfo = Color(0xFF0043CE); // Blue 70

  // Dark theme (Grey 90 / Grey 100).
  static const Color darkError = Color(0xFFFF8389); // Red 30
  static const Color darkSuccess = Color(0xFF24A148); // Green 50
  static const Color darkWarning = Color(0xFFF1C21B); // Yellow 30
  static const Color darkInfo = Color(0xFF78A9FF); // Blue 40

  /// Opacity applied to disabled controls.
  static const double disabledOpacity = 0.3;
}
