import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';
import 'app_theme.dart';

/// Owns the light/dark preference for the whole app.
///
/// The choice is persisted with SharedPreferences, scoped per signed-in
/// account (falling back to a shared "guest" slot for the signed-out
/// screens), so switching accounts on the same device doesn't carry one
/// person's Dark mode choice over to another. It drives both the
/// [ThemeMode] MaterialApp uses (which selects AppTheme.light vs
/// AppTheme.dark) and [activePalette] (which is what every AppColors
/// reference resolves against).
class ThemeController extends ChangeNotifier {
  ThemeController._private();

  static final ThemeController instance = ThemeController._private();

  static const String _guestPrefKey = 'appearance_dark_mode_guest';

  bool _isDark = false;

  /// Whoever the current preference was loaded for. Null means the
  /// guest/signed-out slot. Kept so [setDarkMode] knows where to save.
  String? _uid;

  bool get isDark => _isDark;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  String _prefKeyFor(String? uid) =>
      uid == null ? _guestPrefKey : 'appearance_dark_mode_$uid';

  /// Reads the saved guest-slot preference. Called once from main(),
  /// before Firebase's persisted session (if any) has been checked, so
  /// the very first frame is already painted with a reasonable palette.
  /// Splash then calls [loadForUser] once it knows who's signed in.
  Future<void> load() => loadForUser(null);

  /// Loads the preference for a specific account (or the guest slot,
  /// for [uid] == null, used on sign-out and on the signed-out screens).
  /// A different or new account that has never toggled Dark mode itself
  /// gets the default (light) rather than inheriting whatever the
  /// previous account on this device had chosen.
  Future<void> loadForUser(String? uid) async {
    _uid = uid;
    bool isDark = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      isDark = prefs.getBool(_prefKeyFor(uid)) ?? false;
    } catch (_) {
      // A storage hiccup must never block startup, so fall back to light.
      isDark = false;
    }
    _isDark = isDark;
    activePalette = _isDark ? darkPalette : lightPalette;
    notifyListeners();
  }

  /// Flips the theme, repaints every listener and saves the choice
  /// under whichever account is currently active.
  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    activePalette = _isDark ? darkPalette : lightPalette;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyFor(_uid), value);
    } catch (_) {
      // The switch still works for this session even if saving fails.
    }
  }
}
