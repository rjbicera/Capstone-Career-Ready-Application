import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'resume_analysis_screen.dart';
import 'mock_interview_screen.dart';
import 'skills_assessment_screen.dart';

class _ProgressCard {
  const _ProgressCard({
    required this.icon,
    required this.bg,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName = 'Jenard'});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _carouselController = PageController(viewportFraction: 0.8);
  int _carouselIndex = 0;

  List<_ProgressCard> _buildCards(BuildContext context, AppState state) => [
        _ProgressCard(
          icon: Icons.description_rounded,
          bg: AppColors.primaryLight,
          accent: AppColors.primary,
          title: 'Resume analysis',
          subtitle: state.resumeScore == null
              ? 'Not analyzed yet'
              : 'Scored ${state.resumeScore}/100',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResumeAnalysisScreen(score: state.resumeScore ?? 0),
            ),
          ),
        ),
        _ProgressCard(
          icon: Icons.mic_rounded,
          bg: AppColors.blueLight,
          accent: AppColors.blue,
          title: 'Mock interview',
          subtitle: state.interviewsCompleted == 0
              ? 'Not started'
              : '${state.interviewsCompleted} session${state.interviewsCompleted == 1 ? '' : 's'} completed',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MockInterviewScreen()),
          ),
        ),
        _ProgressCard(
          icon: Icons.bar_chart_rounded,
          bg: AppColors.primaryLight,
          accent: AppColors.primary,
          title: 'Skills assessment',
          subtitle: '${(state.skillsAverage * 100).round()}% complete',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SkillsAssessmentScreen()),
          ),
        ),
      ];

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds automatically whenever any screen calls a setter on
    // AppState.instance (resume upload, interview finished, skill
    // updated) — no manual refresh or navigation callback needed.
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final cards = _buildCards(context, state);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: AppTextStyles.caption),
                        Text(widget.userName, style: AppTextStyles.title),
                      ],
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.blueLight,
                      child: Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Readiness ring card — the ONE headline stat, kept simple
                // on purpose so the dashboard doesn't overwhelm. Now a
                // real composite of resume + skills + interview activity
                // instead of a hardcoded number.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: state.overallReadiness),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall readiness',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              text: '${(state.overallReadiness * 100).round()}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              children: const [
                                TextSpan(
                                  text: '%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Continue prep', style: AppTextStyles.title),
                    Text(
                      'swipe →',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Swipeable progress carousel — subtitles now reflect
                // real state instead of hardcoded strings.
                SizedBox(
                  height: 128,
                  child: PageView.builder(
                    controller: _carouselController,
                    itemCount: cards.length,
                    onPageChanged: (i) => setState(() => _carouselIndex = i),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: card.onTap,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: card.bg,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: card.accent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    card.icon,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  card.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cards.length, (index) {
                    final isActive = index == _carouselIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
