import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';
import 'app_theme.dart';

/// Owns the light/dark preference for the whole app.
///
/// The choice is persisted with SharedPreferences so it survives a
/// restart, and it drives both the [ThemeMode] MaterialApp uses (which
/// selects AppTheme.light vs AppTheme.dark) and [activePalette] (which
/// is what every AppColors reference resolves against).
class ThemeController extends ChangeNotifier {
  ThemeController._private();

  static final ThemeController instance = ThemeController._private();

  static const String _prefKey = 'appearance_dark_mode';

  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// Reads the saved preference. Called once from main() before runApp so
  /// the very first frame is already painted with the right palette.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      // A storage hiccup must never block startup, so fall back to light.
      _isDark = false;
    }
    activePalette = _isDark ? darkPalette : lightPalette;
  }

  /// Flips the theme, repaints every listener and saves the choice.
  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    activePalette = _isDark ? darkPalette : lightPalette;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {
      // The switch still works for this session even if saving fails.
    }
  }
}
