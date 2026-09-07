import 'package:flutter/material.dart';

import 'colour/appbackground_theme.dart';
import 'colour/appborder_theme.dart';
import 'colour/appbutton_theme.dart';
import 'colour/appfield_theme.dart';
import 'colour/applayer_theme.dart';
import 'colour/applayeraccent_theme.dart';
import 'colour/applink_theme.dart';
import 'colour/appsupport_theme.dart';
import 'colour/apptext_theme.dart';
import 'typography/app_typography.dart';

/// Resolved design-token palette for the current [Brightness] based on IBM Carbon Design System.
///
/// Everything the UI renders reads from [AppPalette] (or [ZoaPalette]) via
/// `context.palette` instead of hardcoding colors.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textPlaceholder,
    required this.textOnColor,
    required this.textOnInverse,
    required this.border,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderInteractive,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.link,
    required this.field,
    required this.fieldHover,
    required this.buttonPrimary,
    required this.buttonSecondary,
    required this.isDark,
  });

  final Color background;

  /// Raised surfaces — cards, sheets, panels.
  final Color surface;

  /// Quiet muted background behind fields and secondary blocks.
  final Color surfaceMuted;

  /// Wash used for chips, pills and highlighted rows.
  final Color accent;

  final Color textPrimary;
  final Color textSecondary;
  final Color textPlaceholder;
  final Color textOnColor;
  final Color textOnInverse;

  final Color border;
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderInteractive;

  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  final Color link;

  /// Text-field fill.
  final Color field;
  final Color fieldHover;

  final Color buttonPrimary;
  final Color buttonSecondary;

  final bool isDark;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark() : light();

  static AppPalette light() => const AppPalette(
    background: AppBackgroundColors.lightBackground,
    surface: AppLayerColors.lightStyle01,
    surfaceMuted: AppBackgroundColors.lightSurfaceMuted,
    accent: AppLayerAccentColors.lightAccent01,
    textPrimary: AppTextColors.whiteTextPrimary,
    textSecondary: AppTextColors.whiteTextSecondary,
    textPlaceholder: AppTextColors.whiteTextPlaceholder,
    textOnColor: AppTextColors.whiteTextOnColor,
    textOnInverse: AppTextColors.whiteTextOnInverse,
    border: AppBorderColors.lightBorderSubtle01,
    borderSubtle: AppBorderColors.lightBorderSubtle00,
    borderStrong: AppBorderColors.lightBorderStrong01,
    borderInteractive: AppBorderColors.lightBorderInteractive,
    error: AppSupportColors.lightError,
    success: AppSupportColors.lightSuccess,
    warning: AppSupportColors.lightWarning,
    info: AppSupportColors.lightInfo,
    link: AppLinkColors.whiteLinkPrimary,
    field: AppLayerColors.lightStyle01,
    fieldHover: AppFieldColors.lightFieldHover01,
    buttonPrimary: AppButtonColors.whiteButtonPrimary,
    buttonSecondary: AppButtonColors.whiteButtonSecondary,
    isDark: false,
  );

  static AppPalette dark() => const AppPalette(
    background: AppBackgroundColors.darkBackground,
    surface: AppLayerColors.gray100Style01,
    surfaceMuted: AppBackgroundColors.darkSurfaceMuted,
    accent: AppLayerAccentColors.gray100Accent01,
    textPrimary: AppTextColors.gray100TextPrimary,
    textSecondary: AppTextColors.gray100TextSecondary,
    textPlaceholder: AppTextColors.gray100TextPlaceholder,
    textOnColor: AppTextColors.gray100TextOnColor,
    textOnInverse: AppTextColors.gray100TextOnInverse,
    border: AppBorderColors.gray100BorderSubtle01,
    borderSubtle: AppBorderColors.gray100BorderSubtle00,
    borderStrong: AppBorderColors.gray100BorderStrong01,
    borderInteractive: AppBorderColors.gray100BorderInteractive,
    error: AppSupportColors.darkError,
    success: AppSupportColors.darkSuccess,
    warning: AppSupportColors.darkWarning,
    info: AppSupportColors.darkInfo,
    link: AppLinkColors.gray100LinkPrimary,
    field: AppFieldColors.gray100Field01,
    fieldHover: AppFieldColors.gray100FieldHover01,
    buttonPrimary: AppButtonColors.gray100ButtonPrimary,
    buttonSecondary: AppButtonColors.gray100ButtonSecondary,
    isDark: true,
  );
}

/// Backwards compatibility alias for [AppPalette].
typedef ZoaPalette = AppPalette;

/// Extension giving every widget easy typed access to `context.palette` and `context.appText`.
extension PaletteContext on BuildContext {
  AppPalette get palette => AppPalette.of(this);

  /// Non-null resolved text roles from the active [ThemeData].
  AppTextTheme get appText => AppTextTheme.of(Theme.of(this).textTheme);
}

/// Non-null type roles derived from the theme's [TextTheme] following IBM Carbon Type Scale.
class AppTextTheme {
  const AppTextTheme._(this._t);

  final TextTheme _t;

  static AppTextTheme of(TextTheme t) => AppTextTheme._(t);

  TextStyle get display => _t.displaySmall ?? _t.headlineMedium!;
  TextStyle get hero => _t.headlineLarge ?? _t.headlineMedium!;
  TextStyle get h1 => _t.headlineLarge ?? _t.headlineMedium!;
  TextStyle get h2 => _t.headlineMedium ?? _t.titleLarge!;
  TextStyle get h3 => _t.headlineSmall ?? _t.titleMedium!;
  TextStyle get cardTitle => _t.titleMedium ?? _t.titleSmall!;
  TextStyle get title => _t.titleMedium ?? _t.titleSmall!;
  TextStyle get lead => _t.bodyLarge ?? _t.bodyMedium!;
  TextStyle get body => _t.bodyMedium ?? _t.bodyLarge!;
  TextStyle get bodySoft => _t.bodySmall ?? _t.bodyMedium!;
  TextStyle get bodySm => _t.bodySmall ?? _t.bodyMedium!;
  TextStyle get label => _t.labelLarge ?? _t.labelMedium!;
  TextStyle get button => _t.labelLarge ?? _t.labelMedium!;
  TextStyle get kicker => _t.labelSmall ?? _t.labelMedium!;
  TextStyle get eyebrow => _t.labelSmall ?? _t.labelMedium!;

  /// Monospace body for tokens, codes, character-by-character copy.
  TextStyle get mono => (_t.bodyMedium ?? _t.bodyLarge!).copyWith(
    fontFamily: AppTypography.monoFontFamily,
  );
  TextStyle get tag => _t.labelSmall ?? _t.labelMedium!;
  TextStyle get statNum => _t.headlineMedium ?? _t.titleLarge!;
  TextStyle get code => (_t.headlineMedium ?? _t.titleLarge!).copyWith(
    fontFamily: AppTypography.monoFontFamily,
  );

  // Material slot names exposed non-null
  TextStyle get bodySmall => _t.bodySmall ?? _t.bodyMedium!;
  TextStyle get bodyMedium => _t.bodyMedium ?? _t.bodyLarge!;
  TextStyle get bodyLarge => _t.bodyLarge ?? _t.bodyMedium!;
  TextStyle get labelLarge => _t.labelLarge ?? _t.labelMedium!;
  TextStyle get labelMedium => _t.labelMedium ?? _t.labelSmall!;
  TextStyle get labelSmall => _t.labelSmall ?? _t.labelMedium!;
  TextStyle get headlineLarge => _t.headlineLarge ?? _t.headlineMedium!;
  TextStyle get headlineMedium => _t.headlineMedium ?? _t.headlineLarge!;
  TextStyle get headlineSmall => _t.headlineSmall ?? _t.titleLarge!;
  TextStyle get titleMedium => _t.titleMedium ?? _t.titleSmall!;
  TextStyle get titleLarge => _t.titleLarge ?? _t.headlineSmall!;
  TextStyle get titleSmall => _t.titleSmall ?? _t.titleMedium!;
  TextStyle get displaySmall => _t.displaySmall ?? _t.headlineLarge!;
  TextStyle get displayMedium => _t.displayMedium ?? _t.displaySmall!;
  TextStyle get displayLarge => _t.displayLarge ?? _t.displayMedium!;
}

/// Backwards compatibility alias for [AppTextTheme].
typedef ZoaText = AppTextTheme;
