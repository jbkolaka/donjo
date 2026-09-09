library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_step_container.dart';

class SignUpNameStep extends StatelessWidget {
  const SignUpNameStep({
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
      key: const ValueKey('step_fullname'),
      eyebrow: 'Step 1 of 6 • Your Name',
      title: "What's your name?",
      subtitle:
          'Add your full name so your friends, organizers, and attendees can find you.',
      child: AuthTextField(
        controller: controller,
        focusNode: focusNode,
        label: 'Full name',
        hint: 'e.g. Jane Doe',
        isRequired: true,
        errorText: errorText,
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          size: 20,
          color: p.textSecondary,
        ),
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        enabled: !busy,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
      ),
    );
  }
}
