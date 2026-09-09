library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/grid/app_grid.dart';
import 'package:donjo/core/motion/app_motion.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/carbon_grid_background.dart';
import 'package:donjo/feature/authentication/presentation/widgets/donjo_brand_mark.dart';
import 'package:donjo/feature/authentication/presentation/widgets/recovery_steps/recovery_steps.dart';

/// Clean Instagram-style account recovery & password reset flow.
///
/// Modular steps:
/// - Step 1: Find Account (Enter registered email)
/// - Step 2: Verification Code (Enter reset token received via email)
/// - Step 3: New Password (Set new password with strength meter)
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
  static const int _totalSteps = 3;
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _tokenFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _emailError;
  String? _tokenError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emailFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();

    _emailFocus.dispose();
    _tokenFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _focusCurrentStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_currentStep) {
        case 0:
          _emailFocus.requestFocus();
          break;
        case 1:
          _tokenFocus.requestFocus();
          break;
        case 2:
          _passwordFocus.requestFocus();
          break;
      }
    });
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: AppMotion.durationModerate02,
      curve: AppMotion.easeExpressiveStandard,
    );
    _focusCurrentStep();
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0: // Email
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          setState(() => _emailError = 'Enter your email address');
          return false;
        }
        if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          setState(() => _emailError = 'Enter a valid email address');
          return false;
        }
        setState(() => _emailError = null);
        return true;

      case 1: // Token
        final token = _tokenController.text.trim();
        if (token.isEmpty) {
          setState(
            () => _tokenError = 'Enter the reset token sent to your email',
          );
          return false;
        }
        setState(() => _tokenError = null);
        return true;

      case 2: // New Password
        final password = _newPasswordController.text;
        if (password.isEmpty) {
          setState(() => _passwordError = 'Enter a new password');
          return false;
        }
        if (password.length < 8) {
          setState(
            () => _passwordError = 'Password must be at least 8 characters',
          );
          return false;
        }
        setState(() => _passwordError = null);
        return true;

      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep(_currentStep)) return;

    if (_currentStep == 0) {
      _requestReset();
    } else if (_currentStep == 1) {
      _goToStep(2);
    } else {
      _confirmReset();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).maybePop();
    }
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

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _prevStep();
        }
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.passwordResetSent) {
            // Move smoothly to Token step
            if (_currentStep == 0) {
              _goToStep(1);
            }
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
                tooltip: _currentStep > 0 ? 'Previous' : 'Back',
                onPressed: _prevStep,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DonjoBrandMark(size: 24),
                  const SizedBox(width: AppSpacing.spacing02),
                  Text(
                    'Donjo',
                    style: context.appText.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
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
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppGrid.maxFormWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error Notification Banner
                        if (error != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenGutter,
                              vertical: AppSpacing.spacing03,
                            ),
                            child: DonjoErrorBanner(
                              message: error.message,
                              title: 'Reset Error',
                              onClose: () => context.read<AuthBloc>().add(
                                const AuthErrorCleared(),
                              ),
                            ),
                          ),
                        ],

                        // Success Status Banner
                        if (state.statusMessage != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenGutter,
                              vertical: AppSpacing.spacing03,
                            ),
                            child: DonjoSuccessBanner(
                              message: state.statusMessage!,
                              title: 'Status',
                            ),
                          ),
                        ],

                        // Page View
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              RecoveryEmailStep(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                errorText: _emailError,
                                busy: state.busy,
                                onSubmitted: _nextStep,
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() => _emailError = null);
                                  }
                                },
                                onTokenShortcutTap: () => _goToStep(1),
                              ),
                              RecoveryTokenStep(
                                controller: _tokenController,
                                focusNode: _tokenFocus,
                                errorText: _tokenError,
                                busy: state.busy,
                                onSubmitted: _nextStep,
                                onChanged: (_) {
                                  if (_tokenError != null) {
                                    setState(() => _tokenError = null);
                                  }
                                },
                              ),
                              RecoveryPasswordStep(
                                controller: _newPasswordController,
                                focusNode: _passwordFocus,
                                errorText: _passwordError,
                                busy: state.busy,
                                onSubmitted: _confirmReset,
                                onChanged: (_) {
                                  if (_passwordError != null) {
                                    setState(() => _passwordError = null);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        // Sticky Action Footer
                        RecoveryBottomBar(
                          currentStep: _currentStep,
                          totalSteps: _totalSteps,
                          busy: state.busy,
                          onNext: _nextStep,
                          onSignInTap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
