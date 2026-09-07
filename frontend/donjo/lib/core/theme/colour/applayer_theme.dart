import 'package:flutter/material.dart';

// Layer-based background colors from the design system.

class AppLayerColors {
  const AppLayerColors._();

  // Brand color.
  static const Color brand = Color(0xFFC1F879);

  // Light theme (White background).
  static const Color lightStyle01 = Color(
    0xFFFFFFFF,
  ); // White - Background color for layers on top of Background
  static const Color lightStyle02 = Color(
    0xFFFFFFFF,
  ); // White - Background color for layers on top of Layer-01
  static const Color lightStyle03 = Color(
    0xFFFFFFFF,
  ); // White - Background color for layers on top of Layer-02
  static const Color lightStyle04 = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Active state color for Layer-01
  static const Color lightStyle05 = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Active state color for Layer-02
  static const Color lightStyle06 = Color(
    0xFFC6C6C6,
  ); // Gray 30 - High contrast elements; 4.5:1 AA element contrast
  static const Color lightStyle07 = Color(
    0xFFD8D8D8,
  ); // Gray 50 - Disabled state color for selected layers

  // Gray 10 theme.
  static const Color gray10Style01 = Color(
    0xFFFFFFFF,
  ); // White - Background color for layers on top of Background
  static const Color gray10Style02 = Color(
    0xFFFFFFFF,
  ); // White - Background color for layers on top of Layer-01
  static const Color gray10Style03 = Color(
    0xFFFFFFFF,
  ); // White - Background color for layers on top of Layer-02
  static const Color gray10Style04 = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Active state color for Layer-01
  static const Color gray10Style05 = Color(
    0xFFC6C6C6,
  ); // Gray 30 - Active state color for Layer-02
  static const Color gray10Style06 = Color(
    0xFFC6C6C6,
  ); // Gray 30 - High contrast elements; 4.5:1 AA element contrast
  static const Color gray10Style07 = Color(
    0xFFD8D8D8,
  ); // Gray 50 - Disabled state color for selected layers

  // Gray 90 theme.
  static const Color gray90Style01 = Color(
    0xFF333333,
  ); // Gray 80 - Background color for layers on top of Background
  static const Color gray90Style02 = Color(
    0xFF555555,
  ); // Gray 70 - Background color for layers on top of Layer-01
  static const Color gray90Style03 = Color(
    0xFF666666,
  ); // Gray 60 - Background color for layers on top of Layer-02
  static const Color gray90Style04 = Color(
    0xFF777777,
  ); // Gray 70 - Active state color for Layer-01
  static const Color gray90Style05 = Color(
    0xFF777777,
  ); // Gray 70 - Active state color for Layer-02
  static const Color gray90Style06 = Color(
    0xFF161616,
  ); // Gray 100 - High contrast elements; 4.5:1 AA element contrast
  static const Color gray90Style07 = Color(
    0xFF888888,
  ); // Gray 50 - Disabled state color for selected layers

  // Gray 100 theme.
  static const Color gray100Style01 = Color(
    0xFF333333,
  ); // Gray 90 - Background color for layers on top of Background
  static const Color gray100Style02 = Color(
    0xFF333333,
  ); // Gray 80 - Background color for layers on top of Layer-01
  static const Color gray100Style03 = Color(
    0xFF333333,
  ); // Gray 70 - Background color for layers on top of Layer-02
  static const Color gray100Style04 = Color(
    0xFF777777,
  ); // Gray 70 - Active state color for Layer-01
  static const Color gray100Style05 = Color(
    0xFF777777,
  ); // Gray 70 - Active state color for Layer-02
  static const Color gray100Style06 = Color(
    0xFF161616,
  ); // Gray 100 - High contrast elements; 4.5:1 AA element contrast
  static const Color gray100Style07 = Color(
    0xFF888888,
  ); // Gray 50 - Disabled state color for selected layers

  // Semantic colors.
  static const Color danger = Color(0xFFED4956);
  static const Color success = Color(0xFF2E7D32);

  static const double disabledOpacity = 0.3;
}
