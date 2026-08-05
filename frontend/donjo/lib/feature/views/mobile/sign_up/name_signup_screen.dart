import 'package:donjo/feature/auth_widget/auth_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class NameSignupScreen extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onNext;

  const NameSignupScreen({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.onNext,
  });

  @override
  _NameSignupScreenState createState() => _NameSignupScreenState();
}

class _NameSignupScreenState extends State<NameSignupScreen> {
  String get fullName =>
      '${widget.firstNameController.text.trim()} ${widget.lastNameController.text.trim()}';

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
          Text('Enter your name', style: textTheme.headlineMedium),
          SizedBox(height: 4),
          Text(
            'Enter your legal name so we can verify your identity',
            style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          SizedBox(height: 12),
          // First Name Input Field
          AuthField(
            controller: widget.firstNameController,
            hintText: 'First Name',
            obscureText: false,
          ),
          SizedBox(height: 12),
          AuthField(
            controller: widget.lastNameController,
            hintText: 'Last Name',
            obscureText: false,
          ),
          SizedBox(height: 56),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              widget.onNext();
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
          SizedBox(height: 300),
        ],
      ),
    );
  }
}
