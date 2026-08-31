import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'dark') {
      emit(ThemeMode.dark);
    } else if (saved == 'light') {
      emit(ThemeMode.light);
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    emit(newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
