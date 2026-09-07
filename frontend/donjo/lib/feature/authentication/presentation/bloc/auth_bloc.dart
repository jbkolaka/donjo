library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/network/api_exception.dart';
import 'package:donjo/feature/authentication/data/repositories/auth_repository.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_event.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<Auth2FAVerifyRequested>(_on2FAVerifyRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthPasswordResetConfirmRequested>(_onPasswordResetConfirmRequested);
    on<AuthErrorCleared>(_onErrorCleared);
  }

  final AuthRepository authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final hasToken = await authRepository.hasSavedToken();
    if (!hasToken) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    try {
      final user = await authRepository.getMe();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      await authRepository.clearSession();
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        fieldErrors: const {},
      ),
    );

    try {
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
        twoFactorCode: event.twoFactorCode,
      );

      if (result.twoFactorRequired) {
        emit(
          state.copyWith(
            status: AuthStatus.twoFactorRequired,
            emailFor2FA: event.email,
          ),
        );
        return;
      }

      emit(state.copyWith(status: AuthStatus.authenticated, user: result.user));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.message, fields: e.fields),
          fieldErrors: e.fields,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        fieldErrors: const {},
      ),
    );

    try {
      await authRepository.register(event.request);

      // Automatically sign in upon successful registration
      final result = await authRepository.login(
        email: event.request.email,
        password: event.request.password,
      );

      emit(state.copyWith(status: AuthStatus.authenticated, user: result.user));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.message, fields: e.fields),
          fieldErrors: e.fields,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating));
    await authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _on2FAVerifyRequested(
    Auth2FAVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));

    try {
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
        twoFactorCode: event.twoFactorCode,
      );

      emit(state.copyWith(status: AuthStatus.authenticated, user: result.user));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));

    try {
      await authRepository.requestPasswordReset(event.email);
      emit(
        state.copyWith(
          status: AuthStatus.passwordResetSent,
          statusMessage:
              'If an account exists for that email, a password reset link has been dispatched.',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.toString()),
        ),
      );
    }
  }

  Future<void> _onPasswordResetConfirmRequested(
    AuthPasswordResetConfirmRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));

    try {
      await authRepository.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      emit(
        state.copyWith(
          status: AuthStatus.passwordResetSuccess,
          statusMessage:
              'Your password has been successfully reset. You can now sign in.',
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.message, fields: e.fields),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          error: AuthError(message: e.toString()),
        ),
      );
    }
  }

  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearError: true, fieldErrors: const {}));
  }
}
