library;

import 'package:donjo/feature/authentication/data/model/auth_models.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  twoFactorRequired,
  passwordResetSent,
  passwordResetSuccess,
  failure,
}

class AuthError {
  const AuthError({required this.message, this.fields = const {}});

  final String message;
  final Map<String, String> fields;
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.fieldErrors = const {},
    this.emailFor2FA,
    this.statusMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final AuthError? error;
  final Map<String, String?> fieldErrors;
  final String? emailFor2FA;
  final String? statusMessage;

  bool get busy => status == AuthStatus.authenticating;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get is2FARequired => status == AuthStatus.twoFactorRequired;
  bool get isSignedOut =>
      status == AuthStatus.unauthenticated || status == AuthStatus.failure;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    AuthError? error,
    bool clearError = false,
    Map<String, String?>? fieldErrors,
    String? emailFor2FA,
    String? statusMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : error ?? this.error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      emailFor2FA: emailFor2FA ?? this.emailFor2FA,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
