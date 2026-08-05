import 'package:donjo/feature/views/mobile/sign_in/new_password.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:donjo/feature/auth_widget/auth_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  // Static route method restored to match your design pattern
  static route() =>
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen());

  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 12),
          Text('Forgot password', style: textTheme.headlineMedium?.copyWith()),
          SizedBox(height: 4),
          Text(
            'Enter your email to receive a password reset link',
            style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 12),
          AuthField(
            controller: _emailController,
            hintText: 'Email',
            obscureText: false,
          ),
          SizedBox(height: 80),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, NewPasswordScreen.route());
            },
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
