library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_palette.dart';
import 'package:donjo/core/theme/spacing/app_spacing.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/data/model/auth_models.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_text_field.dart';
import 'package:donjo/feature/authentication/presentation/widgets/auth_widget.dart';
import 'package:donjo/feature/authentication/presentation/widgets/carbon_grid_background.dart';
import 'package:donjo/feature/authentication/presentation/widgets/donjo_brand_mark.dart';
import 'package:donjo/feature/authentication/presentation/widgets/fade_slide_in.dart';

class SignUpScreen extends StatefulWidget {
  static Route<dynamic> route() {
    return MaterialPageRoute(builder: (context) => const SignUpScreen());
  }

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();

    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 13); // Backend requires 13+

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final p = context.palette;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: p.buttonPrimary,
              onPrimary: const Color(0xFF161616),
              surface: p.surface,
              onSurface: p.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dobController.text = formatted;
        _dobError = null;
      });
    }
  }

  bool _validate() {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final dob = _dobController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? 'Enter your full name' : null;

      if (username.isEmpty) {
        _usernameError = 'Enter a username';
      } else if (username.length < 3) {
        _usernameError = 'Username must be at least 3 characters';
      } else {
        _usernameError = null;
      }

      if (email.isEmpty) {
        _emailError = 'Enter your email address';
      } else if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }

      _phoneError = phone.isEmpty ? 'Enter your phone number' : null;
      _dobError = dob.isEmpty ? 'Select your date of birth' : null;

      if (password.isEmpty) {
        _passwordError = 'Enter a password';
      } else if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
      } else {
        _passwordError = null;
      }
    });

    return _fullNameError == null &&
        _usernameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _dobError == null &&
        _passwordError == null;
  }

  void _submit() {
    if (!_validate()) return;

    final request = CreateUserRequest(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      password: _passwordController.text,
    );

    context.read<AuthBloc>().add(AuthSignUpRequested(request: request));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isAuthenticated) {
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

                  // 2. Eyebrow & Headline
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: DonjoEyebrow('Registration'),
                  ),
                  const SizedBox(height: AppSpacing.spacing03),
                  Text(
                    'Create your\naccount.',
                    style: context.appText.headlineLarge.copyWith(
                      height: 1.15,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing03),
                  Text(
                    'Join the platform to access events, ticketing and secure donations.',
                    style: context.appText.bodySmall.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing07),

                  // 3. Error Banner (if any)
                  if (showBanner) ...[
                    DonjoErrorBanner(
                      message: error.message,
                      title: 'Registration Error',
                      onClose: () => context.read<AuthBloc>().add(
                        const AuthErrorCleared(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing05),
                  ],

                  // 4. Form Fields
                  AuthTextField(
                    controller: _fullNameController,
                    label: 'Full name',
                    hint: 'Jane Doe',
                    isRequired: true,
                    errorText: _fullNameError ?? state.fieldErrors['full_name'],
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: p.textSecondary,
                    ),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !state.busy,
                    onSubmitted: (_) => _usernameFocus.requestFocus(),
                    onChanged: (_) {
                      if (_fullNameError != null) {
                        setState(() => _fullNameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.fieldGap + 4),

                  AuthTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    label: 'Username',
                    hint: 'janedoe',
                    isRequired: true,
                    errorText: _usernameError ?? state.fieldErrors['username'],
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      size: 18,
                      color: p.textSecondary,
                    ),
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    enabled: !state.busy,
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                    onChanged: (_) {
                      if (_usernameError != null) {
                        setState(() => _usernameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.fieldGap + 4),

                  AuthTextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    label: 'Email address',
                    hint: 'jane@example.com',
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
                    onSubmitted: (_) => _phoneFocus.requestFocus(),
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.fieldGap + 4),

                  AuthTextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    label: 'Phone number',
                    hint: '+254712345678',
                    isRequired: true,
                    errorText: _phoneError ?? state.fieldErrors['phone_number'],
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: p.textSecondary,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    enabled: !state.busy,
                    onSubmitted: (_) => _pickDateOfBirth(),
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.fieldGap + 4),

                  // Date of Birth Field with tap trigger
                  GestureDetector(
                    onTap: state.busy ? null : _pickDateOfBirth,
                    child: AbsorbPointer(
                      child: AuthTextField(
                        controller: _dobController,
                        label: 'Date of birth',
                        hint: 'YYYY-MM-DD',
                        isRequired: true,
                        helper: 'Must be at least 13 years old',
                        errorText:
                            _dobError ?? state.fieldErrors['date_of_birth'],
                        prefixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: p.textSecondary,
                        ),
                        suffixIcon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: p.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.fieldGap + 4),

                  AuthTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    label: 'Password',
                    hint: 'Minimum 8 characters',
                    isRequired: true,
                    errorText: _passwordError ?? state.fieldErrors['password'],
                    obscure: true,
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: p.textSecondary,
                    ),
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !state.busy,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) {
                      setState(() {
                        if (_passwordError != null) _passwordError = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.spacing03),

                  // 5. Password Strength Meter
                  PasswordStrengthMeter(password: _passwordController.text),
                  const SizedBox(height: AppSpacing.spacing06),

                  // 6. Terms of service checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: p.buttonPrimary,
                          checkColor: const Color(0xFF161616),
                          side: BorderSide(color: p.border, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: state.busy
                              ? null
                              : (v) =>
                                    setState(() => _agreedToTerms = v ?? false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing03),
                      Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: context.appText.bodySmall.copyWith(
                            color: p.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing07),

                  // 7. Submit CTA
                  DonjoPrimaryButton(
                    label: 'Create account',
                    loading: state.busy,
                    onPressed: state.busy || !_agreedToTerms ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.spacing06),

                  // 8. Sign In Link Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: context.appText.bodySmall.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            'Sign in',
                            style: context.appText.labelMedium.copyWith(
                              color: p.link,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
