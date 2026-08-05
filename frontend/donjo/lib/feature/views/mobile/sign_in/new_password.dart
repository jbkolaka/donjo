import 'package:donjo/feature/auth_widget/auth_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  static Route route() =>
      MaterialPageRoute(builder: (context) => const NewPasswordScreen());

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (password.isEmpty || confirmPassword.isEmpty) {
        _errorMessage = 'Please fill out both fields';
      } else if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
      } else if (password != confirmPassword) {
        _errorMessage = 'Passwords do not match';
      } else {
        _errorMessage = null;
        // Trigger your authentication or update logic here
        print('Password updated successfully');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 48),
            IconButton(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: 12),
            Text('New password', style: textTheme.headlineMedium),
            SizedBox(height: 4),
            Text(
              'Set your new secure password to safeguard your account',
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 12),
            // New Password Field
            AuthField(
              controller: _passwordController,
              hintText: 'New Password',
              obscureText: true,
            ),
            SizedBox(height: 12),
            // Confirm New Password Field
            AuthField(
              controller: _confirmPasswordController,
              hintText: 'Confirm New Password',
              obscureText: true,
            ),
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
            ElevatedButton(
              onPressed: _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Submit',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
