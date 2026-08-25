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
    final asset = switch (type) {
      AppBackgroundType.auth => 'assets/images/bg-auth.svg',
      AppBackgroundType.main when width < 700 => 'assets/images/bg-small.svg',
      AppBackgroundType.main => 'assets/images/bg-main.svg',
    };

    return _AppBackgroundScope(
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(asset, fit: BoxFit.cover),
          child,
        ],
      ),
    );
  }
}
