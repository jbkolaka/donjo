library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';

class RecoveryBottomBar extends StatelessWidget {
  const RecoveryBottomBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.busy,
    required this.onNext,
    required this.onSignInTap,
  });

  final int currentStep;
  final int totalSteps;
  final bool busy;
  final VoidCallback onNext;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLastStep = currentStep == totalSteps - 1;
    final buttonLabel = switch (currentStep) {
      0 => 'Send reset link',
      1 => 'Continue',
      _ => 'Update password',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenGutter,
        vertical: AppSpacing.spacing04,
      ),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(
          top: BorderSide(
            color: p.borderSubtle.withValues(alpha: 0.2),
            width: AppSizes.hairline,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action CTA
          DonjoPrimaryButton(
            label: buttonLabel,
            loading: busy,
            icon: isLastStep
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            onPressed: busy ? null : onNext,
          ),
          const SizedBox(height: AppSpacing.spacing03),

          // Return to Sign In
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: context.appText.bodySmall.copyWith(
                  color: p.textSecondary,
                ),
              ),
              InkWell(
                onTap: onSignInTap,
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Sign in',
                    style: context.appText.labelMedium.copyWith(
                      color: p.link,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
