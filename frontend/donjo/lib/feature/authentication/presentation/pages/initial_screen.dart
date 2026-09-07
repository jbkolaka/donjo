library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/pages/signin_screen.dart';
import 'package:donjo/feature/authentication/presentation/pages/signup_screen.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/carbon_grid_background.dart';
import 'package:donjo/feature/authentication/presentation/widgets/donjo_brand_mark.dart';
import 'package:donjo/feature/authentication/presentation/widgets/fade_slide_in.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (context) => const InitialScreen());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              p.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: p.textSecondary,
              size: 20,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          const SizedBox(width: AppSpacing.spacing03),
        ],
      ),
      body: CarbonGridBackground(
        child: DonjoPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: FadeSlideIn.staggered([
              const SizedBox(height: AppSpacing.spacing06),

              // 1. Carbon Brand Emblem
              const Center(child: DonjoBrandMark(size: 64)),
              const SizedBox(height: AppSpacing.spacing06),

              // 2. Eyebrow Tag
              const Center(child: DonjoEyebrow('Enterprise Event Platform')),
              const SizedBox(height: AppSpacing.spacing04),

              // 3. Display Headline (Carbon Light 300 scale)
              Text(
                'Experience events\nwith precision.',
                textAlign: TextAlign.center,
                style: context.appText.displaySmall.copyWith(
                  height: 1.1,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.0,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing04),

              // 4. Lead Body Text
              Text(
                'Manage your tickets, organize community gatherings, and power seamless donations with enterprise security.',
                textAlign: TextAlign.center,
                style: context.appText.bodySmall.copyWith(
                  color: p.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing08),

              // 5. Value Proposition Badges
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing04),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: p.borderSubtle,
                    width: AppSizes.hairline,
                  ),
                ),
                child: Column(
                  children: [
                    _FeatureRow(
                      icon: Icons.shield_outlined,
                      title: 'Bank-Grade Security',
                      description:
                          'TOTP Two-Factor Authentication & JWT Sessions',
                    ),
                    Divider(
                      color: p.borderSubtle,
                      height: AppSpacing.spacing05,
                    ),
                    _FeatureRow(
                      icon: Icons.bolt_outlined,
                      title: 'Instant Checkout',
                      description: 'Direct M-Pesa & Mobile Wallet Integration',
                    ),
                    Divider(
                      color: p.borderSubtle,
                      height: AppSpacing.spacing05,
                    ),
                    _FeatureRow(
                      icon: Icons.grid_view_rounded,
                      title: 'Carbon Design System',
                      description:
                          'Standard 2x Grid, Productive Motion & Contrast',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.spacing09),

              // 6. Action CTAs
              DonjoPrimaryButton(
                label: 'Sign in to account',
                onPressed: () =>
                    Navigator.of(context).push(SignInScreen.route()),
              ),
              const SizedBox(height: AppSpacing.spacing04),

              DonjoGhostButton(
                label: 'Create new account',
                onPressed: () =>
                    Navigator.of(context).push(SignUpScreen.route()),
              ),
              const SizedBox(height: AppSpacing.spacing08),
            ]),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: p.buttonPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: p.isDark ? p.buttonPrimary : const Color(0xFF161616),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.appText.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              Text(
                description,
                style: context.appText.bodySm.copyWith(
                  color: p.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
