import 'package:flutter/material.dart';

/// A complete set of design tokens for one brightness (light or dark).
///
/// Screens never depend on this class directly: they read the active
/// palette through AppColors in app_theme.dart, which delegates to
/// whichever AppPalette is currently in effect. That lets every
/// existing `AppColors.primary` reference keep working while the whole
/// app repaints when the user flips the Dark mode switch.
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.blue,
    required this.blueLight,
    required this.blueSoft,
    required this.background,
    required this.card,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.danger,
    required this.dangerSoft,
  });

  final Brightness brightness;

  final Color primary;
  final Color primaryLight;
  final Color accent;

  final Color blue;
  final Color blueLight;
  final Color blueSoft;

  /// Scaffold background. Transparent so the AppBackground gradient shows.
  final Color background;

  /// Opaque surface for cards, sheets, dialogs and menus.
  final Color card;

  /// Foreground drawn on top of primary-filled controls.
  final Color onPrimary;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color border;
  final Color danger;

  /// Tinted fill used behind destructive or incorrect states.
  final Color dangerSoft;

  bool get isDark => brightness == Brightness.dark;
}

/// The original pastel-indigo light palette, adapted from the
/// resume-analyzer reference artwork.
const AppPalette lightPalette = AppPalette(
  brightness: Brightness.light,
  primary: Color(0xFF6678EF),
  primaryLight: Color(0xFFE9ECFF),
  accent: Color(0xFF8E98FF),
  blue: Color(0xFF6F78D8),
  blueLight: Color(0xFFF0F4FF),
  blueSoft: Color(0xFFC9D2FF),
  background: Colors.transparent,
  card: Colors.white,
  onPrimary: Colors.white,
  textPrimary: Color(0xFF1E1B22),
  textSecondary: Color(0xFF475467),
  textMuted: Color(0xFF667085),
  border: Color(0xFFE4E7EC),
  danger: Color(0xFFD95D79),
  dangerSoft: Color(0xFFFCEBEB),
);

/// A companion dark palette. Brand indigo is kept so buttons and links
/// stay recognisable, while surfaces, text and borders flip for dark.
const AppPalette darkPalette = AppPalette(
  brightness: Brightness.dark,
  primary: Color(0xFF7C8AF2),
  primaryLight: Color(0xFF2A2F4A),
  accent: Color(0xFFA8B0FF),
  blue: Color(0xFF8B96E8),
  blueLight: Color(0xFF232838),
  blueSoft: Color(0xFF3A4370),
  background: Colors.transparent,
  card: Color(0xFF1C1B22),
  onPrimary: Colors.white,
  textPrimary: Color(0xFFF3F4F8),
  textSecondary: Color(0xFFC7CBD6),
  textMuted: Color(0xFF98A0B3),
  border: Color(0xFF33313D),
  danger: Color(0xFFE8799B),
  dangerSoft: Color(0xFF3A2530),
);
