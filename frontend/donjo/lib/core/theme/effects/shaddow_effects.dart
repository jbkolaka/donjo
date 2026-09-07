import 'package:flutter/material.dart';

/// Shadows and elevation tokens for the Donj design system.
///
/// Shadows should be used sparingly to create depth.
/// The base shadow token [menu] is strictly designed for dropdown menus
/// and popovers as defined by the design system.
class AppShadows {
  const AppShadows._();

  // Base color extracted from the design token: rgba(0,0,0,.3)
  static const Color menuShadowColor = Color(0x4D000000); // 0.3 opacity

  /// Standard shadow for dropdown menus and popovers.
  /// Value: 0 2px 6px 0 rgba(0,0,0,.3)
  static const List<BoxShadow> menu = [
    BoxShadow(
      color: menuShadowColor,
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  /// Elevated Card shadow (slightly softer than menu).
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x26000000), // 0.15 opacity
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  /// Raised button shadow.
  static const List<BoxShadow> button = [
    BoxShadow(
      color: Color(0x33000000), // 0.2 opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Floating action button or modal overlay shadow.
  static const List<BoxShadow> overlay = [
    BoxShadow(
      color: Color(0x4D000000), // 0.3 opacity
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}
