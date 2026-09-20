import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_background.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  const ResumeAnalysisScreen({super.key, this.score = 0});

  final int score;

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  static const int _maxResumeBytes = 10 * 1024 * 1024;

  String? _uploadedFileName;
  bool _isUploading = false;
  late int _displayScore;
  Map<String, dynamic>? _analysis;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
    _displayScore = AppState.instance.resumeScore ?? widget.score;
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _feedbackList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(
          (item) => item['issue'] != null && item['recommendation'] != null,
        )
        .toList();
  }

  Future<void> _handleUpload() async {
    PlatformFile? picked;

    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    } catch (e) {
      if (!mounted) return;

      _showError("Couldn't open file picker: $e");
      return;
    }

    if (picked == null) return;

    List<int> fileBytes;

    try {
      fileBytes = await picked.readAsBytes();
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Unable to read the selected PDF. Please choose the file again.',
      );
      return;
    }

    if (fileBytes.isEmpty) {
      _showError('The selected PDF is empty.');
      return;
    }

    if (fileBytes.length > _maxResumeBytes) {
      _showError('Resume PDF must be 10 MB or smaller.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('Your session has expired. Please sign in again.');
      return;
    }

    setState(() {
      _uploadedFileName = picked!.name;
      _isUploading = true;
      _errorMessage = null;
      _analysis = null;
    });

    try {
      final idToken = await user.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          'Your authentication session could not be verified.',
          code: 'MISSING_TOKEN',
        );
      }

      final response = await AuthApiService.analyzeResume(
        idToken: idToken,
        fileBytes: fileBytes,
        fileName: picked.name,
      );

      final resume = response['resume'];

      final analysis = resume is Map ? resume['analysis'] : null;

      if (analysis is! Map) {
        throw ApiException(
          'The server returned an incomplete resume analysis.',
          code: 'INVALID_ANALYSIS_RESPONSE',
        );
      }

      final normalizedAnalysis = Map<String, dynamic>.from(analysis);

      final score = (normalizedAnalysis['overallScore'] as num?)?.round() ?? 0;

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _analysis = normalizedAnalysis;
        _displayScore = score;
      });

      AppState.instance.setResume(score: score, fileName: picked.name);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume analyzed successfully.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _errorMessage = e.message;
      });

      _showError(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _errorMessage = e.message;
      });

      _showError(e.message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _errorMessage = 'Unable to analyze this resume right now.';
      });

      _showError('Unable to analyze this resume right now.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final contentScore = (_analysis?['contentScore'] as num?)?.round() ?? 0;
    final layoutScore = (_analysis?['layoutScore'] as num?)?.round() ?? 0;
    final atsScore = (_analysis?['atsScore'] as num?)?.round() ?? 0;
    final summary = _analysis?['summary']?.toString() ?? '';
    final strengths = _stringList(_analysis?['strengths']);
    final weaknesses = _stringList(_analysis?['weaknesses']);
    final feedback = _feedbackList(_analysis?['feedback']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        type: AppBackgroundType.main,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.of(context).canPop()) ...[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 12),
                ],
                const _GradientHeading('Smart feedback for your dream job'),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Upload a PDF to get content, layout, and ATS feedback.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ),
                const SizedBox(height: 24),
                _ScoreCard(
                  label: 'Overall score',
                  score: _displayScore,
                  color: AppColors.blue,
                  background: AppColors.blueLight,
                ),
                if (_analysis != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniScoreCard(
                          label: 'Content',
                          score: contentScore,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniScoreCard(
                          label: 'Layout',
                          score: layoutScore,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniScoreCard(label: 'ATS', score: atsScore),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                if (_uploadedFileName != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _uploadedFileName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_isUploading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          )
                        else if (_analysis != null)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ],
                if (_isUploading)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Uploading and analyzing your resume. This may take a moment.',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null && !_isUploading)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                if (_analysis != null) ...[
                  if (summary.isNotEmpty) ...[
                    Text('AI summary', style: AppTextStyles.title),
                    const SizedBox(height: 10),
                    _InfoCard(text: summary),
                    const SizedBox(height: 18),
                  ],
                  if (strengths.isNotEmpty) ...[
                    Text('What is working well', style: AppTextStyles.title),
                    const SizedBox(height: 10),
                    ...strengths.map(
                      (item) => _BulletCard(
                        icon: Icons.check_circle_outline_rounded,
                        text: item,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (weaknesses.isNotEmpty) ...[
                    Text('What needs improvement', style: AppTextStyles.title),
                    const SizedBox(height: 10),
                    ...weaknesses.map(
                      (item) => _BulletCard(
                        icon: Icons.warning_amber_rounded,
                        text: item,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (feedback.isNotEmpty) ...[
                    Text('Actionable feedback', style: AppTextStyles.title),
                    const SizedBox(height: 10),
                    ...feedback.map((item) => _FeedbackCard(item: item)),
                    const SizedBox(height: 18),
                  ],
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.blueSoft, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.blue,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyze your latest resume',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF only • maximum 10 MB',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _handleUpload,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(
                            _uploadedFileName == null
                                ? 'Upload resume'
                                : 'Analyze a different resume',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
    required this.background,
  });

  final String label;
  final int score;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: '$score',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              children: [
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
    );
  }
}

class _MiniScoreCard extends StatelessWidget {
  const _MiniScoreCard({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12.5,
          height: 1.5,
        ),
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final category = item['category']?.toString() ?? 'Feedback';
    final severity = item['severity']?.toString() ?? 'medium';
    final issue = item['issue']?.toString() ?? '';
    final why = item['whyItMatters']?.toString() ?? '';
    final recommendation = item['recommendation']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                severity.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            issue,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (why.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              why,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Recommendation: $recommendation',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradientHeading extends StatelessWidget {
  const _GradientHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: AppColors.headlineGradient,
          ).createShader(bounds),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        );
      },
    );
  }
}
