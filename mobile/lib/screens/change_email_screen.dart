import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/reauth_helper.dart';
import '../theme/app_theme.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _isSent = false;
  String? _errorText;

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  String get _currentEmail =>
      FirebaseAuth.instance.currentUser?.email ?? 'your current address';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your new email.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    if (v.toLowerCase() ==
        FirebaseAuth.instance.currentUser?.email?.toLowerCase()) {
      return 'That\'s already your email address.';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorText = 'Your session has expired. Please sign in again.';
      });
      return;
    }

    // Changing an email is a sensitive operation — Firebase rejects it
    // outright if the sign-in is stale, so confirm identity first.
    final reauthed = await ReauthHelper.reauthenticate(context);
    if (!reauthed) return;

    if (!mounted) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      // verifyBeforeUpdateEmail (not the deprecated updateEmail) sends a
      // confirmation link to the NEW address and only switches the
      // account over once it's clicked. That's what stops someone from
      // locking a user out by typing an address they don't control.
      await user.verifyBeforeUpdateEmail(_emailController.text.trim());

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'That email is already used by another account.';
          break;
        case 'invalid-email':
          message = 'That email address isn\'t valid.';
          break;
        case 'requires-recent-login':
          message = 'Please sign out and back in, then try again.';
          break;
        default:
          message = e.message ?? 'Could not update your email.';
      }
      setState(() {
        _errorText = message;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Change email',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: _isSent ? _buildSentState() : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account currently uses $_currentEmail.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 6),
            Text(
              'We\'ll send a confirmation link to your new address. '
              'Your email only changes once you click it.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            Text('New email', style: AppTextStyles.caption),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Send confirmation link'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text('Confirm your new email', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'We sent a link to ${_emailController.text.trim()}. '
              'Open it to finish switching your account over — until then, '
              'keep signing in with your current email.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
