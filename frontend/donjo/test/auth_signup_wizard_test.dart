import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_theme.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/data/model/auth_models.dart';
import 'package:donjo/feature/authentication/data/repositories/auth_repository.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/pages/signup_screen.dart';

class MockAuthRepository implements AuthRepository {
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
  }) async =>
      AuthResult(
        user: await getMe(),
        tokens: const TokenResponse(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresIn: 3600,
          tokenType: 'Bearer',
        ),
      );

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

Widget createTestableWidget() {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(authRepository: MockAuthRepository()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const SignUpScreen(),
    ),
  );
}

void main() {
  testWidgets('SignUpScreen navigates step by step like Instagram wizard', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget());
    await tester.pumpAndSettle();

    // Step 1: Full name
    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Try to advance without entering name
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);

    // Fill valid name and advance
    await tester.enterText(find.byType(TextField).first, 'Alice Wonder');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 2: Username
    expect(find.text('Create a username'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'alicew');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 3: Email
    expect(find.text("What's your email?"), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'alice@example.com');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 4: Phone
    expect(find.text("What's your mobile number?"), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '+254712345678');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 5: Birthday
    expect(find.text("What's your date of birth?"), findsOneWidget);

    // Test back button to navigate backwards to Step 4
    await tester.tap(find.byTooltip('Previous step'));
    await tester.pumpAndSettle();
    expect(find.text("What's your mobile number?"), findsOneWidget);
  });
}
