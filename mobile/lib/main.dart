import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_background.dart';

Future<void> main() async {
  // Required before any Firebase call (Auth, Firestore, Storage, etc.).
  // firebase_options.dart was already generated via the FlutterFire CLI
  // (see docs/CHANGELOG-SDD.md [SDD v1.3]) but was never actually wired
  // up here, so every FirebaseAuth call in the app — signup's sign-in
  // step, and login/logout/reset below — was failing with
  // "No Firebase App '[DEFAULT]' has been created" at runtime.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
