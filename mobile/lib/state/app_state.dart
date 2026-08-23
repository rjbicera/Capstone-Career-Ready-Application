import 'package:flutter/foundation.dart';

/// Single in-memory source of truth for cross-screen data.
///
/// This is intentionally NOT tied to Firestore yet — the backend doesn't
/// have resume/skills/interview endpoints implemented at this point (see
/// backend/src, which currently only has firebaseAdmin config + auth
/// middleware). Once those endpoints exist, replace the setters below
/// with real API calls and keep the same public interface so screens
/// don't need to change.
///
/// Usage: AppState.instance is a singleton. Screens that display data
/// wrap themselves in a ListenableBuilder(listenable: AppState.instance, ...)
/// so they rebuild automatically when any setter below is called.
class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();

  // ---- Resume ----
  int? resumeScore; // null = no resume analyzed yet
  String? resumeFileName;

  void setResume({required int score, required String fileName}) {
    resumeScore = score;
    resumeFileName = fileName;
    notifyListeners();
  }

  // ---- Mock interview ----
  int interviewsCompleted = 0;
  static const int _interviewsForFullCredit = 5;

  void recordInterviewCompleted() {
    interviewsCompleted++;
    notifyListeners();
  }

  // ---- Skills assessment ----
  final Map<String, double> skillsProgress = {
    'Networking fundamentals': 0.90,
    'Cloud fundamentals': 0.64,
    'Security basics': 0.48,
  };

  void updateSkill(String category, double progress) {
    skillsProgress[category] = progress;
    notifyListeners();
  }

  double get skillsAverage {
    if (skillsProgress.isEmpty) return 0;
    final total = skillsProgress.values.reduce((a, b) => a + b);
    return total / skillsProgress.length;
  }

  // ---- Composite readiness score shown on Home ----
  // Weighted: resume 40%, skills 40%, interview activity 20%.
  // Weights are a placeholder — align with whatever the SDD's
  // readiness-scoring formula ends up being once that's finalized.
  double get overallReadiness {
    final resumeComponent = (resumeScore ?? 0) / 100;
    final interviewComponent =
        (interviewsCompleted / _interviewsForFullCredit).clamp(0.0, 1.0);
    return (resumeComponent * 0.4) +
        (skillsAverage * 0.4) +
        (interviewComponent * 0.2);
  }
}
