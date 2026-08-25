import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/app_background.dart';

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

class ResumeAnalysisScreen extends StatefulWidget {
  const ResumeAnalysisScreen({super.key, this.score = 84});

  final int score; // out of 100

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  String? _uploadedFileName;
  bool _isUploading = false;
  late int _displayScore;

  @override
  void initState() {
    super.initState();
    // Prefer whatever is already in shared state (e.g. set by a
    // previous upload or by Saved Resumes) over the constructor default,
    // so this screen doesn't show stale data after navigating back to it.
    _displayScore = AppState.instance.resumeScore ?? widget.score;
  }

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

  Future<void> _handleUpload() async {
    List<PlatformFile> result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Couldn\'t open file picker: $e')));
      return;
    }

    if (result.isEmpty) return;

    final picked = result.single;
    setState(() {
      _uploadedFileName = picked.name;
      _isUploading = true;
    });

    // TODO: replace with actual upload to your backend
    // (multer endpoint per SDD) + AI analysis call. Score below is a
    // placeholder stand-in until that endpoint returns a real one.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    const placeholderScore = 78; // TODO: replace with real AI score.
    setState(() {
      _isUploading = false;
      _displayScore = placeholderScore;
    });
    AppState.instance.setResume(score: placeholderScore, fileName: picked.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$_uploadedFileName" uploaded — analyzing.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const _GradientHeading('Smart feedback for your dream job'),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Drop your resume for an ATS score and improvement tips.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ),
                const SizedBox(height: 24),

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
                          text: '$_displayScore',
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

                if (_uploadedFileName != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_rounded,
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
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ],

                const Text('AI improvement tips', style: AppTextStyles.title),
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.blueSoft, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        color: AppColors.blue,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload your latest resume',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PDF, DOC, or DOCX',
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
                                ? 'Upload new resume'
                                : 'Upload a different resume',
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

class _GradientHeading extends StatelessWidget {
  const _GradientHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFAB8C95), Color(0xFF171717), Color(0xFF6F78D8)],
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
  }
}
