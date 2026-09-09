import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_theme.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/data/model/auth_models.dart';
import 'package:donjo/feature/authentication/data/repositories/auth_repository.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/pages/forgot_password_screen.dart';

class MockResetAuthRepository implements AuthRepository {
  @override
  Future<bool> hasSavedToken() async => false;

  @override
  Future<UserModel> getMe() async => const UserModel(
    id: '1',
    email: 'test@example.com',
    fullName: 'Test User',
    username: 'testuser',
    dateOfBirth: '2000-01-01',
    phoneNumber: '+254700000000',
  );

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String? twoFactorCode,
  }) async => AuthResult(user: await getMe());

  @override
  Future<UserModel> register(CreateUserRequest request) async => getMe();

  @override
  Future<void> logout() async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<void> clearSession() async {}
}

Widget createResetTestWidget() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(authRepository: MockResetAuthRepository()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const ForgotPasswordScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'ForgotPasswordScreen navigates through account recovery steps without progress bars',
    (WidgetTester tester) async {
      await tester.pumpWidget(createResetTestWidget());
      await tester.pumpAndSettle();

      // Verify there is no LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Step 1: Email
      expect(find.text('Find your account'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);

      // Invalid email check
      await tester.enterText(find.byType(TextField).first, 'invalid');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);

      // Enter valid email and send reset
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      // Step 2: Security Token
      expect(find.text('Enter reset token'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Enter token and advance
      await tester.enterText(find.byType(TextField).first, 'SECRET-TOKEN-123');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: New Password
      expect(find.text('Create new password'), findsOneWidget);
      expect(find.text('Update password'), findsOneWidget);
    },
  );
}
