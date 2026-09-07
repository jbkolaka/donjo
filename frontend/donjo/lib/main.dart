import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:donjo/core/theme/app_theme.dart';
import 'package:donjo/core/theme/theme.dart';
import 'package:donjo/feature/authentication/data/repositories/auth_repository.dart';
import 'package:donjo/feature/authentication/presentation/bloc/auth_bloc.dart';
import 'package:donjo/feature/authentication/presentation/pages/initial_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DonjoApp());
}

class DonjoApp extends StatelessWidget {
  const DonjoApp({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(authRepository: authRepository ?? AuthRepositoryImpl())
                ..add(const AuthCheckRequested()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Donjo',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const InitialScreen(),
          );
        },
      ),
    );
  }
}
