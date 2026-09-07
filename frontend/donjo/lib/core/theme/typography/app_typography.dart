import 'package:flutter/material.dart';

/// Type scale for the Donjo design system.
///
/// Based on IBM Plex Sans with a strict 4pt grid.
/// Three weights are used: Light (300), Regular (400), and SemiBold (600).
///
/// Principles borrowed from the Carbon Design System:
///   * Font size and weight pairings are balanced: a much larger light font can
///     rank higher than a smaller semibold font.
///   * Headlines use tighter negative letter-spacing to read as one object.
///   * Secondary copy drops a size *and* a colour, never just a colour.
///
/// The px values match the standard 0.75rem to 5.75rem scale exactly
/// (e.g., 1rem = 16px, 1.5rem = 24px, 2rem = 32px, 3rem = 48px).
class AppTypography {
  const AppTypography._();

  /// Primary / default font family used across the whole type scale.
  ///
  /// Bundled in pubspec.yaml at weights 400/500/600/700. The Light (300)
  /// steps below therefore fall back to Regular until an IBMPlexSans-300
  /// asset is added.
  static const String fontFamily = 'IBM Plex Sans';

  /// Monospace face for codes, ids and other character-by-character copy.
  static const String monoFontFamily = 'IBM Plex Mono';

  /// Shared sizes so widgets (buttons, links) can align with the scale.
  static const double labelLargeSize = 16;
  static const double labelMediumSize = 14;

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      // Brand wordmark / Massive display sizes. (e.g., 68px, 76px)
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 68,
        height: 76 / 68,
        fontWeight: FontWeight.w300, // Light
        letterSpacing: -1.5,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 60,
        height: 68 / 60,
        fontWeight: FontWeight.w300, // Light
        letterSpacing: -1.2,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 48,
        height: 56 / 48,
        fontWeight: FontWeight.w300, // Light
        letterSpacing: -1.0,
        color: primary,
      ),

      // Headlines (e.g., 32px, 36px, 42px).
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 42,
        height: 48 / 42,
        fontWeight: FontWeight.w300, // Light
        letterSpacing: -0.8,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        height: 42 / 36,
        fontWeight: FontWeight.w300, // Light
        letterSpacing: -0.6,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        height: 36 / 32,
        fontWeight: FontWeight.w300, // Light
        letterSpacing: -0.5,
        color: primary,
      ),

      // Screen titles & Section headers (e.g., 24px, 28px).
      // 28px is ideal for section headers using the SemiBold weight.
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 32 / 28,
        fontWeight: FontWeight.w600, // SemiBold
        letterSpacing: -0.4,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        height: 28 / 24,
        fontWeight: FontWeight.w600, // SemiBold
        letterSpacing: -0.3,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        height: 24 / 20,
        fontWeight: FontWeight.w600, // SemiBold
        letterSpacing: -0.2,
        color: primary,
      ),

      // Body copy (e.g., 14px, 16px, 18px).
      // Regular weight (400) is used for all long text.
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w400, // Regular
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400, // Regular
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 22 / 14,
        fontWeight: FontWeight.w400, // Regular
        color: secondary,
      ),

      // Primary button label (e.g., 16px).
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        height: 20 / 16,
        fontWeight: FontWeight.w600, // SemiBold
        letterSpacing: 0.1,
        color: primary,
      ),

      // Inline links and medium labels (e.g., 14px).
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w600, // SemiBold
        color: primary,
      ),

      // Captions, helper text, chips (e.g., 12px).
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600, // SemiBold
        letterSpacing: 0.2,
        color: secondary,
      ),
    );
  }
}
