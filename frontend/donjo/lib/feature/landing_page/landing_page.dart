import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Text(
            'Donjo',
            style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
