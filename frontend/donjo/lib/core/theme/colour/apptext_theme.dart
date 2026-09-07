import 'package:flutter/material.dart';

// Text tokens from the design system, separated by background themes.

class AppTextColors {
  const AppTextColors._();

  // 1. White Theme
  static const Color whiteTextPrimary = Color(
    0xFF161616,
  ); // Gray 100 - Primary body copy; Headers
  static const Color whiteTextSecondary = Color(
    0xFF525252,
  ); // Gray 70 - Secondary text color, input labels, helper text
  static const Color whiteTextPlaceholder = Color(
    0xFF6F6F6F,
  ); // Gray 60 - Placeholder text
  static const Color whiteTextOnColor = Color(
    0xFFFFFFFF,
  ); // White - Text on interactive colors
  static const Color whiteTextHelper = Color(
    0xFF6F6F6F,
  ); // Gray 60 - Tertiary text; Help text
  static const Color whiteTextError = Color(
    0xFFDA1E28,
  ); // Red 60 - Error message text
  static const Color whiteTextOnInverse = Color(
    0xFFFFFFFF,
  ); // White - Text color on Background-inverse
  static const Color whiteTextDisabled = Color(
    0xFF161616,
  ); // Gray 100 - Disabled text color; Disabled label

  static Color get whiteTextOnColorDisabled =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.25); // White 25%
  static Color get whiteTextDisabledDark =>
      const Color(0xFF161616).withValues(alpha: 0.25); // Gray 100 25%

  // 2. Grey 10 Theme
  static const Color gray10TextPrimary = Color(0xFF161616); // Gray 100
  static const Color gray10TextSecondary = Color(0xFF525252); // Gray 70
  static const Color gray10TextPlaceholder = Color(0xFF6F6F6F); // Gray 60
  static const Color gray10TextOnColor = Color(0xFFFFFFFF); // White
  static const Color gray10TextHelper = Color(0xFF6F6F6F); // Gray 60
  static const Color gray10TextError = Color(0xFFDA1E28); // Red 60
  static const Color gray10TextOnInverse = Color(0xFFFFFFFF); // White
  static const Color gray10TextDisabled = Color(0xFF161616); // Gray 100

  static Color get gray10TextOnColorDisabled =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.25); // White 25%
  static Color get gray10TextDisabledDark =>
      const Color(0xFF161616).withValues(alpha: 0.25); // Gray 100 25%

  // 3. Grey 90 Theme
  static const Color gray90TextPrimary = Color(
    0xFFF4F4F4,
  ); // Gray 10 - Primary body copy; Headers
  static const Color gray90TextSecondary = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Secondary text color, input labels, helper text
  static const Color gray90TextPlaceholder = Color(
    0xFF6F6F6F,
  ); // Gray 60 - Placeholder text
  static const Color gray90TextOnColor = Color(
    0xFFFFFFFF,
  ); // White - Text on interactive colors
  static const Color gray90TextHelper = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Tertiary text; Help text
  static const Color gray90TextError = Color(
    0xFFFF8389,
  ); // Red 30 - Error message text
  static const Color gray90TextOnInverse = Color(
    0xFF161616,
  ); // Gray 100 - Text color on Background-inverse
  static const Color gray90TextDisabled = Color(
    0xFFF4F4F4,
  ); // Gray 10 - Disabled text color; Disabled label

  static Color get gray90TextOnColorDisabled =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.25); // White 25%
  static Color get gray90TextDisabledDark =>
      const Color(0xFFF4F4F4).withValues(alpha: 0.25); // Gray 10 25%

  // 4. Grey 100 Theme
  static const Color gray100TextPrimary = Color(0xFFF4F4F4); // Gray 10
  static const Color gray100TextSecondary = Color(0xFFC6C6C6); // Gray 30
  static const Color gray100TextPlaceholder = Color(0xFF6F6F6F); // Gray 60
  static const Color gray100TextOnColor = Color(0xFFFFFFFF); // White
  static const Color gray100TextHelper = Color(0xFFC6C6C6); // Gray 30
  static const Color gray100TextError = Color(0xFFFF8389); // Red 30
  static const Color gray100TextOnInverse = Color(0xFF161616); // Gray 100
  static const Color gray100TextDisabled = Color(0xFFF4F4F4); // Gray 10

  static Color get gray100TextOnColorDisabled =>
      const Color(0xFFFFFFFF).withValues(alpha: 0.25); // White 25%
  static Color get gray100TextDisabledDark =>
      const Color(0xFFF4F4F4).withValues(alpha: 0.25); // Gray 10 25%
}
