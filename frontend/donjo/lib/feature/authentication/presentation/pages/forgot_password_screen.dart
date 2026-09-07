library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/carbon_grid_background.dart';
import 'package:donjo/feature/authentication/presentation/widgets/donjo_brand_mark.dart';
import 'package:donjo/feature/authentication/presentation/widgets/fade_slide_in.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute(
      builder: (context) => const ForgotPasswordScreen(),
    );
  }

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String? _emailError;
  String? _tokenError;
  String? _passwordError;
  bool _showResetForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _requestReset() {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }
    setState(() => _emailError = null);

    context.read<AuthBloc>().add(AuthPasswordResetRequested(email: email));
  }

  void _confirmReset() {
    final token = _tokenController.text.trim();
    final password = _newPasswordController.text;

    setState(() {
      _tokenError = token.isEmpty ? 'Enter the reset token' : null;
      _passwordError = password.length < 8
          ? 'Password must be at least 8 characters'
          : null;
    });

    if (_tokenError != null || _passwordError != null) return;

    context.read<AuthBloc>().add(
      AuthPasswordResetConfirmRequested(token: token, newPassword: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.passwordResetSent) {
          setState(() => _showResetForm = true);
        } else if (state.status == AuthStatus.passwordResetSuccess) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!context.mounted) return;
            Navigator.of(context).pop();
          });
        }
      },
      builder: (context, state) {
        final error = state.error;

        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              IconButton(
                tooltip: 'Toggle Theme',
                icon: Icon(
                  p.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: p.textSecondary,
                  size: 20,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              ),
              const SizedBox(width: AppSpacing.spacing02),
            ],
          ),
          body: CarbonGridBackground(
            child: DonjoPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: FadeSlideIn.staggered([
                  Row(
                    children: [
                      const DonjoBrandMark(size: 32),
                      const SizedBox(width: AppSpacing.spacing03),
                      Text(
                        'Donjo',
                        style: context.appText.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing07),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: DonjoEyebrow('Account Recovery'),
                  ),
                  const SizedBox(height: AppSpacing.spacing03),
                  Text(
                    'Reset your\npassword.',
                    style: context.appText.headlineLarge.copyWith(
                      height: 1.15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing03),
                  Text(
                    'Enter your registered email address to receive password reset instructions.',
                    style: context.appText.bodySmall.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing07),

                  if (error != null) ...[
                    DonjoErrorBanner(
                      message: error.message,
                      title: 'Reset Error',
                      onClose: () => context.read<AuthBloc>().add(
                        const AuthErrorCleared(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing05),
                  ],

                  if (state.statusMessage != null) ...[
                    DonjoSuccessBanner(
                      message: state.statusMessage!,
                      title: 'Instructions Sent',
                    ),
                    const SizedBox(height: AppSpacing.spacing05),
                  ],

                  if (!_showResetForm) ...[
                    AuthTextField(
                      controller: _emailController,
                      label: 'Registered email',
                      hint: 'user@example.com',
                      isRequired: true,
                      errorText: _emailError,
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: p.textSecondary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !state.busy,
                      onSubmitted: (_) => _requestReset(),
                    ),
                    const SizedBox(height: AppSpacing.spacing07),
                    DonjoPrimaryButton(
                      label: 'Send reset link',
                      loading: state.busy,
                      onPressed: state.busy ? null : _requestReset,
                    ),
                    const SizedBox(height: AppSpacing.spacing04),
                    DonjoGhostButton(
                      label: 'I already have a reset token',
                      onPressed: () => setState(() => _showResetForm = true),
                    ),
                  ] else ...[
                    AuthTextField(
                      controller: _tokenController,
                      label: 'Reset Token',
                      hint: 'Paste token from email',
                      isRequired: true,
                      mono: true,
                      errorText: _tokenError,
                      prefixIcon: Icon(
                        Icons.key_rounded,
                        size: 18,
                        color: p.textSecondary,
                      ),
                      textInputAction: TextInputAction.next,
                      enabled: !state.busy,
                    ),
                    const SizedBox(height: AppSpacing.fieldGap + 4),
                    AuthTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      hint: 'Minimum 8 characters',
                      isRequired: true,
                      obscure: true,
                      errorText: _passwordError,
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: p.textSecondary,
                      ),
                      textInputAction: TextInputAction.done,
                      enabled: !state.busy,
                      onSubmitted: (_) => _confirmReset(),
                    ),
                    const SizedBox(height: AppSpacing.spacing07),
                    DonjoPrimaryButton(
                      label: 'Update password',
                      loading: state.busy,
                      onPressed: state.busy ? null : _confirmReset,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.spacing07),
                  Center(
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing03,
                          vertical: AppSpacing.spacing02,
                        ),
                        child: Text(
                          'Back to sign in',
                          style: context.appText.labelMedium.copyWith(
                            color: p.link,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing08),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
