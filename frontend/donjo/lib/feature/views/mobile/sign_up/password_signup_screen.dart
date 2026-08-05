import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:donjo/feature/auth_widget/auth_field.dart';

class PasswordSignupScreen extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onNext;

  const PasswordSignupScreen({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onNext,
  });

  @override
  _PasswordSignupScreenState createState() => _PasswordSignupScreenState();
}

class _PasswordSignupScreenState extends State<PasswordSignupScreen> {
  // Local validation state management
  String? _errorMessage;

  void _validateAndSubmit() {
    final password = widget.passwordController.text;
    final confirmPassword = widget.confirmPasswordController.text;

    setState(() {
      if (password.isEmpty || confirmPassword.isEmpty) {
        _errorMessage = 'Please fill out both fields';
      } else if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
      } else if (password != confirmPassword) {
        _errorMessage = 'Passwords do not match';
      } else {
        _errorMessage = null; // Clear errors if validation passes
        widget.onNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          IconButton(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 12),
          Text('Create a password', style: textTheme.headlineMedium),
          SizedBox(height: 4),
          Text(
            'Ensure your account remains safe and protected',
            style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 12),
          // Password Input Field
          AuthField(
            controller: widget.passwordController,
            hintText: 'Password',
            obscureText: true, // Hides password characters
          ),
          SizedBox(height: 12),
          // Confirm Password Input Field
          AuthField(
            controller: widget.confirmPasswordController,
            hintText: 'Confirm Password',
            obscureText: true, // Hides confirm password characters
          ),
          // Dynamic Error Alert Message
          if (_errorMessage != null) ...[
            SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ],
          SizedBox(height: 40),
          //RichText(...),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: _validateAndSubmit, // Triggers matching check
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
          SizedBox(height: 300),
        ],
      ),
    );
  }
}
