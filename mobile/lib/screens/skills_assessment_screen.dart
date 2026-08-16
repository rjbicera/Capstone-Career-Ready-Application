import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'skills_quiz_screen.dart';

class _Skill {
  _Skill({required this.label, required this.progress, required this.color});
  final String label;
  double progress; // 0.0 - 1.0
  final Color color;
}

class SkillsAssessmentScreen extends StatefulWidget {
  const SkillsAssessmentScreen({super.key});

  @override
  State<SkillsAssessmentScreen> createState() => _SkillsAssessmentScreenState();
}

class _SkillsAssessmentScreenState extends State<SkillsAssessmentScreen> {
  final List<_Skill> _skills = [
    _Skill(
      label: 'Networking fundamentals',
      progress: 0.90,
      color: AppColors.primary,
    ),
    _Skill(label: 'Cloud fundamentals', progress: 0.64, color: AppColors.blue),
    _Skill(
      label: 'Security basics',
      progress: 0.48,
      color: AppColors.textMuted,
    ),
  ];

  Future<void> _pickCategory() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose a category', style: AppTextStyles.title),
              const SizedBox(height: 12),
              ..._skills.map(
                (skill) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.quiz_outlined, color: skill.color),
                  title: Text(skill.label),
                  subtitle: Text('Current: ${(skill.progress * 100).round()}%'),
                  onTap: () => Navigator.of(sheetContext).pop(skill.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || !mounted) return;

    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => SkillsQuizScreen(category: chosen)),
    );

    if (result == null || !mounted) return;

    setState(() {
      final skill = _skills.firstWhere((s) => s.label == chosen);
      skill.progress = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$chosen updated to ${(result * 100).round()}%.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Skills assessment',
                    style: AppTextStyles.headline,
                  ),
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
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: skill.progress),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation(skill.color),
                              ),
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
                onPressed: _pickCategory,
                child: const Text('Start new assessment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
