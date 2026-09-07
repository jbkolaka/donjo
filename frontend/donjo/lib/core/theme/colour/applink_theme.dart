import 'package:flutter/material.dart';

// Link tokens from the design system, separated by background themes.

class AppLinkColors {
  const AppLinkColors._();

  // 1. White Theme
  static const Color whiteLinkPrimary = Color(
    0xFF5C9E00,
  ); // Green 60 - Primary links; Ghost button
  static const Color whiteLinkPrimaryHover = Color(
    0xFF4A7F00,
  ); // Green 70 - Hover state color for link-primary
  static const Color whiteLinkSecondary = Color(
    0xFF4A7F00,
  ); // Green 70 - Secondary link color for lower contrast backgrounds
  static const Color whiteLinkOnInverse02 = Color(
    0xFFC1F879,
  ); // Green 40 - Links on Inverse-02 backgrounds
  static const Color whiteLinkOnInverseHover = Color(
    0xFFBFEE80,
  ); // Green 30 - Hover color for links on Inverse backgrounds
  static const Color whiteLinkInverseActive = Color(
    0xFF4D4D4D,
  ); // Gray 70 - Active color for links on Inverse backgrounds
  static const Color whiteLinkVisited = Color(
    0xFF8A3FFC,
  ); // Purple 60 - Visited links
  static const Color whiteLinkInverseVisited = Color(
    0xFFBE95FF,
  ); // Purple 40 - Color for visited links on Inverse backgrounds

  // 2. Grey 10 Theme
  static const Color gray10LinkPrimary = Color(0xFF5C9E00); // Green 60
  static const Color gray10LinkPrimaryHover = Color(0xFF4A7F00); // Green 70
  static const Color gray10LinkSecondary = Color(0xFF4A7F00); // Green 70
  static const Color gray10LinkOnInverse02 = Color(0xFFC1F879); // Green 40
  static const Color gray10LinkOnInverseHover = Color(0xFFBFEE80); // Green 30
  static const Color gray10LinkInverseActive = Color(0xFF4D4D4D); // Gray 70
  static const Color gray10LinkVisited = Color(0xFF8A3FFC); // Purple 60
  static const Color gray10LinkInverseVisited = Color(0xFFBE95FF); // Purple 40

  // 3. Grey 90 Theme
  static const Color gray90LinkPrimary = Color(0xFFC1F879); // Green 40
  static const Color gray90LinkPrimaryHover = Color(0xFFBFEE80); // Green 30
  static const Color gray90LinkSecondary = Color(0xFFBFEE80); // Green 30
  static const Color gray90LinkOnInverse02 = Color(0xFF5C9E00); // Green 60
  static const Color gray90LinkOnInverseHover = Color(0xFF4A7F00); // Green 70
  static const Color gray90LinkInverseActive = Color(
    0xFF171616,
  ); // Gray 100 (Note: image shows gray 70 text, but hex is dark)
  static const Color gray90LinkVisited = Color(0xFFBE95FF); // Purple 40
  static const Color gray90LinkInverseVisited = Color(0xFF8A3FFC); // Purple 60

  // 4. Grey 100 Theme
  static const Color gray100LinkPrimary = Color(0xFFC1F879); // Green 40
  static const Color gray100LinkPrimaryHover = Color(0xFFBFEE80); // Green 30
  static const Color gray100LinkSecondary = Color(0xFFBFEE80); // Green 30
  static const Color gray100LinkOnInverse02 = Color(0xFF5C9E00); // Green 60
  static const Color gray100LinkOnInverseHover = Color(0xFF4A7F00); // Green 70
  static const Color gray100LinkInverseActive = Color(0xFF171616); // Gray 100
  static const Color gray100LinkVisited = Color(0xFFBE95FF); // Purple 40
  static const Color gray100LinkInverseVisited = Color(0xFF8A3FFC); // Purple 60
}
