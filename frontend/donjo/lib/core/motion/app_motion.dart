import 'package:flutter/material.dart';

/// Motion and Duration tokens for the Fuko design system.
///
/// Based on the IBM Carbon Design System.
/// Two sets of easing curves are provided: [Productive] (tight, fast, for UI)
/// and [Expressive] (smoother, slower, for larger movements and expressive moments).
///
/// Durations are broken down into micro (fast), moderate, and slow to map
/// perfectly to standard interaction types.
class AppMotion {
  const AppMotion._();

  // 1. Duration Tokens (in milliseconds)

  /// Micro-interactions such as button and toggle.
  static const Duration durationFast01 = Duration(milliseconds: 70);

  /// Micro-interactions such as fade.
  static const Duration durationFast02 = Duration(milliseconds: 110);

  /// Micro-interactions, small expansion, short distance movements.
  static const Duration durationModerate01 = Duration(milliseconds: 150);

  /// Expansion, system communication, toast.
  static const Duration durationModerate02 = Duration(milliseconds: 240);

  /// Large expansion, important system notifications.
  static const Duration durationSlow01 = Duration(milliseconds: 400);

  /// Background dimming.
  static const Duration durationSlow02 = Duration(milliseconds: 700);

  // 2. Easing Curves - Productive Set

  /// Productive Standard easing: cubic-bezier(0.2, 0, 0.38, 0.9)
  static const Curve easeProductiveStandard = Cubic(0.2, 0.0, 0.38, 0.9);

  /// Productive Entrance easing: cubic-bezier(0, 0, 0.38, 0.9)
  static const Curve easeProductiveEntrance = Cubic(0.0, 0.0, 0.38, 0.9);

  /// Productive Exit easing: cubic-bezier(0.2, 0, 1, 0.9)
  static const Curve easeProductiveExit = Cubic(0.2, 0.0, 1.0, 0.9);

  // 3. Easing Curves - Expressive Set

  /// Expressive Standard easing: cubic-bezier(0.4, 0.14, 0.3, 1)
  static const Curve easeExpressiveStandard = Cubic(0.4, 0.14, 0.3, 1.0);

  /// Expressive Entrance easing: cubic-bezier(0, 0, 0.3, 1)
  static const Curve easeExpressiveEntrance = Cubic(0.0, 0.0, 0.3, 1.0);

  /// Expressive Exit easing: cubic-bezier(0.4, 0.14, 1, 1)
  static const Curve easeExpressiveExit = Cubic(0.4, 0.14, 1.0, 1.0);
}
