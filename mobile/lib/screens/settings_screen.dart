import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'notifications_screen.dart';

class _LanguageOption {
  const _LanguageOption(this.code, this.label);
  final String code;
  final String label;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _biometricLogin = false;
  String _language = 'English';
  bool _isClearingCache = false;

  static const _languages = [
    _LanguageOption('en', 'English'),
    _LanguageOption('fil', 'Filipino'),
  ];

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.danger : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    (onTap != null
                        ? const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          )
                        : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Language', style: AppTextStyles.title),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _language,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _language = value);
                  Navigator.of(sheetContext).pop();
                },
                child: Column(
                  children: [
                    ..._languages.map(
                      (lang) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(lang.label),
                        value: lang.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleClearCache() async {
    setState(() => _isClearingCache = true);
    // TODO: clear cached images / local resume drafts / offline data.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isClearingCache = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache cleared.')));
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, resumes, and progress. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: call backend account-deletion endpoint.
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _sectionLabel('ACCOUNT'),
            _tile(
              icon: Icons.lock_outline_rounded,
              title: 'Change password',
              onTap: () {
                // TODO: navigate to change-password flow.
              },
            ),
            _tile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric login',
              subtitle: 'Use fingerprint or face unlock to sign in.',
              trailing: Switch(
                value: _biometricLogin,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _biometricLogin = v),
              ),
            ),
            _tile(
              icon: Icons.g_mobiledata_rounded,
              title: 'Linked accounts',
              subtitle: 'Google — not connected',
              onTap: () {
                // TODO: trigger Google account linking flow.
              },
            ),

            _sectionLabel('NOTIFICATIONS'),
            _tile(
              icon: Icons.notifications_outlined,
              title: 'Notification preferences',
              subtitle: 'Manage what you get notified about.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),

            _sectionLabel('APPEARANCE & LANGUAGE'),
            _tile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              subtitle: 'Currently in development.',
              trailing: Switch(
                value: _darkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
            ),
            _tile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: _language,
              onTap: _showLanguagePicker,
            ),

            _sectionLabel('DATA & STORAGE'),
            _tile(
              icon: Icons.cleaning_services_outlined,
              title: 'Clear cache',
              subtitle: _isClearingCache
                  ? 'Clearing...'
                  : 'Free up local storage.',
              onTap: _isClearingCache ? null : _handleClearCache,
              trailing: _isClearingCache
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : null,
            ),
            _tile(
              icon: Icons.download_outlined,
              title: 'Export my data',
              subtitle: 'Download a copy of your resumes and progress.',
              onTap: () {
                // TODO: trigger data export job.
              },
            ),

            _sectionLabel('ABOUT'),
            _tile(
              icon: Icons.info_outline_rounded,
              title: 'App version',
              subtitle: '1.0.0',
            ),
            _tile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              onTap: () {
                // TODO: open privacy policy (web view or external link).
              },
            ),
            _tile(
              icon: Icons.description_outlined,
              title: 'Terms of service',
              onTap: () {
                // TODO: open terms of service.
              },
            ),

            _sectionLabel('DANGER ZONE'),
            _tile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              isDestructive: true,
              onTap: _handleDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
