import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  AppThemeMode _themeMode = AppThemeMode.system;
  ThemeMode _currentThemeMode = ThemeMode.system;

  AppThemeMode get themeMode => _themeMode;
  ThemeMode get currentThemeMode => _currentThemeMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => AppThemeMode.system,
        );
        _updateThemeMode();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    _updateThemeMode();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  void _updateThemeMode() {
    switch (_themeMode) {
      case AppThemeMode.light:
        _currentThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        _currentThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        _currentThemeMode = ThemeMode.system;
        break;
    }
  }
}
