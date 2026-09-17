import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/biometric_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_mark.dart';
import '../widgets/app_background.dart';
import 'main_navigation.dart';
import 'demographic_profile_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _progress;

  static const _duration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _duration);

    // Logo fades/scales in over the first 40% of the timeline.
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // Progress bar fills across the whole timeline.
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _routeOnLaunch();
      }
    });
  }

  /// Decides where to go once the splash animation finishes.
  ///
  /// Firebase already persists the session across app launches, so a
  /// returning user shouldn't be dumped back on onboarding. If they've
  /// enabled biometric login, the scan gates access to that restored
  /// session before any of their data is shown.
  Future<void> _routeOnLaunch() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _go(const OnboardingScreen());
      return;
    }

    final biometricEnabled = await BiometricService.isEnabled();
    if (biometricEnabled) {
      final ok = await BiometricService.authenticate(
        reason: 'Unlock Career Ready',
      );
      if (!ok) {
        // Failed or cancelled — sign out rather than silently letting
        // them past a lock they explicitly turned on.
        await AuthApiService.signOut();
        AppState.instance.clearProfile();
        _go(const OnboardingScreen());
        return;
      }
    }

    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        _go(const OnboardingScreen());
        return;
      }

      final profile = await AuthApiService.me(idToken: idToken);
      AppState.instance.loadProfile(profile);

      _go(
        profile['profileComplete'] == true
            ? const MainNavigation()
            : const DemographicProfileScreen(),
      );
    } catch (_) {
      // Backend unreachable or token rejected — fall back to the
      // normal signed-out flow rather than hanging on the splash.
      _go(const OnboardingScreen());
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: screen),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        type: AppBackgroundType.main,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(_fade),
                  child: const LogoMark(size: 84),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: _fade,
                child: const Text(
                  'career ready',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Spacer(flex: 3),

              // Progress indicator so the wait doesn't feel static.
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.value,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.65),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
