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
  String? photoUrl;
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
    photoUrl = data['photoUrl'] as String?;
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
    photoUrl = null;
    memberSince = null;
    // Skill category keys are course-specific (BSIT vs BSBA) — clear
    // them on sign-out too, or a different course's categories on the
    // next login would sit alongside stale ones from this session.
    skillsProgress.clear();
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
  // Kept empty until [ensureDefaultSkillsSeeded] fills it in based on
  // [course], so BSIT and BSBA users never share default category keys.
  final Map<String, double> skillsProgress = {};

  /// Course-appropriate category list for the skills assessment screen
  /// and the quiz question bank. BSIT keeps the original IT-flavored
  /// categories; BSBA gets a business/management-flavored set. Defaults
  /// to the BSIT set if course hasn't been set yet (e.g. mid-onboarding).
  List<String> get skillCategoriesForCourse {
    if (course == 'BSBA') {
      return const [
        'Financial fundamentals',
        'Marketing fundamentals',
        'Management basics',
      ];
    }
    return const [
      'Networking fundamentals',
      'Cloud fundamentals',
      'Security basics',
    ];
  }

  /// Seeds [skillsProgress] with placeholder values for the current
  /// course the first time it's needed (e.g. on first visit to the
  /// skills assessment screen), so the progress bars have something to
  /// show before the user has taken any quiz. No-op if already seeded.
  void ensureDefaultSkillsSeeded() {
    if (skillsProgress.isNotEmpty) return;
    if (course == 'BSBA') {
      skillsProgress.addAll({
        'Financial fundamentals': 0.72,
        'Marketing fundamentals': 0.58,
        'Management basics': 0.45,
      });
    } else {
      skillsProgress.addAll({
        'Networking fundamentals': 0.90,
        'Cloud fundamentals': 0.64,
        'Security basics': 0.48,
      });
    }
  }

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
