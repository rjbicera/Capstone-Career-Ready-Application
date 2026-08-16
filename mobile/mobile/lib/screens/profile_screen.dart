import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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
  });

  final String userName;
  final String userSubtitle;

  static const _actions = [
    _MenuAction(icon: Icons.edit_outlined, label: 'Edit profile'),
    _MenuAction(icon: Icons.folder_outlined, label: 'Saved resumes'),
    _MenuAction(icon: Icons.notifications_outlined, label: 'Notifications'),
    _MenuAction(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text(
              userName,
              style: AppTextStyles.title.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 2),
            Text(
              userSubtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            ..._actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _MenuTile(
                  action: action,
                  onTap: () {
                    // TODO: route to the relevant screen for this action.
                  },
                ),
              ),
            ),
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
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.action, required this.onTap});

  final _MenuAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = action.isDestructive ? AppColors.danger : AppColors.textPrimary;

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
