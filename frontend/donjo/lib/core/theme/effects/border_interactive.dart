import 'package:flutter/material.dart';

/// Interactive Border tokens for the Donj design system.
///
/// These tokens define borders based on states (Subtle, Strong, Focus, Selected,
/// Error, Disabled) and directional logic. Use the [AppInteractiveBorders.create]
/// method to build a specific border, or use the static constants for the
/// most common "all sides" scenarios.
class AppInteractiveBorders {
  const AppInteractiveBorders._();

  // 1. Base Colors from the palette
  static const Color subtleColor = Color(0xFFE0E0E0); // Gray 20
  static const Color strongColor = Color(0xFF8D8D8D); // Gray 50
  static const Color focusBlue = Color(0xFFC1F879); // Brand green
  static const Color interactiveBlue = Color(0xFFC1F879); // Brand green (Selected)
  static const Color errorRed = Color(0xFFDA1E28); // Support error Red 60
  static const Color disabledGray = Color(
    0xFF8D8D8D,
  ); // Gray 30 (Border color for disabled)

  // 2. Base Widths
  static const double standardWidth = 1;
  static const double focusWidth = 2;

  // 3. Dynamic Creator to match exact directional tokens
  /// Example: AppInteractiveBorders.create(
  ///   type: BorderType.focus,
  ///   sides: BorderSides.bottom,
  /// )
  static Border create({
    required BorderType type,
    BorderSides sides = BorderSides.all,
  }) {
    Color color;
    double width;

    switch (type) {
      case BorderType.subtle:
        color = subtleColor;
        width = standardWidth;
        break;
      case BorderType.strong:
        color = strongColor;
        width = standardWidth;
        break;
      case BorderType.focus:
        color = focusBlue;
        width = focusWidth;
        break;
      case BorderType.selected:
      case BorderType.selectedInverse:
        color = interactiveBlue;
        width = focusWidth;
        break;
      case BorderType.error:
        color = errorRed;
        width = standardWidth;
        break;
      case BorderType.disabled:
        color = disabledGray;
        width = standardWidth;
        break;
    }

    return Border(
      top: sides.top ? BorderSide(color: color, width: width) : BorderSide.none,
      right: sides.right
          ? BorderSide(color: color, width: width)
          : BorderSide.none,
      bottom: sides.bottom
          ? BorderSide(color: color, width: width)
          : BorderSide.none,
      left: sides.left
          ? BorderSide(color: color, width: width)
          : BorderSide.none,
    );
  }

  // 4. Common Pre-built Static Constants (All Sides)

  // Subtle
  static const Border subtleBorderAll = Border(
    top: BorderSide(color: subtleColor, width: standardWidth),
    right: BorderSide(color: subtleColor, width: standardWidth),
    bottom: BorderSide(color: subtleColor, width: standardWidth),
    left: BorderSide(color: subtleColor, width: standardWidth),
  );

  // Strong
  static const Border strongBorderAll = Border(
    top: BorderSide(color: strongColor, width: standardWidth),
    right: BorderSide(color: strongColor, width: standardWidth),
    bottom: BorderSide(color: strongColor, width: standardWidth),
    left: BorderSide(color: strongColor, width: standardWidth),
  );

  // Focus
  static const Border focusBorderAll = Border(
    top: BorderSide(color: focusBlue, width: focusWidth),
    right: BorderSide(color: focusBlue, width: focusWidth),
    bottom: BorderSide(color: focusBlue, width: focusWidth),
    left: BorderSide(color: focusBlue, width: focusWidth),
  );

  // Selected (Interactive)
  static const Border selectedBorderAll = Border(
    top: BorderSide(color: interactiveBlue, width: focusWidth),
    right: BorderSide(color: interactiveBlue, width: focusWidth),
    bottom: BorderSide(color: interactiveBlue, width: focusWidth),
    left: BorderSide(color: interactiveBlue, width: focusWidth),
  );

  // Error
  static const Border errorBorderAll = Border(
    top: BorderSide(color: errorRed, width: standardWidth),
    right: BorderSide(color: errorRed, width: standardWidth),
    bottom: BorderSide(color: errorRed, width: standardWidth),
    left: BorderSide(color: errorRed, width: standardWidth),
  );

  // Disabled
  static const Border disabledBorderAll = Border(
    top: BorderSide(color: disabledGray, width: standardWidth),
    right: BorderSide(color: disabledGray, width: standardWidth),
    bottom: BorderSide(color: disabledGray, width: standardWidth),
    left: BorderSide(color: disabledGray, width: standardWidth),
  );
}

/// Enum for the type of state border to draw.
enum BorderType {
  subtle,
  strong,
  focus,
  selected,
  selectedInverse,
  error,
  disabled,
}

/// Helper class to define which sides to draw for the [AppInteractiveBorders.create] method.
class BorderSides {
  const BorderSides._({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final bool top;
  final bool right;
  final bool bottom;
  final bool left;

  static const BorderSides all = BorderSides._(
    top: true,
    right: true,
    bottom: true,
    left: true,
  );
  static const BorderSides none = BorderSides._(
    top: false,
    right: false,
    bottom: false,
    left: false,
  );
  static const BorderSides topOnly = BorderSides._(
    top: true,
    right: false,
    bottom: false,
    left: false,
  );
  static const BorderSides rightOnly = BorderSides._(
    top: false,
    right: true,
    bottom: false,
    left: false,
  );
  static const BorderSides bottomOnly = BorderSides._(
    top: false,
    right: false,
    bottom: true,
    left: false,
  );
  static const BorderSides leftOnly = BorderSides._(
    top: false,
    right: false,
    bottom: false,
    left: true,
  );
  static const BorderSides topBottom = BorderSides._(
    top: true,
    right: false,
    bottom: true,
    left: false,
  );
  static const BorderSides leftRight = BorderSides._(
    top: false,
    right: true,
    bottom: false,
    left: true,
  );
}
