import 'package:flutter/material.dart';

/// Type scale for the Donjo design system.
///
/// Five sizes and three weights. Instagram ships roughly this much and no
/// more — the discipline is the design. Two habits are borrowed from it:
///
///   * Headlines are heavy (w700) with *negative* letter-spacing. Bold type at
///     24px looks loose at default tracking; pulling it in makes a title read
///     as one object.
///   * Secondary copy drops a size *and* a colour, never just a colour. A grey
///     15px line next to a black 15px line reads as broken, not subordinate.
///
/// Line heights are expressed as `px / fontSize` so the intended leading is
/// visible at the call site.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      // Brand wordmark.
      displaySmall: TextStyle(
        fontSize: 32,
        height: 36 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 32 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primary,
      ),
      // Screen titles: 'Welcome back', 'Enter your email'.
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 28 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 24 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primary,
      ),
      // Section headers inside a card or list.
      titleMedium: TextStyle(
        fontSize: 16,
        height: 20 / 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primary,
      ),
      // Input text and prominent body copy.
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      // Supporting lines, helper text, captions.
      bodySmall: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      // Primary button label.
      labelLarge: TextStyle(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primary,
      ),
      // Inline links.
      labelMedium: TextStyle(
        fontSize: 14,
        height: 18 / 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: secondary,
      ),
    );
  }
}
