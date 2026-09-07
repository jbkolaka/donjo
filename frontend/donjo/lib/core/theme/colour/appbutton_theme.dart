import 'package:flutter/material.dart';

// Button tokens from the design system, separated by background themes.

class AppButtonColors {
  const AppButtonColors._();

  // 1. White Theme
  static const Color whiteButtonPrimary = Color(
    0xFFC1F879,
  ); // Brand green - Primary button background color
  static const Color whiteButtonPrimaryHover = Color(
    0xFF5C9E00,
  ); // Green 60 - Hover color for button-primary
  static const Color whiteButtonPrimaryActive = Color(
    0xFF4A7F00,
  ); // Green 70 - Active color for button-primary
  static const Color whiteButtonSecondary = Color(
    0xFF393939,
  ); // Gray 70 - Secondary button background color
  static const Color whiteButtonSecondaryHover = Color(
    0xFF4C4C4C,
  ); // Gray 70 Hover - Hover color for button-secondary
  static const Color whiteButtonSecondaryActive = Color(
    0xFF6F6F6F,
  ); // Gray 60 - Active color for button-secondary
  static const Color whiteButtonTertiary = Color(
    0xFFC1F879,
  ); // Brand green - Tertiary button border and text color
  static const Color whiteButtonTertiaryHover = Color(
    0xFF5C9E00,
  ); // Green 60 - Hover color for button-tertiary
  static const Color whiteButtonTertiaryActive = Color(
    0xFF4A7F00,
  ); // Green 70 - Active color for button-tertiary
  static const Color whiteButtonDangerPrimary = Color(
    0xFFDA1E28,
  ); // Red 60 - Primary danger button background color
  static const Color whiteButtonDangerPrimaryHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover - Hover color for button-danger-primary
  static const Color whiteButtonDangerPrimaryActive = Color(
    0xFF750E13,
  ); // Red 80 - Active color for button-danger-primary
  static const Color whiteButtonDangerTertiary = Color(
    0xFFDA1E28,
  ); // Red 60 - Tertiary danger button border and text color
  static const Color whiteButtonDangerTertiaryHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover - Hover color for button-danger-tertiary
  static const Color whiteButtonDangerTertiaryActive = Color(
    0xFF750E13,
  ); // Red 80 - Active color for button-danger-tertiary
  static const Color whiteButtonDangerGhost = Color(
    0xFFDA1E28,
  ); // Red 60 - Tertiary danger button border and text color
  static const Color whiteButtonDangerGhostHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover - Hover color for button-danger-ghost
  static const Color whiteButtonGhost = Color(
    0xFF393939,
  ); // Gray 70 - Tertiary button border and text color
  static const Color whiteButtonGhostHover = Color(
    0xFF4C4C4C,
  ); // Gray 70 Hover - Hover color for button-ghost
  static const Color whiteButtonGhostActive = Color(
    0xFF6F6F6F,
  ); // Gray 60 - Active color for button-ghost

  // 2. Grey 10 Theme
  static const Color gray10ButtonPrimary = Color(0xFFC1F879); // Brand green
  static const Color gray10ButtonPrimaryHover = Color(
    0xFF5C9E00,
  ); // Green 60
  static const Color gray10ButtonPrimaryActive = Color(0xFF4A7F00); // Green 70
  static const Color gray10ButtonSecondary = Color(0xFF393939); // Gray 70
  static const Color gray10ButtonSecondaryHover = Color(
    0xFF4C4C4C,
  ); // Gray 70 Hover
  static const Color gray10ButtonSecondaryActive = Color(0xFF6F6F6F); // Gray 60
  static const Color gray10ButtonTertiary = Color(0xFFC1F879); // Brand green
  static const Color gray10ButtonTertiaryHover = Color(
    0xFF5C9E00,
  ); // Green 60
  static const Color gray10ButtonTertiaryActive = Color(0xFF4A7F00); // Green 70
  static const Color gray10ButtonDangerPrimary = Color(0xFFDA1E28); // Red 60
  static const Color gray10ButtonDangerPrimaryHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover
  static const Color gray10ButtonDangerPrimaryActive = Color(
    0xFF750E13,
  ); // Red 80
  static const Color gray10ButtonDangerTertiary = Color(0xFFDA1E28); // Red 60
  static const Color gray10ButtonDangerTertiaryHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover
  static const Color gray10ButtonDangerTertiaryActive = Color(
    0xFF750E13,
  ); // Red 80
  static const Color gray10ButtonDangerGhost = Color(0xFFDA1E28); // Red 60
  static const Color gray10ButtonDangerGhostHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover
  static const Color gray10ButtonGhost = Color(0xFF393939); // Gray 70
  static const Color gray10ButtonGhostHover = Color(
    0xFF4C4C4C,
  ); // Gray 70 Hover
  static const Color gray10ButtonGhostActive = Color(0xFF6F6F6F); // Gray 60

  // 3. Grey 90 Theme (Inverted Colors)
  static const Color gray90ButtonPrimary = Color(0xFFC1F879); // Brand green
  static const Color gray90ButtonPrimaryHover = Color(
    0xFF5C9E00,
  ); // Green 60
  static const Color gray90ButtonPrimaryActive = Color(0xFF4A7F00); // Green 70
  static const Color gray90ButtonSecondary = Color(
    0xFF6F6F6F,
  ); // Gray 60 (Dark mode secondary)
  static const Color gray90ButtonSecondaryHover = Color(
    0xFF5E5E5E,
  ); // Gray 60 Hover
  static const Color gray90ButtonSecondaryActive = Color(0xFF393939); // Gray 70
  static const Color gray90ButtonTertiary = Color(
    0xFFFFFFFF,
  ); // White (Dark mode tertiary)
  static const Color gray90ButtonTertiaryHover = Color(
    0xFFF4F4F4,
  ); // Gray 10 Hover
  static const Color gray90ButtonTertiaryActive = Color(0xFFE0E0E0); // Gray 20
  static const Color gray90ButtonDangerPrimary = Color(0xFFDA1E28); // Red 60
  static const Color gray90ButtonDangerPrimaryHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover
  static const Color gray90ButtonDangerPrimaryActive = Color(
    0xFF750E13,
  ); // Red 80
  static const Color gray90ButtonDangerTertiary = Color(
    0xFFFF8389,
  ); // Red 30 (Dark mode danger tertiary)
  static const Color gray90ButtonDangerTertiaryHover = Color(
    0xFFFF5B61,
  ); // Red 30 Hover
  static const Color gray90ButtonDangerTertiaryActive = Color(
    0xFFFA4D56,
  ); // Red 50
  static const Color gray90ButtonDangerGhost = Color(0xFFFF8389); // Red 30
  static const Color gray90ButtonDangerGhostHover = Color(
    0xFFFF5B61,
  ); // Red 30 Hover
  static const Color gray90ButtonGhost = Color(0xFFFFFFFF); // White
  static const Color gray90ButtonGhostHover = Color(
    0xFFF4F4F4,
  ); // Gray 10 Hover
  static const Color gray90ButtonGhostActive = Color(0xFFE0E0E0); // Gray 20

  // 4. Grey 100 Theme (Inverted Colors)
  static const Color gray100ButtonPrimary = Color(0xFFC1F879); // Brand green
  static const Color gray100ButtonPrimaryHover = Color(
    0xFF5C9E00,
  ); // Green 60
  static const Color gray100ButtonPrimaryActive = Color(0xFF4A7F00); // Green 70
  static const Color gray100ButtonSecondary = Color(0xFF6F6F6F); // Gray 60
  static const Color gray100ButtonSecondaryHover = Color(
    0xFF5E5E5E,
  ); // Gray 60 Hover
  static const Color gray100ButtonSecondaryActive = Color(
    0xFF393939,
  ); // Gray 70
  static const Color gray100ButtonTertiary = Color(0xFFFFFFFF); // White
  static const Color gray100ButtonTertiaryHover = Color(
    0xFFF4F4F4,
  ); // Gray 10 Hover
  static const Color gray100ButtonTertiaryActive = Color(0xFFE0E0E0); // Gray 20
  static const Color gray100ButtonDangerPrimary = Color(0xFFDA1E28); // Red 60
  static const Color gray100ButtonDangerPrimaryHover = Color(
    0xFFBA1B23,
  ); // Red 60 Hover
  static const Color gray100ButtonDangerPrimaryActive = Color(
    0xFF750E13,
  ); // Red 80
  static const Color gray100ButtonDangerTertiary = Color(0xFFFF8389); // Red 30
  static const Color gray100ButtonDangerTertiaryHover = Color(
    0xFFFF5B61,
  ); // Red 30 Hover
  static const Color gray100ButtonDangerTertiaryActive = Color(
    0xFFFA4D56,
  ); // Red 50
  static const Color gray100ButtonDangerGhost = Color(0xFFFF8389); // Red 30
  static const Color gray100ButtonDangerGhostHover = Color(
    0xFFFF5B61,
  ); // Red 30 Hover
  static const Color gray100ButtonGhost = Color(0xFFFFFFFF); // White
  static const Color gray100ButtonGhostHover = Color(
    0xFFF4F4F4,
  ); // Gray 10 Hover
  static const Color gray100ButtonGhostActive = Color(0xFFE0E0E0); // Gray 20
}
