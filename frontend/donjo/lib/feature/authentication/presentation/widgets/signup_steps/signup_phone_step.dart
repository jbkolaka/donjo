library;

import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_step_container.dart';

class SignUpPhoneStep extends StatelessWidget {
  const SignUpPhoneStep({
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
      key: const ValueKey('step_phone'),
      eyebrow: 'Step 4 of 6 • Mobile Phone',
      title: "What's your mobile number?",
      subtitle:
          'Used for instant M-Pesa payments, SMS ticket links, and fast account recovery.',
      child: AuthTextField(
        controller: controller,
        focusNode: focusNode,
        label: 'Mobile phone number',
        hint: 'e.g. +254712345678',
        isRequired: true,
        errorText: errorText,
        prefixIcon: Icon(
          Icons.phone_outlined,
          size: 20,
          color: p.textSecondary,
        ),
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        enabled: !busy,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
      ),
    );
  }
}
