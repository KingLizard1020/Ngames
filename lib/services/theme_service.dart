import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'app_theme_mode';

// Enum for Theme options
enum AppThemeMode { light, dark, system }

// Provider for SharedPreferences - this will be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This will throw if not overridden, which is what we want to ensure it's provided.
  throw UnimplementedError(
    'SharedPreferencesProvider must be overridden in ProviderScope',
  );
});

// StateNotifier for ThemeMode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  final SharedPreferences _prefs;

  Future<void> _loadThemeMode() async {
    final themeString = _prefs.getString(_themeModeKey);
    state = _stringToThemeMode(themeString);
  }

  Future<void> setThemeMode(AppThemeMode appThemeMode) async {
    state = _appThemeModeToMaterialThemeMode(appThemeMode);
    await _prefs.setString(_themeModeKey, _themeModeToString(appThemeMode));
  }

  AppThemeMode get currentAppThemeMode =>
      _materialThemeModeToAppThemeMode(state);

  ThemeMode _appThemeModeToMaterialThemeMode(AppThemeMode appThemeMode) {
    switch (appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  AppThemeMode _materialThemeModeToAppThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return AppThemeMode.light;
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.system:
        return AppThemeMode.system;
    }
  }

  String _themeModeToString(AppThemeMode appThemeMode) {
    return appThemeMode.toString().split('.').last;
  }

  ThemeMode _stringToThemeMode(String? themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      // Fallthrough to default if null or unknown, which is ThemeMode.system
      default:
        return ThemeMode.system;
    }
  }
}

// Provider for ThemeModeNotifier
final themeModeNotifierProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
      final prefs = ref.watch(
        sharedPreferencesProvider,
      ); // Now directly gets the SharedPreferences instance
      return ThemeModeNotifier(prefs);
    });
