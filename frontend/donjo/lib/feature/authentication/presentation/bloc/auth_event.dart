library;

import 'package:donjo/feature/authentication/data/model/auth_models.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Check if there's an active session on app launch.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign in with email and password (and optional 2FA code).
final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
    this.twoFactorCode,
  });

  final String email;
  final String password;
  final String? twoFactorCode;
}

/// Sign up a new user.
final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({required this.request});

  final CreateUserRequest request;
}

/// Sign out the current user.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Submit 2FA verification during sign in.
final class Auth2FAVerifyRequested extends AuthEvent {
  const Auth2FAVerifyRequested({
    required this.email,
    required this.password,
    required this.twoFactorCode,
  });

  final String email;
  final String password;
  final String twoFactorCode;
}

/// Request a password reset link to email.
final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;
}

/// Reset password using token and new password.
final class AuthPasswordResetConfirmRequested extends AuthEvent {
  const AuthPasswordResetConfirmRequested({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;
}

/// Clears any transient error message in the auth state.
final class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
