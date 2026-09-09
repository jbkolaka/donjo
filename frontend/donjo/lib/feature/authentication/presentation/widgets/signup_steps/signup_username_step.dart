library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_step_container.dart';

class SignUpUsernameStep extends StatelessWidget {
  const SignUpUsernameStep({
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

    return SignUpStepContainer(
      key: const ValueKey('step_username'),
      eyebrow: 'Step 2 of 6 • Username',
      title: 'Create a username',
      subtitle:
          'Pick a unique handle for your profile and event passes. You can change this later.',
      child: AuthTextField(
        controller: controller,
        focusNode: focusNode,
        label: 'Username',
        hint: 'e.g. janedoe',
        isRequired: true,
        errorText: errorText,
        prefixIcon: Icon(
          Icons.alternate_email_rounded,
          size: 20,
          color: p.textSecondary,
        ),
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username],
        enabled: !busy,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
      ),
    );
  }
}
