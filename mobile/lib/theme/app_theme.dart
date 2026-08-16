import 'package:flutter/material.dart';

/// Central design tokens for Career Ready.
/// Keep every screen pulling colors/text styles from here so the
/// app stays visually consistent as more screens get built.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F6E56); // teal
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color accent = Color(0xFF1D9E75); // lighter teal accent

  static const Color blue = Color(0xFF185FA5);
  static const Color blueLight = Color(0xFFE6F1FB);
  static const Color blueSoft = Color(0xFFB5D4F4);

  static const Color background = Color(0xFFF6F7F5);
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF20211F);
  static const Color textSecondary = Color(0xFF63665F);
  static const Color textMuted = Color(0xFF9A9C94);

  static const Color border = Color(0xFFE7E8E2);
  static const Color danger = Color(0xFFE24B4A);
}

class AppRadius {
  AppRadius._();
  static const double card = 18;
  static const double field = 14;
  static const double button = 14;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headline = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.blue,
        surface: AppColors.background,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}
