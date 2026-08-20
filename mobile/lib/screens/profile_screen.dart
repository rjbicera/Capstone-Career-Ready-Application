import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_resumes_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

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
  const ProfileScreen({
    super.key,
    this.userName = 'Jenard Reyes',
    this.userSubtitle = 'BSIT · Networking track',
    this.memberSince = 'Member since Aug 2026',
    this.resumesCount = 1,
    this.interviewsCount = 2,
    this.skillsTracked = 3,
  });

  final String userName;
  final String userSubtitle;
  final String memberSince;
  final int resumesCount;
  final int interviewsCount;
  final int skillsTracked;

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
      backgroundColor: Colors.white,
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
              const Text('Help & Support', style: AppTextStyles.title),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
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
                leading: const Icon(Icons.quiz_outlined, color: AppColors.blue),
                title: const Text('FAQs'),
                onTap: () {
                  // TODO: navigate to FAQ screen or open web view.
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.bug_report_outlined,
                  color: AppColors.blue,
                ),
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: call your Firebase Auth signOut() here.
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
        style: const TextStyle(
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(userName, style: AppTextStyles.title.copyWith(fontSize: 17)),
              const SizedBox(height: 2),
              Text(
                userSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                memberSince,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 18),

              // Quick stats — gives Profile a functional summary role,
              // not just a settings menu.
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
      color: Colors.white,
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
                const Icon(
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
