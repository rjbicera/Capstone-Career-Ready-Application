import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../services/auth_api_service.dart';
import 'resume_analysis_screen.dart';

class SavedResume {
  const SavedResume({
    required this.resumeId,
    required this.fileName,
    required this.uploadedOn,
    required this.score,
    required this.analysis,
  });

  final String resumeId;
  final String fileName;
  final String uploadedOn;
  final int score;
  final Map<String, dynamic>? analysis;
}

class SavedResumesScreen extends StatefulWidget {
  const SavedResumesScreen({super.key});

  @override
  State<SavedResumesScreen> createState() => _SavedResumesScreenState();
}

class _SavedResumesScreenState extends State<SavedResumesScreen> {
  List<SavedResume> _resumes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken(true);
      if (idToken == null) return;

      final resumesData = await AuthApiService.getResumes(idToken: idToken);
      
      if (mounted) {
        setState(() {
          _resumes = resumesData.map((data) {
            final analysis = data['analysis'] as Map<String, dynamic>?;
            return SavedResume(
              resumeId: data['resumeId'] as String,
              fileName: data['originalFilename'] as String,
              uploadedOn: _formatDate(data['analysisAt'] as String? ?? data['uploadedAt'] as String?),
              score: (analysis?['overallScore'] as num?)?.round() ?? 0,
              analysis: analysis,
            );
          }).toList();
          _isLoading = false;
        });

        // Update AppState with latest resume
        if (_resumes.isNotEmpty && AppState.instance.resumeScore == null) {
          final latest = _resumes.first;
          AppState.instance.setResume(
            score: latest.score,
            fileName: latest.fileName,
            summary: latest.analysis?['summary'] as String?,
            strengths: (latest.analysis?['strengths'] as List?)?.cast<String>(),
            weaknesses: (latest.analysis?['weaknesses'] as List?)?.cast<String>(),
            skills: (latest.analysis?['skills'] as List?)?.cast<String>(),
            missingSkills: (latest.analysis?['missingSkills'] as List?)?.cast<String>(),
            feedback: (latest.analysis?['feedback'] as List?)?.cast<Map<String, dynamic>>(),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Failed to load resumes: $e');
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(isoString);
      return 'Uploaded ${date.day} ${_monthName(date.month)} ${date.year}';
    } catch (_) {
      return 'Unknown date';
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _handleUpload() async {
    // ... upload logic (unchanged, but should call analyzeResume and refresh)
    // For now, just refresh after upload would complete
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload not yet connected to backend')),
    );
  }

  Future<void> _deleteResume(String resumeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final idToken = await user.getIdToken(true);
      if (idToken == null) return;

      await AuthApiService.deleteResume(idToken: idToken, resumeId: resumeId);
      
      if (mounted) {
        setState(() => _resumes.removeWhere((r) => r.resumeId == resumeId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Saved resumes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _resumes.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _resumes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final resume = _resumes[index];
                      return _ResumeTile(
                        resume: resume,
                        onDelete: () => _deleteResume(resume.resumeId),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ResumeAnalysisScreen(
                              score: resume.score,
                              // Pass full analysis data
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _handleUpload,
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: const Text('Upload'),
      ),
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({
    required this.resume,
    required this.onDelete,
    required this.onTap,
  });

  final SavedResume resume;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
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
                child: Icon(
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                onPressed: () => _showDeleteConfirm(context, onDelete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete resume?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            Icon(
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
