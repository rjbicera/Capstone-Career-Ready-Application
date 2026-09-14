import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      _showError('You are not signed in.');
      return;
    }

    setState(() => _saving = true);

    try {
      // Re-authentication is required for this sensitive operation.
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Your current password is incorrect.';
          break;
        case 'weak-password':
        case 'password-does-not-meet-requirements':
          message = 'Your new password is too weak.';
          break;
        case 'requires-recent-login':
          message = 'Please sign in again before changing your password.';
          break;
        default:
          message = e.message ?? 'Unable to change your password.';
      }

      _showError(message);
    } catch (_) {
      _showError('Unable to change your password. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
    bool obscure,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: toggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Change your password', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              const Text(
                'For your security, you must enter your current password first.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: _decoration(
                  'Current password',
                  Icons.lock_outline,
                  _obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your current password.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: _decoration(
                  'New password',
                  Icons.lock_reset_outlined,
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _decoration(
                  'Confirm new password',
                  Icons.verified_user_outlined,
                  _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _changePassword,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Change password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
