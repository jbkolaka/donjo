library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/recovery_steps/recovery_step_container.dart';

class RecoveryPasswordStep extends StatelessWidget {
  const RecoveryPasswordStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.busy,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool busy;
  final VoidCallback onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return RecoveryStepContainer(
      key: const ValueKey('reset_step_newpassword'),
      eyebrow: 'New Password',
      title: 'Create new password',
      subtitle:
          'Choose a strong password with at least 8 characters to secure your Donjo account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: controller,
            focusNode: focusNode,
            label: 'New password',
            hint: 'Minimum 8 characters',
            isRequired: true,
            obscure: true,
            errorText: errorText,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: p.textSecondary,
            ),
            textInputAction: TextInputAction.done,
            enabled: !busy,
            onSubmitted: (_) => onSubmitted(),
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.spacing04),

          // Live Password Strength Meter
          PasswordStrengthMeter(password: controller.text),
        ],
      ),
    );
  }
}
