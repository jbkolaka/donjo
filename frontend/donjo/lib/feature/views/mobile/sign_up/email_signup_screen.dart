import 'package:donjo/feature/auth_widget/auth_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class EmailSignupScreen extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const EmailSignupScreen({
    super.key,
    required this.controller,
    required this.onNext,
  });

  @override
  _EmailSignupScreenState createState() => _EmailSignupScreenState();
}

class _EmailSignupScreenState extends State<EmailSignupScreen> {
  @override
  Widget build(BuildContext context) {
    // Accessing the Material 3 typography scheme
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 12),
          Text('Enter your email', style: textTheme.headlineMedium?.copyWith()),
          SizedBox(height: 4),
          Text(
            'Enter your email so we can keep your safe',
            style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 12),
          AuthField(
            controller: widget.controller,
            hintText: 'Email',
            obscureText: false,
          ),
          SizedBox(height: 80),
          //RichText(
          //  text: TextSpan(
          //    text: "Already have an account ? ",
          //    style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
          //    children: [
          //      TextSpan(
          //        text: ' Sign in',
          //        style: textTheme.bodyMedium?.copyWith(
          //          fontWeight: FontWeight.bold,
          //          color: Theme.of(context).colorScheme.primary,
          //          decoration: TextDecoration.underline,
          //        ),
          //        recognizer: TapGestureRecognizer()
          //          ..onTap = () {
          //            // Add login navigation logic here
          //          },
          //      ),
          //    ],
          //  ),
          //),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              'Next',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 360),
        ],
      ),
    );
  }
}
