import 'package:flutter/foundation.dart';

/// Single in-memory source of truth for cross-screen data.
///
/// This is intentionally NOT tied to Firestore for the resume/skills/
/// interview activity below — the backend doesn't have those endpoints
/// implemented yet. The profile fields ARE backed by Firestore (via
/// AuthApiService.me / updateDemographics / updateProfile) — call
/// [loadProfile] with whatever those calls return so every screen
/// listening to AppState.instance picks up the change immediately.
///
/// Usage: AppState.instance is a singleton. Screens that display data
/// wrap themselves in a ListenableBuilder(listenable: AppState.instance, ...)
/// so they rebuild automatically when any setter below is called.
class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();

  // ---- Profile (backed by the users/{uid} Firestore doc) ----
  String? fullName;
  String? nickname;
  String? email;
  String? course;
  String? yearLevel;
  String? gender;
  String? careerGoal;
  String? memberSince; // ISO createdAt from the backend

  /// Populate the profile fields from a /auth/me, PATCH /auth/me, or
  /// PATCH /auth/me/profile response body. Safe to call repeatedly —
  /// each call just refreshes whatever the backend currently has.
  void loadProfile(Map<String, dynamic> data) {
    fullName = data['fullName'] as String?;
    nickname = data['nickname'] as String?;
    email = data['email'] as String?;
    course = data['course'] as String?;
    yearLevel = data['yearLevel'] as String?;
    gender = data['gender'] as String?;
    careerGoal = data['careerGoal'] as String?;
    memberSince = data['createdAt'] as String?;
    notifyListeners();
  }

  /// Clears profile data on sign-out so the next signed-in user never
  /// briefly sees the previous user's name/greeting.
  void clearProfile() {
    fullName = null;
    nickname = null;
    email = null;
    course = null;
    yearLevel = null;
    gender = null;
    careerGoal = null;
    memberSince = null;
    notifyListeners();
  }

  /// What screens should greet/display the user by. Prefers the
  /// nickname (set during demographic profiling or Edit profile);
  /// falls back to the first word of the full name, then a generic
  /// placeholder if neither is available yet.
  String get displayName {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return nickname!.trim();
    }
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim().split(' ').first;
    }
    return 'there';
  }

  /// "BSIT · Cloud Engineer"-style subtitle for the profile header.
  /// Falls back gracefully if either half hasn't been set yet.
  String get courseAndGoalSubtitle {
    final parts = <String>[
      if (course != null && course!.isNotEmpty) course!,
      if (careerGoal != null && careerGoal!.isNotEmpty) careerGoal!,
    ];
    return parts.isEmpty ? 'Complete your profile' : parts.join(' · ');
  }

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
