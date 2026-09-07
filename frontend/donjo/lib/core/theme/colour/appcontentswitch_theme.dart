import 'package:flutter/material.dart';

// Content Switcher tokens from the design system, separated by background themes.

class AppContentSwitcherColors {
  const AppContentSwitcherColors._();

  // 1. White Theme
  static const Color whiteContentSwitcherBackground = Color(
    0xFFE0E0E0,
  ); // Gray 20
  static const Color whiteContentSwitcherBackgroundHover = Color(
    0xFFD1D1D1,
  ); // Gray 20 Hover
  static const Color whiteContentSwitcherSelected = Color(0xFFFFFFFF); // White

  // 2. Grey 10 Theme
  static const Color gray10ContentSwitcherBackground = Color(
    0xFFE0E0E0,
  ); // Gray 20
  static const Color gray10ContentSwitcherBackgroundHover = Color(
    0xFFD1D1D1,
  ); // Gray 20 Hover
  static const Color gray10ContentSwitcherSelected = Color(0xFFFFFFFF); // White

  // 3. Grey 90 Theme
  static const Color gray90ContentSwitcherBackground = Color(
    0x00000000,
  ); // Transparent
  static Color get gray90ContentSwitcherBackgroundHover =>
      const Color(0xFF8D8D8D).withValues(alpha: 0.12); // Gray 50, 12%
  static Color get gray90ContentSwitcherSelected =>
      const Color(0xFF8D8D8D).withValues(alpha: 0.24); // Gray 50, 24%

  // 4. Grey 100 Theme
  static const Color gray100ContentSwitcherBackground = Color(
    0x00000000,
  ); // Transparent
  static Color get gray100ContentSwitcherBackgroundHover =>
      const Color(0xFF8D8D8D).withValues(alpha: 0.12); // Gray 50, 12%
  static Color get gray100ContentSwitcherSelected =>
      const Color(0xFF8D8D8D).withValues(alpha: 0.24); // Gray 50, 24%
}
