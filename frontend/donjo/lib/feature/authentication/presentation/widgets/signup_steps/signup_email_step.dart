library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_step_container.dart';

class SignUpEmailStep extends StatelessWidget {
  const SignUpEmailStep({
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
      key: const ValueKey('step_email'),
      eyebrow: 'Step 3 of 6 • Email',
      title: "What's your email?",
      subtitle:
          "We'll send your event tickets, receipts, and important account security notices here.",
      child: AuthTextField(
        controller: controller,
        focusNode: focusNode,
        label: 'Email address',
        hint: 'e.g. jane@example.com',
        isRequired: true,
        errorText: errorText,
        prefixIcon: Icon(
          Icons.mail_outline_rounded,
          size: 20,
          color: p.textSecondary,
        ),
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        enabled: !busy,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
      ),
    );
  }
}
