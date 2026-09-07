import 'package:flutter/material.dart';

/// Border 03 Tokens for the Donj design system.
///
/// These tokens define the 03 structural border variants.
/// Subtle borders use Gray 20, while Strong borders use Gray 50
/// (or Gray 10 when used on dark themes).
class AppBorders03 {
  const AppBorders03._();

  // 1. Color Definitions
  static const Color subtleColor = Color(0xFFE0E0E0); // Gray 20
  static const Color strongColor = Color(0xFF8D8D8D); // Gray 50
  static const Color darkStrongColor = Color(
    0xFFF4F4F4,
  ); // Gray 10 (Used in Dark Theme)

  // 2. Width Definition
  static const double width = 1;

  // 3. Dynamic Creator
  /// Creates a border based on the specific combination of sides.
  static Border create({
    bool top = false,
    bool right = false,
    bool bottom = false,
    bool left = false,
    Color color = subtleColor,
    double borderWidth = width,
  }) {
    return Border(
      top: top ? BorderSide(color: color, width: borderWidth) : BorderSide.none,
      right: right
          ? BorderSide(color: color, width: borderWidth)
          : BorderSide.none,
      bottom: bottom
          ? BorderSide(color: color, width: borderWidth)
          : BorderSide.none,
      left: left
          ? BorderSide(color: color, width: borderWidth)
          : BorderSide.none,
    );
  }

  // 4. Static constants for common use cases (Subtle - Gray 20)
  static const Border subtleBorderAll = Border(
    top: BorderSide(color: subtleColor, width: width),
    right: BorderSide(color: subtleColor, width: width),
    bottom: BorderSide(color: subtleColor, width: width),
    left: BorderSide(color: subtleColor, width: width),
  );

  static const Border subtleBorderTop = Border(
    top: BorderSide(color: subtleColor, width: width),
  );

  static const Border subtleBorderRight = Border(
    right: BorderSide(color: subtleColor, width: width),
  );

  static const Border subtleBorderBottom = Border(
    bottom: BorderSide(color: subtleColor, width: width),
  );

  static const Border subtleBorderLeft = Border(
    left: BorderSide(color: subtleColor, width: width),
  );

  static const Border subtleBorderTopBottom = Border(
    top: BorderSide(color: subtleColor, width: width),
    bottom: BorderSide(color: subtleColor, width: width),
  );

  static const Border subtleBorderLeftRight = Border(
    left: BorderSide(color: subtleColor, width: width),
    right: BorderSide(color: subtleColor, width: width),
  );

  // 5. Static constants for common use cases (Strong - Gray 50)
  static const Border strongBorderAll = Border(
    top: BorderSide(color: strongColor, width: width),
    right: BorderSide(color: strongColor, width: width),
    bottom: BorderSide(color: strongColor, width: width),
    left: BorderSide(color: strongColor, width: width),
  );

  static const Border strongBorderTop = Border(
    top: BorderSide(color: strongColor, width: width),
  );

  static const Border strongBorderRight = Border(
    right: BorderSide(color: strongColor, width: width),
  );

  static const Border strongBorderBottom = Border(
    bottom: BorderSide(color: strongColor, width: width),
  );

  static const Border strongBorderLeft = Border(
    left: BorderSide(color: strongColor, width: width),
  );

  static const Border strongBorderTopBottom = Border(
    top: BorderSide(color: strongColor, width: width),
    bottom: BorderSide(color: strongColor, width: width),
  );

  static const Border strongBorderLeftRight = Border(
    left: BorderSide(color: strongColor, width: width),
    right: BorderSide(color: strongColor, width: width),
  );

  // 6. Static constants for Dark Themes (Strong - Gray 10)
  // Note: The table lists "$border-strong-03(Gray 10)" as the unified border for dark themes.
  static const Border darkStrongBorderAll = Border(
    top: BorderSide(color: darkStrongColor, width: width),
    right: BorderSide(color: darkStrongColor, width: width),
    bottom: BorderSide(color: darkStrongColor, width: width),
    left: BorderSide(color: darkStrongColor, width: width),
  );

  static const Border darkStrongBorderTop = Border(
    top: BorderSide(color: darkStrongColor, width: width),
  );

  static const Border darkStrongBorderRight = Border(
    right: BorderSide(color: darkStrongColor, width: width),
  );

  static const Border darkStrongBorderBottom = Border(
    bottom: BorderSide(color: darkStrongColor, width: width),
  );

  static const Border darkStrongBorderLeft = Border(
    left: BorderSide(color: darkStrongColor, width: width),
  );

  static const Border darkStrongBorderTopBottom = Border(
    top: BorderSide(color: darkStrongColor, width: width),
    bottom: BorderSide(color: darkStrongColor, width: width),
  );

  static const Border darkStrongBorderLeftRight = Border(
    left: BorderSide(color: darkStrongColor, width: width),
    right: BorderSide(color: darkStrongColor, width: width),
  );
}
