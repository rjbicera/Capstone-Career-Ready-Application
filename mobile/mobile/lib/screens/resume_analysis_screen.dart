import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _Suggestion {
  const _Suggestion({
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeBg,
    required this.text,
  });

  final String badgeLabel;
  final Color badgeColor;
  final Color badgeBg;
  final String text;
}

class ResumeAnalysisScreen extends StatelessWidget {
  const ResumeAnalysisScreen({super.key, this.score = 84});

  final int score; // out of 100

  static const _suggestions = [
    _Suggestion(
      badgeLabel: 'Formatting',
      badgeColor: AppColors.blue,
      badgeBg: AppColors.blueLight,
      text: 'Use consistent bullet spacing in the experience section.',
    ),
    _Suggestion(
      badgeLabel: 'Keywords',
      badgeColor: AppColors.primary,
      badgeBg: AppColors.primaryLight,
      text: 'Add "cloud infrastructure" to match target roles.',
    ),
    _Suggestion(
      badgeLabel: 'Clarity',
      badgeColor: AppColors.blue,
      badgeBg: AppColors.blueLight,
      text: 'Shorten your summary to 2-3 lines for faster scanning.',
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
            const Text('Resume analysis', style: AppTextStyles.headline),
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  const Text(
                    'Overall score',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      text: '$score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                      children: const [
                        TextSpan(
                          text: '/100',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const Text('Suggestions', style: AppTextStyles.title),
            const SizedBox(height: 10),

            ..._suggestions.map(
              (s) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: s.badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.badgeLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: s.badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.text,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () {
                // TODO: open file picker + upload to backend for re-analysis.
              },
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload new resume'),
            ),
          ],
        ),
      ),
    );
  }
}
