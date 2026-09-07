import 'package:flutter/material.dart';

// Icon tokens from the design system, separated by background themes.

class AppIconColors {
  const AppIconColors._();

  // 1. White Theme
  static const Color whiteIconPrimary = Color(
    0xFF161616,
  ); // Gray 100 - Primary icons
  static const Color whiteIconSecondary = Color(
    0xFF525252,
  ); // Gray 70 - Secondary icons
  static const Color whiteIconOnColor = Color(
    0xFFFFFFFF,
  ); // White - Icons on interactive colors; Icons on non-interactive colors
  static const Color whiteIconInteractive = Color(
    0xFF5C9E00,
  ); // Green 60 - Icon color
  static const Color whiteIconInverse = Color(
    0xFFFFFFFF,
  ); // White - Inverse text color; Inverse icon color
  static const Color whiteIconDisabled = Color(
    0xFF161616,
  ); // Gray 100 - Disabled state for icons

  static Color get whiteIconOnColorDisabled => const Color(
    0xFF8D8D8D,
  ).withValues(alpha: 0.5); // Gray 50 - Disabled state color for $icon-on-color
  static Color get whiteIconDisabledLowOpacity =>
      const Color(0xFF161616).withValues(alpha: 0.25); // Gray 100 @ 25%

  // 2. Grey 10 Theme
  static const Color gray10IconPrimary = Color(0xFF161616); // Gray 100
  static const Color gray10IconSecondary = Color(0xFF525252); // Gray 70
  static const Color gray10IconOnColor = Color(0xFFFFFFFF); // White
  static const Color gray10IconInteractive = Color(0xFF5C9E00); // Green 60
  static const Color gray10IconInverse = Color(0xFFFFFFFF); // White
  static const Color gray10IconDisabled = Color(0xFF161616); // Gray 100

  static Color get gray10IconOnColorDisabled =>
      const Color(0xFF8D8D8D).withValues(alpha: 0.5); // Gray 50
  static Color get gray10IconDisabledLowOpacity =>
      const Color(0xFF161616).withValues(alpha: 0.25); // Gray 100 @ 25%

  // 3. Grey 90 Theme
  static const Color gray90IconPrimary = Color(
    0xFFF4F4F4,
  ); // Gray 10 - Primary icons
  static const Color gray90IconSecondary = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Secondary icons
  static const Color gray90IconOnColor = Color(
    0xFFFFFFFF,
  ); // White - Icons on interactive colors; Icons on non-interactive colors
  static const Color gray90IconInteractive = Color(
    0xFFC1F879,
  ); // Green 40 - Icon color
  static const Color gray90IconInverse = Color(
    0xFF161616,
  ); // Gray 100 - Inverse text color; Inverse icon color
  static const Color gray90IconDisabled = Color(
    0xFFF4F4F4,
  ); // Gray 10 - Disabled state for icons

  static Color get gray90IconOnColorDisabled => const Color(
    0xFF8D8D8D,
  ).withValues(alpha: 0.5); // Gray 50 - Disabled state color for $icon-on-color
  static Color get gray90IconDisabledLowOpacity =>
      const Color(0xFFF4F4F4).withValues(alpha: 0.25); // Gray 10 @ 25%

  // 4. Grey 100 Theme
  static const Color gray100IconPrimary = Color(0xFFF4F4F4); // Gray 10
  static const Color gray100IconSecondary = Color(0xFFC6C6C6); // Gray 30
  static const Color gray100IconOnColor = Color(0xFFFFFFFF); // White
  static const Color gray100IconInteractive = Color(0xFFC1F879); // Green 40
  static const Color gray100IconInverse = Color(0xFF161616); // Gray 100
  static const Color gray100IconDisabled = Color(0xFFF4F4F4); // Gray 10

  static Color get gray100IconOnColorDisabled =>
      const Color(0xFF8D8D8D).withValues(alpha: 0.5); // Gray 50
  static Color get gray100IconDisabledLowOpacity =>
      const Color(0xFFF4F4F4).withValues(alpha: 0.25); // Gray 10 @ 25%
}
