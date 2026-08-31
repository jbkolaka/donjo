/// Spacing, radius and size tokens for the Donj design system.
///
/// The scale is a strict 4pt grid — the same base unit Instagram builds on.
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

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Horizontal inset for every auth screen. Instagram's signup steps use the
  /// same 24pt gutter for their left-aligned title + field + CTA layout.
  static const double screenGutter = xl;

  /// Gap between the back affordance and the screen title.
  static const double backToTitle = xl;

  /// Gap between a title and its supporting line — tight, they are one block.
  static const double titleToSubtitle = sm;

  /// Gap between the title block and the first field.
  static const double titleToBody = xxl;

  /// Gap between two stacked fields in the same form.
  static const double fieldGap = md;

  /// Gap between the last field and the primary action.
  static const double bodyToAction = xl;

  /// Gap between the primary action and any trailing prompt link.
  static const double actionToPrompt = xl;
}

class AppRadius {
  const AppRadius._();

  static const double field = 6;
  static const double button = 8;
  static const double card = 12;
  static const double snackBar = 8;
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
