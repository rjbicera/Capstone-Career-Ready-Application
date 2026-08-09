import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class _OnboardSlide {
  const _OnboardSlide({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardSlide(
      icon: Icons.check_circle_outline,
      iconBg: AppColors.blueLight,
      iconColor: AppColors.blue,
      title: 'Prep smarter, land faster',
      description:
          'AI-powered resume review, mock interviews, and skill checks — all in one place.',
    ),
    _OnboardSlide(
      icon: Icons.description_outlined,
      iconBg: AppColors.primaryLight,
      iconColor: AppColors.primary,
      title: 'Get your resume noticed',
      description:
          'Upload your resume and get instant, AI-driven feedback on formatting, keywords, and gaps recruiters actually look for.',
    ),
    _OnboardSlide(
      icon: Icons.mic_none_rounded,
      iconBg: AppColors.blueLight,
      iconColor: AppColors.blue,
      title: 'Practice before it counts',
      description:
          'Run mock interviews with real-time AI feedback, then track your skills across key areas as you improve.',
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button, hidden on the last slide.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Opacity(
                    opacity: isLastPage ? 0 : 1,
                    child: TextButton(
                      onPressed: isLastPage ? null : _goToLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: slide.iconBg,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 64,
                            color: slide.iconColor,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicators.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(isLastPage ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
