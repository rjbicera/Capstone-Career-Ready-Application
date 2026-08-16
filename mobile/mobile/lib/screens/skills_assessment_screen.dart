import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _Skill {
  const _Skill({
    required this.label,
    required this.progress,
    required this.color,
  });

  final String label;
  final double progress; // 0.0 - 1.0
  final Color color;
}

class SkillsAssessmentScreen extends StatelessWidget {
  const SkillsAssessmentScreen({super.key});

  static const _skills = [
    _Skill(
      label: 'Networking fundamentals',
      progress: 0.90,
      color: AppColors.primary,
    ),
    _Skill(
      label: 'Cloud fundamentals',
      progress: 0.64,
      color: AppColors.blue,
    ),
    _Skill(
      label: 'Security basics',
      progress: 0.48,
      color: AppColors.textMuted,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Text('Skills assessment', style: AppTextStyles.headline),
              ],
            ),
            const SizedBox(height: 20),

            ..._skills.map(
              (skill) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          skill.label,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${(skill.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: skill.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: skill.progress,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(skill.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              onPressed: () {
                // TODO: start a new assessment flow.
              },
              child: const Text('Start new assessment'),
            ),
          ],
        ),
      ),
    );
  }
}
