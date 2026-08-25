import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_background.dart';

void main() {
  runApp(const CareerReadyApp());
}

class CareerReadyApp extends StatelessWidget {
  const CareerReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Ready',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (context, child) => AppBackground(
        type: AppBackgroundType.main,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
