import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_spacing.dart';

/// Brand lockup: mark plus wordmark.
class AppLogo extends StatelessWidget {
  final double size;

  /// Renders the wordmark next to the mark. Set false for tight spaces.
  final bool showWordmark;

  const AppLogo({
    super.key,
    this.size = AppSizes.logoLarge,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', width: size, height: size),
        if (showWordmark) ...[
          const SizedBox(width: AppSpacing.md),
          Text('KeepSafe', style: Theme.of(context).textTheme.headlineLarge),
        ],
      ],
    );
  }
}

class PasswordVisibilityToggle extends StatelessWidget {
  final bool isObscured;
  final VoidCallback onToggle;

  const PasswordVisibilityToggle({
    super.key,
    required this.isObscured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isObscured ? 'Show password' : 'Hide password',
      icon: Icon(
        isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}

/// The primary call to action: full-bleed, brand-filled, one per screen.
///
/// Height is pinned by the theme and does not change when [isLoading] flips, so
/// the layout cannot jump mid-request. Colour, radius and label style all come
/// from `elevatedButtonTheme` — the old version hard-coded
/// `colorScheme.inversePrimary`, which in Material 3 is a pale tint of the
/// brand, so the app's main button looked permanently disabled.
class AppElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const AppElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.control,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// The secondary action, for the one screen that offers two equal paths
/// (onboarding: sign in *or* register). Same footprint as
/// [AppElevatedButton] so the two stack into one column.
class AppOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.control,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
