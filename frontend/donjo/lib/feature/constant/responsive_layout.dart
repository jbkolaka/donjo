import 'package:donjo/feature/views/mobile/onboarding/first_screen.dart';
import 'package:donjo/feature/views/web/sign_in/web_sign_in.dart';
import 'package:donjo/feature/views/web/sign_up./web_sign_up.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return FirstScreen();
        } else {
          return WebSignUpScreen();
        }
      },
    );
  }
}
