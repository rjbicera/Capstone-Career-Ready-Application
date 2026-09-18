import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/auth_api_service.dart';
import '../services/biometric_service.dart';
import '../services/reauth_helper.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'legal_document_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'set_password_screen.dart';

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
  // Seeded from ThemeController so the switch reflects the saved choice.
  bool _darkMode = ThemeController.instance.isDark;
  bool _biometricLogin = false;
  BiometricCheckResult _biometricStatus = const BiometricCheckResult(
    BiometricStatus.error,
  );
  String _language = 'English';
  bool _isClearingCache = false;
  bool _isExporting = false;
  bool _isDeleting = false;

  static const _languages = [
    _LanguageOption('en', 'English'),
    _LanguageOption('fil', 'Filipino'),
  ];

  @override
  void initState() {
    super.initState();
    _darkMode = ThemeController.instance.isDark;
    _loadBiometricState();
  }

  /// Applies the light/dark choice immediately (so the switch and the
  /// whole app repaint together) and lets ThemeController persist it.
  Future<void> _handleDarkModeToggle(bool value) async {
    setState(() => _darkMode = value);
    await ThemeController.instance.setDarkMode(value);
  }

  Future<void> _loadBiometricState() async {
    final status = await BiometricService.checkStatus();
    final enabled = await BiometricService.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricStatus = status;
      _biometricLogin = enabled && status.isAvailable;
    });
  }

  // ------------------------------------------------------------
  // Which sign-in providers are linked to this account. Used to
  // hide password-only options from Google-only users (they have no
  // password to change) and to label the Linked accounts row.
  // ------------------------------------------------------------
  Set<String> get _providers =>
      FirebaseAuth.instance.currentUser?.providerData
          .map((p) => p.providerId)
          .toSet() ??
      <String>{};

  bool get _hasPassword => _providers.contains('password');
  bool get _hasGoogle => _providers.contains('google.com');

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(
      text,
      style: TextStyle(
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
        color: AppColors.card,
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
                        ? Icon(
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
      backgroundColor: AppColors.card,
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
              Text('Language', style: AppTextStyles.title),
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

  // ------------------------------------------------------------
  // Biometric login
  // ------------------------------------------------------------

  Future<void> _handleBiometricToggle(bool value) async {
    if (!value) {
      await BiometricService.setEnabled(false);
      if (!mounted) return;
      setState(() => _biometricLogin = false);
      return;
    }

    // Re-check right before prompting — status can change between
    // opening Settings and tapping the toggle (e.g. they just enrolled
    // a fingerprint in a different app).
    final status = await BiometricService.checkStatus();
    if (!mounted) return;
    if (!status.isAvailable) {
      setState(() => _biometricStatus = status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status.message ?? 'Biometric login isn\'t available.'),
        ),
      );
      return;
    }

    // Prove the scan actually works on this device before saving the
    // preference — otherwise the user could enable a lock that then
    // fails at launch and shuts them out of their own app.
    final ok = await BiometricService.authenticate(
      reason: 'Scan to enable biometric login',
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric scan cancelled or didn\'t match.'),
        ),
      );
      return;
    }

    await BiometricService.setEnabled(true);
    if (!mounted) return;
    setState(() => _biometricLogin = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Biometric login enabled.')));
  }

  // ------------------------------------------------------------
  // Linked accounts
  // ------------------------------------------------------------

  Future<void> _handleLinkedAccounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_hasGoogle) {
      // Only allow unlinking if they'd still have a way back in.
      if (!_hasPassword) {
        _showMessage(
          'Google is your only sign-in method, so it can\'t be removed. '
          'Set a password first.',
        );
        return;
      }

      final confirmed = await _confirm(
        title: 'Unlink Google?',
        message:
            'You\'ll need to sign in with your email and password from now on.',
        confirmLabel: 'Unlink',
        isDestructive: true,
      );
      if (confirmed != true) return;

      try {
        await user.unlink('google.com');
        await AuthApiService.googleSignIn.signOut();
        if (!mounted) return;
        setState(() {});
        _showMessage('Google account unlinked.');
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        _showMessage(e.message ?? 'Could not unlink Google.');
      }
      return;
    }

    // Not linked yet — run the Google sign-in flow and attach that
    // credential to the existing account rather than creating a
    // second, separate one.
    try {
      await AuthApiService.googleSignIn.signOut();
      final googleUser = await AuthApiService.googleSignIn.signIn();
      if (googleUser == null) return; // Cancelled.

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);
      if (!mounted) return;
      setState(() {});
      _showMessage('Google account linked.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'provider-already-linked':
          message = 'That Google account is already linked.';
          break;
        case 'credential-already-in-use':
          message =
              'That Google account is already used by a different Career Ready account.';
          break;
        case 'requires-recent-login':
          message = 'Please sign out and back in, then try again.';
          break;
        default:
          message = e.message ?? 'Could not link Google.';
      }
      _showMessage(message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not link Google.');
    }
  }

  // ------------------------------------------------------------
  // Export my data
  // ------------------------------------------------------------

  Future<void> _handleExportData() async {
    if (_isExporting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isExporting = true);

    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Session expired.', code: 'TOKEN_UNAVAILABLE');
      }

      final data = await AuthApiService.exportData(idToken: idToken);

      // Write it out as pretty-printed JSON and hand it to the OS
      // share sheet, which lets the user save to Files, email it to
      // themselves, or send it anywhere else — no storage permission
      // needed since it goes to the app's own temp directory.
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/career-ready-data-$stamp.json');
      await file.writeAsString(pretty);

      if (!mounted) return;
      setState(() => _isExporting = false);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'My Career Ready data export',
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showMessage(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      _showMessage('Could not export your data.');
    }
  }

  // ------------------------------------------------------------
  // Clear cache
  // ------------------------------------------------------------

  Future<void> _handleClearCache() async {
    setState(() => _isClearingCache = true);

    try {
      // Actually empties the app's temp directory — image picker
      // copies, previous data exports, and anything else cached there.
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {
            // A file still held open by the OS isn't worth failing over.
          }
        }
      }
    } catch (_) {
      // Non-fatal — fall through to the confirmation either way.
    }

    if (!mounted) return;
    setState(() => _isClearingCache = false);
    _showMessage('Cache cleared.');
  }

  // ------------------------------------------------------------
  // Delete account
  // ------------------------------------------------------------

  Future<void> _handleDeleteAccount() async {
    if (_isDeleting) return;

    final confirmed = await _confirm(
      title: 'Delete account?',
      message:
          'This permanently deletes your profile, resumes, and progress. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true) return;
    if (!mounted) return;

    // Second gate: confirm identity. Firebase requires a recent login
    // for deletion anyway, and it makes an irreversible action
    // deliberate rather than a single mistaken tap.
    final reauthed = await ReauthHelper.reauthenticate(context);
    if (!reauthed || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw ApiException('Session expired.');

      // Force-refresh so the backend sees a token minted after the
      // reauth we just did.
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw ApiException('Session expired.', code: 'TOKEN_UNAVAILABLE');
      }

      // The backend deletes both the Firestore doc and the Auth user,
      // so there's no client-side user.delete() call after this.
      await AuthApiService.deleteAccount(idToken: idToken);

      await AuthApiService.signOut();
      await BiometricService.setEnabled(false);
      AppState.instance.clearProfile();
      await ThemeController.instance.loadForUser(null);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showMessage(e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showMessage('Could not delete your account.');
    }
  }

  // ------------------------------------------------------------
  // Shared UI helpers
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: AppColors.danger)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _handleSetPassword() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SetPasswordScreen()));
    // providerData is re-read live in the getters above, so this just
    // needs a rebuild to flip the row from "Set a password" to
    // "Change password" once one's been added.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _sectionLabel('ACCOUNT'),

            _tile(
              icon: Icons.mail_outline_rounded,
              title: 'Change email',
              subtitle: email ?? 'Update your sign-in email.',
              onTap: () => _open(const ChangeEmailScreen()),
            ),

            // A Google-only account has no password yet — offer to set
            // one rather than hiding the row outright, so users who
            // skipped this at sign-up still have a way to add it.
            _hasPassword
                ? _tile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change password',
                    onTap: () => _open(const ChangePasswordScreen()),
                  )
                : _tile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Set a password',
                    subtitle:
                        'Add a password so you can also sign in without Google.',
                    onTap: _handleSetPassword,
                  ),

            _tile(
              icon: Icons.fingerprint_rounded,
              title: 'Biometric login',
              subtitle: _biometricStatus.isAvailable
                  ? 'Use fingerprint or face unlock to open the app.'
                  : (_biometricStatus.message ??
                        'Biometric login isn\'t available.'),
              trailing: Switch(
                value: _biometricLogin,
                activeThumbColor: AppColors.primary,
                onChanged: _biometricStatus.isAvailable
                    ? _handleBiometricToggle
                    : (_biometricStatus.status ==
                              BiometricStatus.unsupportedPlatform
                          ? null
                          // Hardware/enrollment can change without
                          // reopening this screen (e.g. they back out
                          // to enroll a fingerprint) — let a tap
                          // re-check rather than staying stuck.
                          : (_) => _handleBiometricToggle(true)),
              ),
            ),

            _tile(
              icon: Icons.g_mobiledata_rounded,
              title: 'Linked accounts',
              subtitle: _hasGoogle
                  ? 'Google — connected'
                  : 'Google — not connected',
              onTap: _handleLinkedAccounts,
            ),

            _sectionLabel('NOTIFICATIONS'),
            _tile(
              icon: Icons.notifications_outlined,
              title: 'Notification preferences',
              subtitle: 'Manage what you get notified about.',
              onTap: () => _open(const NotificationsScreen()),
            ),

            _sectionLabel('APPEARANCE & LANGUAGE'),
            _tile(
              icon: _darkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              title: 'Dark mode',
              subtitle: _darkMode
                  ? 'On - using the dark palette.'
                  : 'Off - using the light palette.',
              trailing: Switch(
                value: _darkMode,
                activeThumbColor: AppColors.primary,
                onChanged: _handleDarkModeToggle,
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
                  ? SizedBox(
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
              subtitle: _isExporting
                  ? 'Preparing your export...'
                  : 'Download a copy of your profile data.',
              onTap: _isExporting ? null : _handleExportData,
              trailing: _isExporting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : null,
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
              onTap: () => _open(LegalDocumentScreen.privacyPolicy()),
            ),
            _tile(
              icon: Icons.description_outlined,
              title: 'Terms of service',
              onTap: () => _open(LegalDocumentScreen.termsOfService()),
            ),

            _sectionLabel('DANGER ZONE'),
            _tile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              subtitle: _isDeleting ? 'Deleting...' : null,
              isDestructive: true,
              onTap: _isDeleting ? null : _handleDeleteAccount,
              trailing: _isDeleting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.danger),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
