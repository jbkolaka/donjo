library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/grid/app_grid.dart';
import 'package:donjo/core/motion/app_motion.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/data/model/auth_models.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/carbon_grid_background.dart';
import 'package:donjo/feature/authentication/presentation/widgets/donjo_brand_mark.dart';
import 'package:donjo/feature/authentication/presentation/widgets/signup_steps/signup_steps.dart';

/// Instagram-style step-by-step multi-page registration wizard.
///
/// Each input field lives on its own dedicated screen with smooth expressive
/// slide animations, progress tracking, and IBM Carbon 2x Grid layout alignment.
class SignUpScreen extends StatefulWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (context) => const SignUpScreen());
  }

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const int _totalSteps = 6;
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String? _fullNameError;
  String? _usernameError;
  String? _emailError;
  String? _phoneError;
  String? _dobError;
  String? _passwordError;
  bool _agreedToTerms = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fullNameFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();

    _fullNameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _focusCurrentStep() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_currentStep) {
        case 0:
          _fullNameFocus.requestFocus();
          break;
        case 1:
          _usernameFocus.requestFocus();
          break;
        case 2:
          _emailFocus.requestFocus();
          break;
        case 3:
          _phoneFocus.requestFocus();
          break;
        case 4:
          FocusScope.of(context).unfocus();
          break;
        case 5:
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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Full name
        final name = _fullNameController.text.trim();
        if (name.isEmpty) {
          setState(() => _fullNameError = 'Enter your full name');
          return false;
        }
        if (name.length < 2) {
          setState(
            () => _fullNameError = 'Full name must be at least 2 characters',
          );
          return false;
        }
        setState(() => _fullNameError = null);
        return true;

      case 1: // Username
        final username = _usernameController.text.trim();
        if (username.isEmpty) {
          setState(() => _usernameError = 'Enter a username');
          return false;
        }
        if (username.length < 3) {
          setState(
            () => _usernameError = 'Username must be at least 3 characters',
          );
          return false;
        }
        if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
          setState(
            () => _usernameError =
                'Username can only contain letters, numbers, dots, and underscores',
          );
          return false;
        }
        setState(() => _usernameError = null);
        return true;

      case 2: // Email
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

      case 3: // Phone number
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          setState(() => _phoneError = 'Enter your phone number');
          return false;
        }
        final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
        if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(cleanPhone)) {
          setState(
            () =>
                _phoneError = 'Enter a valid phone number (e.g. +254712345678)',
          );
          return false;
        }
        setState(() => _phoneError = null);
        return true;

      case 4: // Date of birth
        final dob = _dobController.text.trim();
        if (dob.isEmpty) {
          setState(() => _dobError = 'Please select your date of birth');
          return false;
        }
        try {
          final parsed = DateTime.parse(dob);
          final now = DateTime.now();
          final age =
              now.year -
              parsed.year -
              ((now.month > parsed.month ||
                      (now.month == parsed.month && now.day >= parsed.day))
                  ? 0
                  : 1);
          if (age < 13) {
            setState(() => _dobError = 'You must be at least 13 years old');
            return false;
          }
        } catch (_) {
          setState(() => _dobError = 'Invalid date format (YYYY-MM-DD)');
          return false;
        }
        setState(() => _dobError = null);
        return true;

      case 5: // Password
        final password = _passwordController.text;
        if (password.isEmpty) {
          setState(() => _passwordError = 'Enter a password');
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
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1920);
    final lastDate = DateTime(now.year - 13, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT YOUR DATE OF BIRTH',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dobController.text = '$y-$m-$d';
        _dobError = null;
      });
    }
  }

  void _submit() {
    if (!_validateCurrentStep()) return;
    if (!_agreedToTerms) return;

    final request = CreateUserRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    context.read<AuthBloc>().add(AuthSignUpRequested(request: request));
  }

  void _handleServerError(AuthState state) {
    if (state.fieldErrors.containsKey('full_name') && _currentStep != 0) {
      _goToStep(0);
    } else if (state.fieldErrors.containsKey('username') && _currentStep != 1) {
      _goToStep(1);
    } else if (state.fieldErrors.containsKey('email') && _currentStep != 2) {
      _goToStep(2);
    } else if (state.fieldErrors.containsKey('phone_number') &&
        _currentStep != 3) {
      _goToStep(3);
    } else if (state.fieldErrors.containsKey('date_of_birth') &&
        _currentStep != 4) {
      _goToStep(4);
    } else if (state.fieldErrors.containsKey('password') && _currentStep != 5) {
      _goToStep(5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = (_currentStep + 1) / _totalSteps;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _prevStep();
        }
      },
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            Navigator.of(context).pop();
          } else if (state.status == AuthStatus.failure) {
            _handleServerError(state);
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
                tooltip: _currentStep > 0 ? 'Previous step' : 'Back',
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: AppMotion.durationModerate02,
                  curve: AppMotion.easeProductiveEntrance,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: p.borderSubtle.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        p.buttonPrimary,
                      ),
                      minHeight: 3,
                    );
                  },
                ),
              ),
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
                        // General Error Banner
                        if (showBanner) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenGutter,
                              vertical: AppSpacing.spacing03,
                            ),
                            child: DonjoErrorBanner(
                              message: error.message,
                              title: 'Registration Error',
                              onClose: () => context.read<AuthBloc>().add(
                                const AuthErrorCleared(),
                              ),
                            ),
                          ),
                        ],

                        // Step Page View
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              SignUpNameStep(
                                controller: _fullNameController,
                                focusNode: _fullNameFocus,
                                errorText:
                                    _fullNameError ??
                                    state.fieldErrors['full_name'],
                                busy: state.busy,
                                onSubmitted: _nextStep,
                                onChanged: (_) {
                                  if (_fullNameError != null) {
                                    setState(() => _fullNameError = null);
                                  }
                                },
                              ),
                              SignUpUsernameStep(
                                controller: _usernameController,
                                focusNode: _usernameFocus,
                                errorText:
                                    _usernameError ??
                                    state.fieldErrors['username'],
                                busy: state.busy,
                                onSubmitted: _nextStep,
                                onChanged: (_) {
                                  if (_usernameError != null) {
                                    setState(() => _usernameError = null);
                                  }
                                },
                              ),
                              SignUpEmailStep(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                errorText:
                                    _emailError ?? state.fieldErrors['email'],
                                busy: state.busy,
                                onSubmitted: _nextStep,
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() => _emailError = null);
                                  }
                                },
                              ),
                              SignUpPhoneStep(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                errorText:
                                    _phoneError ??
                                    state.fieldErrors['phone_number'],
                                busy: state.busy,
                                onSubmitted: _nextStep,
                                onChanged: (_) {
                                  if (_phoneError != null) {
                                    setState(() => _phoneError = null);
                                  }
                                },
                              ),
                              SignUpDobStep(
                                dobText: _dobController.text,
                                errorText:
                                    _dobError ??
                                    state.fieldErrors['date_of_birth'],
                                busy: state.busy,
                                onTapPicker: _pickDateOfBirth,
                              ),
                              SignUpPasswordStep(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                errorText:
                                    _passwordError ??
                                    state.fieldErrors['password'],
                                agreedToTerms: _agreedToTerms,
                                busy: state.busy,
                                onSubmitted: _submit,
                                onChanged: (_) {
                                  if (_passwordError != null) {
                                    setState(() => _passwordError = null);
                                  }
                                },
                                onToggleTerms: (v) =>
                                    setState(() => _agreedToTerms = v ?? false),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Navigation Footer
                        SignUpBottomBar(
                          currentStep: _currentStep,
                          totalSteps: _totalSteps,
                          busy: state.busy,
                          canProceed:
                              _currentStep != _totalSteps - 1 || _agreedToTerms,
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
