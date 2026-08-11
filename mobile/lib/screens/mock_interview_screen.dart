import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'skills_assessment_screen.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  static const _questions = [
    'Tell me about a time you solved a difficult technical problem.',
    'Why do you want to work in networking or cloud infrastructure?',
    'Describe a project where you worked as part of a team.',
    'How do you stay updated with new technology?',
    'What is a weakness you\'re actively working on?',
    'Tell me about a time you had to learn something quickly.',
    'Where do you see yourself in the next few years?',
    'Do you have any questions for us?',
  ];

  int _currentQuestion = 0;
  bool _isRecording = false;

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentQuestion + 1) / _questions.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mock interview', style: AppTextStyles.headline),
            const SizedBox(height: 4),
            Text(
              'Question ${_currentQuestion + 1} of ${_questions.length}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.blue),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                alignment: Alignment.center,
                child: Text(
                  '"${_questions[_currentQuestion]}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: GestureDetector(
                onTap: () => setState(() => _isRecording = !_isRecording),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.danger : AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isRecording ? 'Recording... tap to stop' : 'Tap to record your answer',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SkillsAssessmentScreen(),
                        ),
                      );
                    },
                    child: const Text('View skills'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                    onPressed: _currentQuestion < _questions.length - 1
                        ? _nextQuestion
                        : null,
                    child: Text(
                      _currentQuestion < _questions.length - 1
                          ? 'Next question'
                          : 'Done',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
