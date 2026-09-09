library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/recovery_steps/recovery_step_container.dart';

class RecoveryEmailStep extends StatelessWidget {
  const RecoveryEmailStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.busy,
    required this.onSubmitted,
    required this.onChanged,
    required this.onTokenShortcutTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool busy;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onTokenShortcutTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return RecoveryStepContainer(
      key: const ValueKey('reset_step_email'),
      eyebrow: 'Account Recovery',
      title: "Find your account",
      subtitle:
          'Enter the email address registered with your Donjo account to receive password reset instructions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: controller,
            focusNode: focusNode,
            label: 'Registered email address',
            hint: 'e.g. user@example.com',
            isRequired: true,
            errorText: errorText,
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: p.textSecondary,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !busy,
            onSubmitted: (_) => onSubmitted(),
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.spacing05),

          // Shortcut if user already has a token
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onTokenShortcutTap,
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'Already have a reset token? Enter it here \u2192',
                  style: context.appText.labelMedium.copyWith(
                    color: p.link,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
