import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppBackgroundType { main, auth }

class _AppBackgroundScope extends InheritedWidget {
  const _AppBackgroundScope({required super.child});

  static bool isApplied(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppBackgroundScope>() != null;

  @override
  bool updateShouldNotify(_AppBackgroundScope oldWidget) => false;
}

/// Decorative gradient artwork used behind the main and authentication flows.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.type, required this.child});

  final AppBackgroundType type;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // MaterialApp applies this once for the whole navigator. Individual
    // screens may still use this widget safely without painting it twice.
    if (_AppBackgroundScope.isApplied(context)) return child;

    final width = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = switch (type) {
      AppBackgroundType.auth => 'assets/images/bg-auth.svg',
      AppBackgroundType.main when width < 700 => 'assets/images/bg-small.svg',
      AppBackgroundType.main => 'assets/images/bg-main.svg',
    };

    return _AppBackgroundScope(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Solid base so the transparent Scaffold always has a real
          // backdrop, in both themes.
          ColoredBox(color: isDark ? const Color(0xFF121118) : Colors.white),
          SvgPicture.asset(asset, fit: BoxFit.cover),
          // The artwork is a light pastel gradient. Lay a dark scrim over
          // it in dark mode so text and cards keep their contrast instead
          // of sitting on a bright wash.
          if (isDark) const ColoredBox(color: Color(0xE6121118)),
          child,
        ],
      ),
    );
  }
}
