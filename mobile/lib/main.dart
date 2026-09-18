import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Resolve the saved light/dark choice before the first frame so the
  // app never flashes the wrong palette on launch.
  await ThemeController.instance.load();

  runApp(const CareerReadyApp());
}

class CareerReadyApp extends StatelessWidget {
  const CareerReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds MaterialApp as soon as the Dark mode switch is flipped,
    // so both the app-wide ThemeData and every AppColors lookup change
    // together.
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final controller = ThemeController.instance;
        return MaterialApp(
          title: 'Career Ready',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.themeMode,
          home: const SplashScreen(),
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            // Keep the status-bar clock/icons legible against whichever
            // background the theme is currently painting.
            value: controller.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: AppBackground(
              type: AppBackgroundType.main,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
