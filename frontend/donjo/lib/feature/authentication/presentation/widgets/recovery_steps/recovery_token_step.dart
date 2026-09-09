library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/recovery_steps/recovery_step_container.dart';

class RecoveryTokenStep extends StatelessWidget {
  const RecoveryTokenStep({
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
      key: const ValueKey('reset_step_token'),
      eyebrow: 'Security Token',
      title: 'Enter reset token',
      subtitle:
          'Check your email inbox and enter the security reset token sent to you.',
      child: AuthTextField(
        controller: controller,
        focusNode: focusNode,
        label: 'Reset Token',
        hint: 'Paste token from email',
        isRequired: true,
        mono: true,
        errorText: errorText,
        prefixIcon: Icon(Icons.key_rounded, size: 20, color: p.textSecondary),
        textInputAction: TextInputAction.next,
        enabled: !busy,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
      ),
    );
  }
}
