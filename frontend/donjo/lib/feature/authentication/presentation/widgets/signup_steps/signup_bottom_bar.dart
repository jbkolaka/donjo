library;

import 'package:flutter/material.dart';
import 'package:donjo/core/motion/app_motion.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';

class SignUpBottomBar extends StatelessWidget {
  const SignUpBottomBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.busy,
    required this.canProceed,
    required this.onNext,
    required this.onSignInTap,
  });

  final int currentStep;
  final int totalSteps;
  final bool busy;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isLastStep = currentStep == totalSteps - 1;

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
          // Step dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final active = index == currentStep;
              final completed = index < currentStep;
              return AnimatedContainer(
                duration: AppMotion.durationFast02,
                curve: AppMotion.easeProductiveEntrance,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 4,
                width: active ? 22 : 6,
                decoration: BoxDecoration(
                  color: active
                      ? p.buttonPrimary
                      : (completed
                            ? p.buttonPrimary.withValues(alpha: 0.4)
                            : p.borderSubtle),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.spacing04),

          // Primary CTA Button
          DonjoPrimaryButton(
            label: isLastStep ? 'Create account' : 'Next',
            loading: busy,
            icon: isLastStep
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            onPressed: busy || !canProceed ? null : onNext,
          ),
          const SizedBox(height: AppSpacing.spacing03),

          // Sign In Option
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
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
