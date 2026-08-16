import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorText;

  // TEMP: hardcoded test account for development only.
  // Remove this once Firebase Auth is wired in.
  static const _tempEmail = 'jenard@gmail.com';
  static const _tempPassword = '12345678';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    // TODO: replace this whole block with your Firebase Auth sign-in call.
    await Future.delayed(const Duration(milliseconds: 600));

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isValid = email == _tempEmail && password == _tempPassword;

    if (!mounted) return;

    if (!isValid) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Incorrect email or password.';
      });
      return;
    }

    setState(() => _isSubmitting = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back', style: AppTextStyles.headline),
              const SizedBox(height: 6),
              const Text(
                'Sign in to continue your prep',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),

              const Text('Email', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'jenard@gmail.com'),
              ),
              const SizedBox(height: 16),

              const Text('Password', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: navigate to forgot-password flow.
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSignIn,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or', style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
                  // TODO: wire up Google sign-in.
                },
                icon: const Icon(Icons.g_mobiledata, size: 22),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 24),

              Center(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                    children: const [
                      TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
