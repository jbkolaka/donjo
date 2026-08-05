import 'package:donjo/feature/views/mobile/sign_in/forgot_password.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:donjo/feature/auth_widget/auth_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  static Route route() =>
      MaterialPageRoute(builder: (context) => const SignInScreen());

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Please fill out all fields';
      } else if (!email.contains('@')) {
        _errorMessage = 'Please enter a valid email address';
      } else {
        _errorMessage = null;
        print('Authenticating: $email');
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
            Text('Welcome back', style: textTheme.headlineMedium),
            SizedBox(height: 4),
            Text(
              'Sign in to access your secure safe dashboard',
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: 12),
            AuthField(
              controller: _emailController,
              hintText: 'Email',
              obscureText: false,
            ),
            SizedBox(height: 12),
            AuthField(
              controller: _passwordController,
              hintText: 'Password',
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
            RichText(
              text: TextSpan(
                text: "Did you forget your password? ",
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                children: [
                  TextSpan(
                    text: 'Forgot Password',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Directly navigate to the registration screen
                        Navigator.push(context, ForgotPasswordScreen.route());
                      },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                'Sign In',
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
