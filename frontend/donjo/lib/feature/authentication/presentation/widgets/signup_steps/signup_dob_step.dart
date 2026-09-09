library;

import 'package:flutter/material.dart';
import 'package:donjo/core/motion/app_motion.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_step_container.dart';

class SignUpDobStep extends StatelessWidget {
  const SignUpDobStep({
    super.key,
    required this.dobText,
    required this.errorText,
    required this.busy,
    required this.onTapPicker,
  });

  final String dobText;
  final String? errorText;
  final bool busy;
  final VoidCallback onTapPicker;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasValue = dobText.isNotEmpty;

    return SignUpStepContainer(
      key: const ValueKey('step_dob'),
      eyebrow: 'Step 5 of 6 • Birthday',
      title: "What's your date of birth?",
      subtitle:
          'Providing your birthday helps verify your age for ticket tiers. You must be at least 13 years old. This won’t be displayed publicly.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: busy ? null : onTapPicker,
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: AnimatedContainer(
                duration: AppMotion.durationModerate01,
                curve: AppMotion.easeProductiveEntrance,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing05,
                  vertical: AppSpacing.spacing05,
                ),
                decoration: BoxDecoration(
                  color: p.field,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(
                    color: errorText != null
                        ? p.error
                        : (hasValue ? p.buttonPrimary : p.border),
                    width: errorText != null
                        ? AppSizes.focusRing
                        : AppSizes.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 22,
                      color: hasValue ? p.buttonPrimary : p.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.spacing04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasValue ? 'Date of birth' : 'Select your birthday',
                            style: context.appText.labelSmall.copyWith(
                              color: hasValue
                                  ? p.textSecondary
                                  : p.textPlaceholder,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasValue ? dobText : 'YYYY-MM-DD',
                            style: context.appText.titleMedium.copyWith(
                              color: hasValue
                                  ? p.textPrimary
                                  : p.textPlaceholder,
                              fontWeight: hasValue
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.spacing02,
                left: AppSpacing.spacing01,
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: p.error),
                  const SizedBox(width: AppSpacing.spacing02),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: context.appText.labelSmall.copyWith(
                        color: p.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
