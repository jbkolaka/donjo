import 'package:donjo/feature/views/mobile/sign_in/sign_in_screen.dart';
import 'package:donjo/feature/views/mobile/sign_up/phone_signup_screen.dart';
import 'package:flutter/material.dart';

class FirstScreen extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const FirstScreen());
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Welcome to KeepSafe'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, SignInScreen.route());
              },
              child: const Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, SignUpScreen.route());
              },
              child: const Text('Register'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
