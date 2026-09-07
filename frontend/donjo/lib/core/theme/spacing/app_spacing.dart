/// Spacing, radius and size tokens for the Donj design system.
///
/// The scale follows the IBM Carbon Design System ($spacing-01 to $spacing-13).
/// It is based on a 2px grid, where the base unit is 2px (0.125rem).
///
/// Two rules travel with it, and they matter more than the numbers:
///
///   * Elements inside one logical group sit [xs]–[md] apart (4–12pt).
///   * Separate groups sit [xl]–[xxl] apart (24–32pt).
///
/// That contrast — tight within, generous between — is what makes an Instagram
/// form read as a few calm blocks instead of an evenly spaced list of widgets.
/// Screens should reference the semantic aliases ([screenGutter], [fieldGap],
/// …) rather than the raw steps, so a rhythm change happens in one place.
class AppSpacing {
  const AppSpacing._();

  // Raw Scale (Matching the image exactly)
  static const double spacing01 = 2; // 0.125rem / 2px
  static const double spacing02 = 4; // 0.25rem / 4px
  static const double spacing03 = 8; // 0.5rem / 8px
  static const double spacing04 = 12; // 0.75rem / 12px
  static const double spacing05 = 16; // 1rem / 16px
  static const double spacing06 = 24; // 1.5rem / 24px
  static const double spacing07 = 32; // 2rem / 32px
  static const double spacing08 = 40; // 2.5rem / 40px
  static const double spacing09 = 48; // 3rem / 48px
  static const double spacing10 = 64; // 4rem / 64px
  static const double spacing11 = 80; // 5rem / 80px
  static const double spacing12 = 96; // 6rem / 96px
  static const double spacing13 = 160; // 10rem / 160px

  // Semantic Aliases (Mapped to the new raw scale)

  /// Horizontal inset for every auth screen. Instagram's signup steps use the
  /// same 24pt gutter for their left-aligned title + field + CTA layout.
  static const double screenGutter = spacing06; // 24

  /// Gap between the back affordance and the screen title.
  static const double backToTitle = spacing06; // 24

  /// Gap between a title and its supporting line — tight, they are one block.
  static const double titleToSubtitle = spacing03; // 8

  /// Gap between the title block and the first field.
  static const double titleToBody = spacing07; // 32

  /// Gap between two stacked fields in the same form.
  static const double fieldGap = spacing04; // 12

  /// Gap between the last field and the primary action.
  static const double bodyToAction = spacing06; // 24

  /// Gap between the primary action and any trailing prompt link.
  static const double actionToPrompt = spacing06; // 24
}

class AppRadius {
  const AppRadius._();

  static const double field = 6;
  static const double button = 8;
  static const double card = 12;
  static const double snackBar = 8;

  /// Fully rounded: pills, chips, circular affordances. Any value larger
  /// than half the element's height clamps to a semicircle.
  static const double pill = 999;
}

class AppSizes {
  const AppSizes._();
  static const double control = 48;

  static const double logoSmall = 40;
  static const double logoLarge = 64;

  static const double hairline = 1;
  static const double focusRing = 1.5;

  static const double formMaxWidth = 400;
}
