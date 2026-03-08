import 'package:flutter/material.dart';
import 'package:pos/core/const/app_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeController(this._prefs) : _themeMode = _initialMode(_prefs);

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static ThemeMode _initialMode(SharedPreferences prefs) {
    final saved = prefs.getString(AppKey.themeMode);
    switch (saved) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    await _prefs.setString(AppKey.themeMode, mode.name);
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
