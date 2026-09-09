library;

import 'package:flutter/material.dart';
import 'package:donjo/core/motion/app_motion.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';

/// IBM Carbon Design System primary action button.
class DonjoPrimaryButton extends StatelessWidget {
  const DonjoPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;

    final Color bgColor = enabled
        ? p.buttonPrimary
        : p.buttonPrimary.withValues(alpha: 0.38);
    final Color textColor = p.isDark
        ? const Color(0xFF161616)
        : const Color(0xFF161616);

    final button = AnimatedContainer(
      duration: AppMotion.durationFast02,
      curve: AppMotion.easeProductiveStandard,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: p.buttonPrimary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          splashColor: Colors.black.withValues(alpha: 0.1),
          highlightColor: Colors.black.withValues(alpha: 0.05),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.control),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing06,
              vertical: AppSpacing.spacing04,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: AppMotion.durationFast02,
              child: loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: expand
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: context.appText.button.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: AppSpacing.spacing03),
                          Icon(icon, size: 18, color: textColor),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    if (expand) return SizedBox(width: double.infinity, child: button);
    return button;
  }
}

/// Carbon Design System ghost (text/outline) button.
class DonjoGhostButton extends StatelessWidget {
  const DonjoGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing05,
            vertical: AppSpacing.spacing03,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: p.link),
                const SizedBox(width: AppSpacing.spacing02),
              ],
              Text(
                label,
                style: context.appText.labelMedium.copyWith(
                  color: p.link,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carbon Design System high-contrast section / step eyebrow badge.
class DonjoEyebrow extends StatelessWidget {
  const DonjoEyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing03,
        vertical: AppSpacing.spacing01 + 2,
      ),
      decoration: BoxDecoration(
        color: p.buttonPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: p.buttonPrimary.withValues(alpha: 0.35),
          width: AppSizes.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: p.buttonPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing02 + 2),
          Text(
            label.toUpperCase(),
            style: context.appText.eyebrow.copyWith(
              color: p.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carbon Inline Notification (Error/Banner).
class DonjoErrorBanner extends StatelessWidget {
  const DonjoErrorBanner({
    super.key,
    required this.message,
    this.title,
    this.onClose,
  });

  final String message;
  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        decoration: BoxDecoration(
          color: p.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(
            color: p.error.withValues(alpha: 0.3),
            width: AppSizes.hairline,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Carbon Accent Strip
              Container(width: 3.5, color: p.error),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing04,
                    vertical: AppSpacing.spacing04,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 20,
                        color: p.error,
                      ),
                      const SizedBox(width: AppSpacing.spacing03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null) ...[
                              Text(
                                title!,
                                style: context.appText.labelLarge.copyWith(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              message,
                              style: context.appText.bodySmall.copyWith(
                                color: p.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onClose != null) ...[
                        const SizedBox(width: AppSpacing.spacing02),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carbon-styled success inline banner.
class DonjoSuccessBanner extends StatelessWidget {
  const DonjoSuccessBanner({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        decoration: BoxDecoration(
          color: p.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.field),
          border: Border.all(
            color: p.success.withValues(alpha: 0.3),
            width: AppSizes.hairline,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Carbon Accent Strip
              Container(width: 3.5, color: p.success),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing04,
                    vertical: AppSpacing.spacing04,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: p.success,
                      ),
                      const SizedBox(width: AppSpacing.spacing03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null) ...[
                              Text(
                                title!,
                                style: context.appText.labelLarge.copyWith(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              message,
                              style: context.appText.bodySmall.copyWith(
                                color: p.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// High-tech Carbon 2x Page Container with responsive width clamping and smooth scrolling.
class DonjoPage extends StatelessWidget {
  const DonjoPage({
    super.key,
    required this.child,
    this.scrollable = true,
    this.maxWidth = 480,
  });

  final Widget child;
  final bool scrollable;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
            vertical: AppSpacing.spacing06,
          ),
          child: child,
        ),
      ),
    );

    if (!scrollable) {
      return body;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: body,
    );
  }
}

/// Carbon-styled Live Password Strength Meter.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[a-z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password) ||
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      s++;
    }
    return s;
  }

  String _label(BuildContext context) {
    return switch (_score) {
      0 => 'Enter password',
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Strong',
      _ => '',
    };
  }

  Color _color(AppPalette p) {
    return switch (_score) {
      0 => p.border,
      1 => p.error,
      2 => p.warning,
      3 => p.info,
      4 => p.success,
      _ => p.border,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final score = _score;
    final color = _color(p);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password strength',
              style: context.appText.labelSmall.copyWith(
                color: p.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              _label(context),
              style: context.appText.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing02),
        Row(
          children: List.generate(4, (index) {
            final active = index < score;
            return Expanded(
              child: AnimatedContainer(
                duration: AppMotion.durationFast02,
                curve: AppMotion.easeProductiveEntrance,
                height: 3.5,
                margin: EdgeInsets.only(
                  right: index < 3 ? AppSpacing.spacing02 : 0,
                ),
                decoration: BoxDecoration(
                  color: active ? color : p.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
