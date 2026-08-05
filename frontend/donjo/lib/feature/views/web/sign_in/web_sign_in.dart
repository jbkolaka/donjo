import 'package:donjo/feature/auth_widget/auth_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class WebSignInScreen extends StatefulWidget {
  const WebSignInScreen({super.key});
  static Route route() =>
      MaterialPageRoute(builder: (_) => const WebSignInScreen());
  @override
  State<WebSignInScreen> createState() => _WebSignInScreenState();
}

class _WebSignInScreenState extends State<WebSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
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
                    constraints: const BoxConstraints(maxWidth: 400),
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
                            const SizedBox(width: 16),
                            Text(
                              'Donjo',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Sign in to your account',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        AuthField(
                          controller: _emailController,
                          obscureText: false,
                          hintText: 'Email',
                        ),
                        const SizedBox(height: 16),
                        AuthField(
                          controller: _passwordController,
                          obscureText: true,
                          hintText: 'Password',
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Sign In',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 28),
                        RichText(
                          text: TextSpan(
                            text: "Did you forget your password? ",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Forgot Password',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Navigate to your registration screen here
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
