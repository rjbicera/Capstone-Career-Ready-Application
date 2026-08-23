import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'resume_analysis_screen.dart';

class SavedResume {
  const SavedResume({
    required this.fileName,
    required this.uploadedOn,
    required this.score,
    required this.isActive,
  });

  final String fileName;
  final String uploadedOn;
  final int score;
  final bool isActive;
}

class SavedResumesScreen extends StatefulWidget {
  const SavedResumesScreen({super.key});

  @override
  State<SavedResumesScreen> createState() => _SavedResumesScreenState();
}

class _SavedResumesScreenState extends State<SavedResumesScreen> {
  // Reflects the resume actually on file for this account.
  final List<SavedResume> _resumes = [
    const SavedResume(
      fileName: 'Jenard_Reyes_Resume.pdf',
      uploadedOn: 'Uploaded Aug 3, 2026',
      score: 84,
      isActive: true,
    ),
  ];

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Seed AppState with the default active resume so Home's carousel
    // reflects it on first launch, before any upload happens.
    if (AppState.instance.resumeScore == null) {
      final active = _resumes.firstWhere((r) => r.isActive);
      AppState.instance.setResume(
        score: active.score,
        fileName: active.fileName,
      );
    }
  }

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
    setState(() => _isUploading = true);

    // TODO: replace with actual upload to your backend + AI scoring call.
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _isUploading = false;
      // Newly uploaded resume becomes the active one; previous active
      // resume is demoted (kept in history, matches typical "latest
      // resume used for matching" UX).
      for (var i = 0; i < _resumes.length; i++) {
        _resumes[i] = SavedResume(
          fileName: _resumes[i].fileName,
          uploadedOn: _resumes[i].uploadedOn,
          score: _resumes[i].score,
          isActive: false,
        );
      }
      _resumes.insert(
        0,
        SavedResume(
          fileName: picked.name,
          uploadedOn: 'Uploaded just now',
          score: 0, // unscored until backend analysis returns.
          isActive: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Saved resumes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: _resumes.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: _resumes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final resume = _resumes[index];
                  return _ResumeTile(resume: resume);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _isUploading ? null : _handleUpload,
        icon: _isUploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.upload_file_rounded, size: 18),
        label: Text(_isUploading ? 'Uploading...' : 'Upload'),
      ),
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({required this.resume});
  final SavedResume resume;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResumeAnalysisScreen(score: resume.score),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            resume.fileName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (resume.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resume.uploadedOn,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                resume.score > 0 ? '${resume.score}' : '—',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No resumes uploaded yet.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
