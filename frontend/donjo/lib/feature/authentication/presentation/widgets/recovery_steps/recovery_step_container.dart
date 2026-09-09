library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/fade_slide_in.dart';

/// Helper container for individual recovery wizard steps.
class RecoveryStepContainer extends StatelessWidget {
  const RecoveryStepContainer({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenGutter,
        vertical: AppSpacing.spacing06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: FadeSlideIn.staggered([
          // Step Eyebrow Pill
          Align(alignment: Alignment.centerLeft, child: DonjoEyebrow(eyebrow)),
          const SizedBox(height: AppSpacing.spacing04),

          // Main Headline
          Text(
            title,
            style: context.appText.headlineLarge.copyWith(
              height: 1.15,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.8,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing03),

          // Subtitle / Explanatory Text
          Text(
            subtitle,
            style: context.appText.bodySmall.copyWith(
              color: p.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing08),

          // Step Content
          child,
          const SizedBox(height: AppSpacing.spacing06),
        ]),
      ),
    );
  }
}
