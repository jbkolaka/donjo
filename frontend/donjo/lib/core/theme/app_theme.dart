import 'package:flutter/material.dart';

import '../motion/app_motion.dart';
import 'colour/appbackground_theme.dart';
import 'colour/appborder_theme.dart';
import 'colour/appbutton_theme.dart';
import 'colour/appfield_theme.dart';
import 'colour/applayer_theme.dart';
import 'colour/applayeraccent_theme.dart';
import 'colour/applink_theme.dart';
import 'colour/apptext_theme.dart';
import 'effects/border_interactive.dart';
import 'effects/shaddow_effects.dart';
import 'spacing/app_spacing.dart';
import 'typography/app_typography.dart';

/// Root theme for Fuko.
///
/// Consumes the design-system tokens from [core/theme/colour] (colour),
/// [core/motion/app_motion] (motion) and [core/theme/typography] (typography)
/// so the app uses a single, consistent design system instead of relying on
/// the auto-generated Material 3 colour scheme from a seed colour.
class AppTheme {
  const AppTheme._();

  /// Light theme backed by the White / Gray-10 design tokens.
  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: AppButtonColors.whiteButtonPrimary,
      onPrimary: AppTextColors.whiteTextOnColor,
      secondary: AppButtonColors.whiteButtonSecondary,
      onSecondary: AppTextColors.whiteTextOnColor,
      error: AppTextColors.whiteTextError,
      onError: AppTextColors.whiteTextOnColor,
      surface: AppLayerColors.lightStyle01,
      onSurface: AppTextColors.whiteTextPrimary,
      surfaceContainerHighest: AppLayerColors.lightStyle04,
      onSurfaceVariant: AppTextColors.whiteTextSecondary,
      outline: AppBorderColors.lightBorderSubtle01,
      outlineVariant: AppBorderColors.lightBorderSubtle00,
      inverseSurface: AppBackgroundColors.lightBackgroundInverse,
      onInverseSurface: AppTextColors.whiteTextOnInverse,
      primaryContainer: AppLayerAccentColors.lightAccent01,
      onPrimaryContainer: AppTextColors.whiteTextPrimary,
      secondaryContainer: AppButtonColors.whiteButtonSecondary,
      onSecondaryContainer: AppTextColors.whiteTextOnColor,
      tertiary: AppButtonColors.whiteButtonTertiary,
      onTertiary: AppTextColors.whiteTextOnColor,
    ),
  );

  /// Dark theme backed by the Gray-100 design tokens.
  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: AppButtonColors.gray100ButtonPrimary,
      onPrimary: AppTextColors.gray100TextOnColor,
      secondary: AppButtonColors.gray100ButtonSecondary,
      onSecondary: AppTextColors.gray100TextOnColor,
      error: AppTextColors.gray100TextError,
      onError: AppTextColors.gray100TextOnColor,
      surface: AppLayerColors.gray100Style01,
      onSurface: AppTextColors.gray100TextPrimary,
      surfaceContainerHighest: AppLayerColors.gray100Style04,
      onSurfaceVariant: AppTextColors.gray100TextSecondary,
      outline: AppBorderColors.gray100BorderSubtle01,
      outlineVariant: AppBorderColors.gray100BorderSubtle00,
      inverseSurface: AppLayerColors.gray100Style06,
      onInverseSurface: AppTextColors.gray100TextOnInverse,
      primaryContainer: AppLayerAccentColors.gray100Accent01,
      onPrimaryContainer: AppTextColors.gray100TextPrimary,
      secondaryContainer: AppButtonColors.gray100ButtonSecondary,
      onSecondaryContainer: AppTextColors.gray100TextOnColor,
      tertiary: AppButtonColors.gray100ButtonTertiary,
      onTertiary: AppTextColors.gray100TextOnColor,
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    final bool isLight = brightness == Brightness.light;

    // Typography drives the text theme from the design scale.
    final AppTextColorSet textColors = isLight
        ? const AppTextColorSet.white()
        : const AppTextColorSet.gray100();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isLight
          ? AppBackgroundColors.lightBackground
          : AppBackgroundColors.darkBackground,

      textTheme: AppTypography.textTheme(
        primary: textColors.primary,
        secondary: textColors.secondary,
      ).apply(
        bodyColor: textColors.primary,
        displayColor: textColors.primary,
      ),

      // Motion tokens feed both page transitions and interaction timings.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // Expressive entrance curve feeds every Android route transition.
          TargetPlatform.android: _AppPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,

      inputDecorationTheme: _inputDecoration(
        colors: isLight
            ? const AppFieldColorSet.white()
            : const AppFieldColorSet.gray100(),
        interactiveBorder: AppInteractiveBorders.focusBlue,
      ),

      elevatedButtonTheme: _elevatedButtonTheme(
        primary: scheme.primary,
        onPrimary: scheme.onPrimary,
      ),
      outlinedButtonTheme: _outlinedButtonTheme(
        foreground: scheme.primary,
        outline: scheme.outline,
      ),
      textButtonTheme: _textButtonTheme(
        foreground: AppLinkColors.whiteLinkPrimary,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.snackBar)),
        ),
      ),

      // Overlay surfaces take their depth from the shadow tokens rather than
      // Material's default elevation ramp.
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppShadows.menuShadowColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppShadows.menuShadowColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppShadows.menuShadowColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppSizes.hairline,
        space: AppSpacing.spacing04,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
    );
  }

  static InputDecorationTheme _inputDecoration({
    required AppFieldColorSet colors,
    required Color interactiveBorder,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.field,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing05,
        vertical: AppSpacing.spacing05,
      ),
      hintStyle: TextStyle(color: colors.hint),
      labelStyle: TextStyle(color: colors.hint),
      errorStyle: TextStyle(color: colors.error),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: colors.enabledBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(
          color: interactiveBorder,
          width: AppSizes.focusRing,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        borderSide: BorderSide(
          color: colors.error,
          width: AppSizes.focusRing,
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({
    required Color primary,
    required Color onPrimary,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(double.infinity, AppSizes.control),
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppTypography.labelLargeSize,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required Color foreground,
    required Color outline,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSizes.control),
        foregroundColor: foreground,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppTypography.labelLargeSize,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme({required Color foreground}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppTypography.labelMediumSize,
        ),
      ),
    );
  }
}

/// Custom page transition that applies the expressive standard easing
/// (cubic-bezier(0.4, 0.14, 0.3, 1)) over the 400ms slow-01 duration, matching
/// the [AppMotion] tokens.
class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeExpressiveStandard,
      reverseCurve: AppMotion.easeProductiveExit,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Small adapter that picks the correct token set per brightness.
abstract class AppTextColorSet {
  const AppTextColorSet();

  Color get primary;
  Color get secondary;
  Color get hint;
  Color get error;

  const factory AppTextColorSet.white() = _WhiteTextColorSet;
  const factory AppTextColorSet.gray100() = _Gray100TextColorSet;
}

class _WhiteTextColorSet extends AppTextColorSet {
  const _WhiteTextColorSet();

  @override
  Color get primary => AppTextColors.whiteTextPrimary;

  @override
  Color get secondary => AppTextColors.whiteTextSecondary;

  @override
  Color get hint => AppTextColors.whiteTextPlaceholder;

  @override
  Color get error => AppTextColors.whiteTextError;
}

class _Gray100TextColorSet extends AppTextColorSet {
  const _Gray100TextColorSet();

  @override
  Color get primary => AppTextColors.gray100TextPrimary;

  @override
  Color get secondary => AppTextColors.gray100TextSecondary;

  @override
  Color get hint => AppTextColors.gray100TextPlaceholder;

  @override
  Color get error => AppTextColors.gray100TextError;
}

/// Small adapter exposing the field colours used by the input theme.
abstract class AppFieldColorSet {
  const AppFieldColorSet();

  Color get field;
  Color get hint;
  Color get error;
  Color get enabledBorder;

  const factory AppFieldColorSet.white() = _WhiteFieldColorSet;
  const factory AppFieldColorSet.gray100() = _Gray100FieldColorSet;
}

class _WhiteFieldColorSet extends AppFieldColorSet {
  const _WhiteFieldColorSet();

  @override
  Color get field => AppFieldColors.lightField02;

  @override
  Color get hint => AppTextColors.whiteTextPlaceholder;

  @override
  Color get error => AppTextColors.whiteTextError;

  @override
  Color get enabledBorder => AppBorderColors.lightBorderSubtle01;
}

class _Gray100FieldColorSet extends AppFieldColorSet {
  const _Gray100FieldColorSet();

  @override
  Color get field => AppFieldColors.gray100Field01;

  @override
  Color get hint => AppTextColors.gray100TextPlaceholder;

  @override
  Color get error => AppTextColors.gray100TextError;

  @override
  Color get enabledBorder => AppBorderColors.gray100BorderSubtle01;
}
