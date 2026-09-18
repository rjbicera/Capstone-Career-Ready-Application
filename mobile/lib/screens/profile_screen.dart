import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_resumes_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../services/auth_api_service.dart';
import '../theme/theme_controller.dart';

class _MenuAction {
  const _MenuAction({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _accountActions = [
    _MenuAction(icon: Icons.edit_outlined, label: 'Edit profile'),
    _MenuAction(icon: Icons.folder_outlined, label: 'Saved resumes'),
    _MenuAction(icon: Icons.notifications_outlined, label: 'Notifications'),
    _MenuAction(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  static const _supportActions = [
    _MenuAction(icon: Icons.help_outline_rounded, label: 'Help & Support'),
    _MenuAction(icon: Icons.info_outline_rounded, label: 'About'),
  ];

  void _handleMenuTap(BuildContext context, String label) {
    Widget destination;
    switch (label) {
      case 'Edit profile':
        destination = const EditProfileScreen();
        break;
      case 'Saved resumes':
        destination = const SavedResumesScreen();
        break;
      case 'Notifications':
        destination = const NotificationsScreen();
        break;
      case 'Settings':
        destination = const SettingsScreen();
        break;
      case 'Help & Support':
        _showHelpSheet(context);
        return;
      case 'About':
        _showAboutSheet(context);
        return;
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & Support', style: AppTextStyles.title),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.mail_outline_rounded,
                  color: AppColors.blue,
                ),
                title: const Text('Contact support'),
                subtitle: const Text('careerready.support@example.com'),
                onTap: () {
                  // TODO: launch mailto: or in-app contact form.
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.quiz_outlined, color: AppColors.blue),
                title: const Text('FAQs'),
                onTap: () {
                  // TODO: navigate to FAQ screen or open web view.
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.bug_report_outlined, color: AppColors.blue),
                title: const Text('Report a bug'),
                onTap: () {
                  // TODO: open bug report form.
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About Career Ready'),
        content: const Text(
          'Career Ready v1.0.0\n\nAn AI-powered career preparation app helping students '
          'get resume feedback, practice mock interviews, and track skill readiness.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content: const Text('You\'ll need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Without this, the Firebase ID token stays valid and
              // /auth/me-style authenticated requests would keep working
              // even after the user is dropped back on the login screen.
              await AuthApiService.signOut();
              // Drop the previous user's profile so it can't flash on
              // screen for whoever signs in next on this device.
              AppState.instance.clearProfile();
              // Same for their Dark mode choice — back to the guest
              // default until the next account signs in and its own
              // preference (if any) is loaded.
              await ThemeController.instance.loadForUser(null);
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 18),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.4,
        ),
      ),
    ),
  );

  Widget _statChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  String _memberSinceLabel(String? isoDate) {
    if (isoDate == null) return 'Member';
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return 'Member';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Member since ${months[parsed.month - 1]} ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever AppState changes — e.g. right after Edit
    // profile saves — so this screen always reflects the signed-in
    // user instead of a fixed placeholder.
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppState.instance,
        ThemeController.instance,
      ]),
      builder: (context, _) {
        final state = AppState.instance;
        final userName = state.fullName ?? state.displayName;
        final resumesCount = state.resumeFileName != null ? 1 : 0;
        final interviewsCount = state.interviewsCompleted;
        final skillsTracked = state.skillsProgress.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.blueLight,
                    backgroundImage: state.photoUrl != null
                        ? NetworkImage(state.photoUrl!)
                        : null,
                    child: state.photoUrl == null
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  // "BSIT · Cloud Engineer" — pulled from this user's
                  // own course and career goal, not a shared default.
                  Text(
                    state.courseAndGoalSubtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _memberSinceLabel(state.memberSince),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quick stats — gives Profile a functional summary role,
                  // not just a settings menu. Numbers now come from this
                  // user's actual activity in AppState.
                  Row(
                    children: [
                      _statChip('$resumesCount', 'Resumes'),
                      const SizedBox(width: 8),
                      _statChip('$interviewsCount', 'Interviews'),
                      const SizedBox(width: 8),
                      _statChip('$skillsTracked', 'Skills tracked'),
                    ],
                  ),

                  _sectionLabel('ACCOUNT'),
                  ..._accountActions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _MenuTile(
                        action: action,
                        onTap: () => _handleMenuTap(context, action.label),
                      ),
                    ),
                  ),

                  _sectionLabel('SUPPORT'),
                  ..._supportActions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _MenuTile(
                        action: action,
                        onTap: () => _handleMenuTap(context, action.label),
                      ),
                    ),
                  ),

                  const SizedBox(height: 9),
                  _MenuTile(
                    action: const _MenuAction(
                      icon: Icons.logout_rounded,
                      label: 'Log out',
                      isDestructive: true,
                    ),
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.action, required this.onTap});

  final _MenuAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive
        ? AppColors.danger
        : AppColors.textPrimary;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 19, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (!action.isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
