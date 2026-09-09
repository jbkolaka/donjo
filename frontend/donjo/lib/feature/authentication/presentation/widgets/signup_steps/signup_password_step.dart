library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_step_container.dart';

class SignUpPasswordStep extends StatelessWidget {
  const SignUpPasswordStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.agreedToTerms,
    required this.busy,
    required this.onSubmitted,
    required this.onChanged,
    required this.onToggleTerms,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool agreedToTerms;
  final bool busy;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool?> onToggleTerms;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SignUpStepContainer(
      key: const ValueKey('step_password'),
      eyebrow: 'Step 6 of 6 • Password & Security',
      title: 'Create a password',
      subtitle:
          'Create a password with at least 8 characters to keep your tickets and wallet secure.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextField(
            controller: controller,
            focusNode: focusNode,
            label: 'Password',
            hint: 'Minimum 8 characters',
            isRequired: true,
            errorText: errorText,
            obscure: true,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: p.textSecondary,
            ),
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            enabled: !busy,
            onSubmitted: (_) => onSubmitted(),
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.spacing04),

          // Live Password Strength Indicator
          PasswordStrengthMeter(password: controller.text),
          const SizedBox(height: AppSpacing.spacing06),

          // Terms and Conditions Agreement
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: agreedToTerms,
                  activeColor: p.buttonPrimary,
                  checkColor: const Color(0xFF161616),
                  side: BorderSide(color: p.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: busy ? null : onToggleTerms,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing03),
              Expanded(
                child: Text(
                  'I agree to the Terms of Service, Privacy Policy, and Event Attendance Guidelines.',
                  style: context.appText.bodySmall.copyWith(
                    color: p.textSecondary,
                    fontSize: 13,
                    height: 1.35,
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
