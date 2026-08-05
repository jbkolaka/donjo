import 'package:donjo/feature/auth_widget/auth_field.dart';
import 'package:donjo/feature/views/web/sign_in/web_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class WebSignUpScreen extends StatefulWidget {
  const WebSignUpScreen({super.key});
  @override
  State<WebSignUpScreen> createState() => _WebSignUpScreenState();
}

class _WebSignUpScreenState extends State<WebSignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/finger.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/finger.jpg',
                              width: 61,
                              height: 61,
                            ),
                            SizedBox(width: 16),
                            Text(
                              'KeepSafe',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        Text(
                          'Sign up so we can keep you safe',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 24),
                        AuthField(
                          controller: _emailController,
                          obscureText: false,
                          hintText: 'Email',
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: AuthField(
                                controller: _firstNameController,
                                obscureText: false,
                                hintText: 'First Name',
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: AuthField(
                                controller: _lastNameController,
                                obscureText: false,
                                hintText: 'Last Name',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        AuthField(
                          controller: _passwordController,
                          obscureText: true,
                          hintText: 'Password',
                        ),
                        SizedBox(height: 16),
                        AuthField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          hintText: 'Confirm Password',
                        ),
                        SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              WebSignInScreen.route(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Next',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 28),
                        RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      WebSignInScreen.route(),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
