import 'package:flutter/material.dart';

// Palette for the KeepSafe design system.

class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF0096A6);

  // Light theme.
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFFAFAFA);
  static const Color lightTextPrimary = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF737373);
  static const Color lightBorder = Color(0xFFDBDBDB);

  // Dark theme.
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurfaceMuted = Color(0xFF121212);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA8A8A8);
  static const Color darkBorder = Color(0xFF363636);

  /// Error red. Warmer and less alarming than `Colors.red`, which is what
  /// Instagram uses for inline validation copy.
  static const Color danger = Color(0xFFED4956);

  static const Color success = Color(0xFF2E7D32);

  /// Opacity applied to a disabled primary button. Instagram fades the filled
  /// button rather than swapping it to grey, so the CTA keeps its identity
  /// while clearly not being tappable.
  static const double disabledOpacity = 0.3;
}
