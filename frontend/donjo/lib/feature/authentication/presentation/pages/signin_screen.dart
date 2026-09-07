library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/pages/forgot_password_screen.dart';
import 'package:donjo/feature/authentication/presentation/pages/signup_screen.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/carbon_grid_background.dart';
import 'package:donjo/feature/authentication/presentation/widgets/donjo_brand_mark.dart';
import 'package:donjo/feature/authentication/presentation/widgets/fade_slide_in.dart';

class SignInScreen extends StatefulWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (context) => const SignInScreen());
  }

  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _twoFactorController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _twoFactorController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Enter your email address';
      } else if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }

      _passwordError = password.isEmpty ? 'Enter your password' : null;
    });

    return _emailError == null && _passwordError == null;
  }

  void _submit() {
    if (!_validate()) return;

    context.read<AuthBloc>().add(
      AuthSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _submit2FA(String email, String password) {
    final code = _twoFactorController.text.trim();
    if (code.isEmpty) return;

    context.read<AuthBloc>().add(
      Auth2FAVerifyRequested(
        email: email,
        password: password,
        twoFactorCode: code,
      ),
    );
  }

  void _show2FADialog(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      builder: (ctx) {
        final p = ctx.palette;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.spacing06,
            left: AppSpacing.spacing06,
            right: AppSpacing.spacing06,
            top: AppSpacing.spacing06,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.security_rounded, color: p.link, size: 24),
                  const SizedBox(width: AppSpacing.spacing03),
                  Text(
                    'Two-Factor Authentication',
                    style: ctx.appText.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing03),
              Text(
                'Enter the 6-digit authentication code from your authenticator app.',
                style: ctx.appText.bodySmall,
              ),
              const SizedBox(height: AppSpacing.spacing06),
              AuthTextField(
                controller: _twoFactorController,
                label: 'Verification Code',
                hint: '123456',
                mono: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                onSubmitted: (_) {
                  Navigator.pop(ctx);
                  _submit2FA(email, _passwordController.text);
                },
              ),
              const SizedBox(height: AppSpacing.spacing06),
              DonjoPrimaryButton(
                label: 'Verify & Sign In',
                onPressed: () {
                  Navigator.pop(ctx);
                  _submit2FA(email, _passwordController.text);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToRegister() {
    context.read<AuthBloc>().add(const AuthErrorCleared());
    Navigator.of(context).push(SignUpScreen.route());
  }

  void _goToForgotPassword() {
    context.read<AuthBloc>().add(const AuthErrorCleared());
    Navigator.of(context).push(ForgotPasswordScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.is2FARequired && state.emailFor2FA != null) {
          _show2FADialog(state.emailFor2FA!);
        } else if (state.isAuthenticated) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        final error = state.error;
        final showBanner = error != null && state.fieldErrors.isEmpty;

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
                  // 1. Header Lockup
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

                  // 2. Eyebrow & Title
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: DonjoEyebrow('Account Access'),
                  ),
                  const SizedBox(height: AppSpacing.spacing03),
                  Text(
                    'Sign in to your\naccount.',
                    style: context.appText.headlineLarge.copyWith(
                      height: 1.15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing03),
                  Text(
                    'Welcome back. Enter your credentials to continue.',
                    style: context.appText.bodySmall.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing07),

                  // 3. Error Banner (if any)
                  if (showBanner) ...[
                    DonjoErrorBanner(
                      message: error.message,
                      title: 'Authentication Failed',
                      onClose: () => context.read<AuthBloc>().add(
                        const AuthErrorCleared(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing05),
                  ],

                  // 4. Form Fields
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'user@example.com',
                    isRequired: true,
                    errorText: _emailError ?? state.fieldErrors['email'],
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      size: 18,
                      color: p.textSecondary,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    enabled: !state.busy,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.fieldGap + 4),

                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    isRequired: true,
                    focusNode: _passwordFocus,
                    errorText: _passwordError ?? state.fieldErrors['password'],
                    obscure: true,
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: p.textSecondary,
                    ),
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    enabled: !state.busy,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.spacing03),

                  // 5. Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      onTap: state.busy ? null : _goToForgotPassword,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing02,
                          vertical: AppSpacing.spacing02,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: context.appText.labelMedium.copyWith(
                            color: p.link,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing06),

                  // 6. Sign In CTA
                  DonjoPrimaryButton(
                    label: 'Sign in',
                    loading: state.busy,
                    onPressed: state.busy ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.spacing06),

                  // 7. Carbon Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: p.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing04,
                        ),
                        child: Text(
                          'OR',
                          style: context.appText.labelSmall.copyWith(
                            color: p.textPlaceholder,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: p.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing06),

                  // 8. Create Account Secondary Button
                  DonjoGhostButton(
                    label: 'Create an account',
                    onPressed: state.busy ? null : _goToRegister,
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
