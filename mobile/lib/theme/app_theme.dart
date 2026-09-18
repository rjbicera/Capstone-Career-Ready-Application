import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The palette every screen reads through [AppColors].
///
/// ThemeController swaps this when the user toggles Dark mode. It starts
/// on the light palette so widget tests and any pre-load frame look the
/// same as they always have.
AppPalette activePalette = lightPalette;

/// Central design tokens for Career Ready.
/// Keep every screen pulling colors/text styles from here so the
/// app stays visually consistent as more screens get built.
///
/// These are getters rather than constants because they resolve against
/// [activePalette], which changes at runtime. Call sites keep reading
/// `AppColors.textPrimary` exactly as before, but a reference like that
/// can no longer sit inside a `` expression.
class AppColors {
  AppColors._();

  // Pastel indigo, lavender and blush are adapted from the resume-analyzer
  // reference artwork. Keep functional state colors distinct and accessible.
  static Color get primary => activePalette.primary;
  static Color get primaryLight => activePalette.primaryLight;
  static Color get accent => activePalette.accent;

  static Color get blue => activePalette.blue;
  static Color get blueLight => activePalette.blueLight;
  static Color get blueSoft => activePalette.blueSoft;

  static Color get background => activePalette.background;
  static Color get card => activePalette.card;
  static Color get onPrimary => activePalette.onPrimary;

  static Color get textPrimary => activePalette.textPrimary;
  static Color get textSecondary => activePalette.textSecondary;
  static Color get textMuted => activePalette.textMuted;

  static Color get border => activePalette.border;
  static Color get danger => activePalette.danger;

  /// Fill used behind incorrect/destructive states (e.g. a wrong quiz answer).
  static Color get dangerSoft => activePalette.dangerSoft;

  static List<Color> get headlineGradient => activePalette.headlineGradient;
}

class AppRadius {
  AppRadius._();
  static const double card = 18;
  static const double field = 14;
  static const double button = 14;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headline => TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get title => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(lightPalette);

  static ThemeData get dark => _build(darkPalette);

  /// Builds one ThemeData from an explicit palette. Taking the palette as
  /// a parameter (instead of reading [activePalette]) is what lets
  /// MaterialApp hold both the light and dark themes at the same time.
  static ThemeData _build(AppPalette p) {
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Mona Sans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: p.brightness,
        primary: p.primary,
        secondary: p.blue,
        surface: p.background,
        onSurface: p.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: p.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: p.textMuted, fontSize: 13),
      ),
      // `colorScheme.surface` above is intentionally transparent so the
      // AppBackground gradient shows through the Scaffold body. But
      // several Material components (dropdown menus, popup menus,
      // dialogs) also paint their own background from colorScheme.surface
      // by default, so that same transparency was leaking into them and
      // making their popups render see-through (e.g. the year-level
      // dropdown on the sign-up screen, and the logout confirmation
      // dialog on profile). Pin these back to an opaque card explicitly.
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStateProperty.all(p.card)),
      ),
      popupMenuTheme: PopupMenuThemeData(color: p.card),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
      ),
      canvasColor: p.card,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? const Color(0xFF2C2B35) : null,
        contentTextStyle: p.isDark ? TextStyle(color: p.textPrimary) : null,
      ),
    );
  }
}
