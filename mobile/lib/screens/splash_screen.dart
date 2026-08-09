import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_mark.dart';
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
        _goToOnboarding();
      }
    });
  }

  void _goToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const OnboardingScreen(),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.blue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(_fade),
                  child: const LogoMark.onColor(size: 84),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: _fade,
                child: const Text(
                  'career ready',
                  style: TextStyle(
                    color: Colors.white,
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
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
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
