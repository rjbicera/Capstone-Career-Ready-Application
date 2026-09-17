import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_api_service.dart';

/// Firebase requires a *recent* sign-in before it will allow sensitive
/// account changes (password change, email change, account deletion).
/// If the user signed in a while ago, those calls fail with
/// `requires-recent-login` no matter how valid their session is.
///
/// This helper handles that in one place: it works out how the user
/// originally signed in and reauthenticates them the matching way —
/// a password prompt for email/password accounts, a silent Google
/// re-consent for Google accounts.
class ReauthHelper {
  /// Returns true if the user successfully reauthenticated, false if
  /// they cancelled or it failed (an error message is shown for
  /// failures; cancelling is silent).
  static Future<bool> reauthenticate(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // providerData tells us how this account actually signs in. An
    // account can have both (if Google was linked to an email/password
    // account), in which case the password prompt is the better UX —
    // it doesn't bounce the user out to a browser.
    final providers = user.providerData.map((p) => p.providerId).toSet();

    if (providers.contains('password')) {
      return _reauthWithPassword(context, user);
    }

    if (providers.contains('google.com')) {
      return _reauthWithGoogle(context, user);
    }

    _showError(
      context,
      'This account type can\'t be reauthenticated in the app yet.',
    );
    return false;
  }

  static Future<bool> _reauthWithPassword(
    BuildContext context,
    User user,
  ) async {
    final password = await _promptForPassword(context);
    if (password == null || password.isEmpty) return false;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return false;
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _showError(context, 'That password is incorrect.');
      } else if (e.code == 'too-many-requests') {
        _showError(context, 'Too many attempts. Try again later.');
      } else {
        _showError(context, e.message ?? 'Could not verify your identity.');
      }
      return false;
    } catch (_) {
      if (!context.mounted) return false;
      _showError(context, 'Could not verify your identity.');
      return false;
    }
  }

  static Future<bool> _reauthWithGoogle(BuildContext context, User user) async {
    try {
      // Sign out of the Google session first so the account chooser
      // actually appears — otherwise it silently reuses the cached
      // account, which defeats the point of a confirmation step.
      await AuthApiService.googleSignIn.signOut();

      final googleUser = await AuthApiService.googleSignIn.signIn();
      if (googleUser == null) return false; // User cancelled.

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return false;
      if (e.code == 'user-mismatch') {
        _showError(
          context,
          'Please choose the same Google account you signed in with.',
        );
      } else {
        _showError(context, e.message ?? 'Could not verify your identity.');
      }
      return false;
    } catch (_) {
      if (!context.mounted) return false;
      _showError(context, 'Could not verify your identity.');
      return false;
    }
  }

  static Future<String?> _promptForPassword(BuildContext context) {
    final controller = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm your password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For your security, please re-enter your password to continue.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Current password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    onPressed: () =>
                        setDialogState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (value) =>
                    Navigator.of(dialogContext).pop(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
