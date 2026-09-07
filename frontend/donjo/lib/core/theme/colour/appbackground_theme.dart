import 'package:flutter/material.dart';

// Palette for the background design system.
// Based on the design token specifications.

class AppBackgroundColors {
  const AppBackgroundColors._();

  // Brand colors.
  static const Color brand = Color(0xFFC1F879); // Brand green

  // Gray scale values (based on examples).
  static const Color gray10 = Color(0xFFF4F4F4); // Lightest
  static const Color gray50 = Color(0xFF8D8D8D);
  static const Color gray80 = Color(0xFF393939);
  static const Color gray90 = Color(0xFF282626);

  // White base.
  static const Color white = Color(0xFFFFFFFF);

  // Light theme (White background).
  static const Color lightBackground = Color(0xFFFFFFFF); // $background: White
  static const Color lightBackgroundHover = Color(0xFFD8D8D8); // Gray 50 @ 12%
  static const Color lightBackgroundActive = Color(0xFFD8D8D8); // Gray 50 @ 50%
  static const Color lightBackgroundSelected = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 20%
  static const Color lightBackgroundSelectedHover = Color(
    0xFFD8D8D8,
  ); // Gray 80 @ 32%
  static const Color lightBackgroundInverse = Color(0xFF393939); // Gray 80
  static const Color lightBackgroundInverseHover = Color(
    0xFF4C4C4C,
  ); // Gray 80 hover
  static const Color lightBackgroundBrand = Color(0xFFC1F879); // Brand green

  // Light theme text & surface (derived).
  static const Color lightTextPrimary = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF737373);
  static const Color lightSurfaceMuted = Color(0xFFFAFAFA);
  static const Color lightBorder = Color(0xFFDBDBDB);

  // Dark theme (Gray 10 background).
  static const Color darkBackground = Color(0xFF141414); // $background: Gray 10
  static const Color darkBackgroundHover = Color(0xFFD8D8D8); // Gray 50 @ 12%
  static const Color darkBackgroundActive = Color(0xFFD8D8D8); // Gray 50 @ 50%
  static const Color darkBackgroundSelected = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 20%
  static const Color darkBackgroundSelectedHover = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 32%
  static const Color darkBackgroundInverse = Color(0xFF393939); // Gray 80
  static const Color darkBackgroundInverseHover = Color(
    0xFF4C4C4C,
  ); // Gray 80 hover
  static const Color darkBackgroundBrand = Color(0xFFC1F879); // Brand green

  // Alternative dark theme (Gray 90 background).
  static const Color darkAltBackground = Color(
    0xFF282626,
  ); // $background: Gray 90
  static const Color darkAltBackgroundHover = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 16%
  static const Color darkAltBackgroundActive = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 40%
  static const Color darkAltBackgroundSelected = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 24%
  static const Color darkAltBackgroundSelectedHover = Color(
    0xFFD8D8D8,
  ); // Gray 50 @ 32%
  static const Color darkAltBackgroundInverse = Color(0xFF393939); // Gray 80
  static const Color darkAltBackgroundInverseHover = Color(
    0xFF4C4C4C,
  ); // Gray 80 hover
  static const Color darkAltBackgroundBrand = Color(0xFFC1F879); // Brand green

  // Dark theme text & surface (derived).
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA8A8A8);
  static const Color darkSurfaceMuted = Color(0xFF121212);
  static const Color darkBorder = Color(0xFF363636);

  // Semantic colors.
  static const Color danger = Color(0xFFED4956);
  static const Color success = Color(0xFF2E7D32);

  /// Opacity applied to a disabled primary button.
  static const double disabledOpacity = 0.3;
}
