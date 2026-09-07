import 'package:flutter/material.dart';

/// Grid and Breakpoint tokens for the Donjo design system.
///
/// Based on the IBM Carbon 2x Grid system.
/// The 2x Grid is a 16px base unit grid designed to maintain layout integrity
/// across mobile, tablet, and desktop screen sizes.
class AppGrid {
  const AppGrid._();

  /// The base 2x grid unit (16px) used to calculate all sizes.
  static const double baseUnit = 16;

  /// Standard padding for all grid containers (16px).
  static const double gridPadding = 16;

  // ==========================================
  // 1. Breakpoint Values (in px)
  // ==========================================
  static const double breakpointSmall = 320;
  static const double breakpointMedium = 672;
  static const double breakpointLarge = 1056;
  static const double breakpointXLarge = 1312;
  static const double breakpointMax = 1584;

  // ==========================================
  // 2. Column Counts
  // ==========================================
  static const int columnsSmall = 4;
  static const int columnsMedium = 8;
  static const int columnsLarge = 16;
  static const int columnsXLarge = 16;
  static const int columnsMax = 16;

  // ==========================================
  // 3. Gutters (Margins)
  // ==========================================
  static const double gutterSmall = 16;
  static const double gutterMedium = 16;
  static const double gutterLarge = 16;
  static const double gutterXLarge = 16;
  static const double gutterMax = 24;

  // ==========================================
  // 4. Maximum Auth Form Clamping
  // ==========================================
  static const double maxFormWidth = 480;

  // ==========================================
  // 5. Helper to get proper layout dimensions
  // ==========================================
  static double getMarginForWidth(double width) {
    if (width >= breakpointMax) return gutterMax;
    if (width >= breakpointXLarge) return gutterXLarge;
    if (width >= breakpointLarge) return gutterLarge;
    if (width >= breakpointMedium) return gutterMedium;
    return gutterSmall;
  }

  static int getColumnsForWidth(double width) {
    if (width >= breakpointLarge) return columnsLarge;
    if (width >= breakpointMedium) return columnsMedium;
    return columnsSmall;
  }

  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpointMedium;

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= breakpointMedium && width < breakpointLarge;
  }

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpointLarge;
}

/// A responsive container that adheres to the IBM Carbon 2x grid specification.
class CarbonGridContainer extends StatelessWidget {
  const CarbonGridContainer({
    super.key,
    required this.child,
    this.maxWidth = AppGrid.maxFormWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
    this.scrollable = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final margin = AppGrid.getMarginForWidth(width);
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: margin);

    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );

    if (scrollable) {
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(alignment: alignment, child: content),
              ),
            );
          },
        ),
      );
    }

    return SafeArea(
      child: Align(alignment: alignment, child: content),
    );
  }
}
