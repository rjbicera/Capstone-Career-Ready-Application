import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../services/auth_api_service.dart';
import 'demographic_profile_screen.dart';
import 'main_navigation.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

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
  bool _isGoogleSubmitting = false;
  String? _errorText;

  final _googleSignIn = AuthApiService.googleSignIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Maps FirebaseAuth's error codes to user-facing copy. Deliberately
  /// vague on which of email/password is wrong (avoids leaking which
  /// emails have accounts), consistent with the security policy already
  /// referenced elsewhere in this codebase (see authMiddleware.js).
  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another sign-in method.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';

      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';

      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  /// Shared by both sign-in paths (email/password and Google) once
  /// FirebaseAuth has a session — decides whether this account still
  /// needs the demographic-profiling step (SDD v1.6) before landing on
  /// the main app.
  ///
  /// A brand-new Google account has no users/{uid} doc at all yet (GET
  /// /auth/me 404s USER_NOT_FOUND), and a plain email account always has
  /// one but may have profileComplete: false if this is its first
  /// sign-in after registering. Both cases route to
  /// DemographicProfileScreen; anything else goes straight to the app.
  ///
  /// If the backend can't be reached, this deliberately still lets the
  /// user into the app rather than stranding them on the login screen —
  /// they'll just get asked for demographics next time it succeeds.
  Future<void> _routeAfterSignIn() async {
    if (!mounted) return;

    Widget destination = const MainNavigation();
    try {
      final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
      final me = await AuthApiService.me(idToken: idToken!);
      if (me['profileComplete'] != true) {
        destination = const DemographicProfileScreen();
      }
    } on ApiException catch (e) {
      if (e.code == 'USER_NOT_FOUND') {
        destination = const DemographicProfileScreen();
      }
      // Any other API error: fall through to MainNavigation rather than
      // blocking sign-in on a profile-completeness check.
    } catch (_) {
      // Network/unexpected error — same reasoning as above.
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSubmitting || _isGoogleSubmitting) {
      return;
    }

    setState(() {
      _isGoogleSubmitting = true;
      _errorText = null;
    });

    try {
      final googleUser = await _googleSignIn.signIn();

      // User closed the Google account picker.
      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isGoogleSubmitting = false;
          });
        }
        return;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'google-no-token',
          message: 'Google did not return a valid sign-in token.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase handles both cases:
      //
      // Existing Google account:
      //     sign in
      //
      // New Google account:
      //     create account + sign in
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE FIREBASE ERROR: ${e.code}');
      debugPrint('GOOGLE FIREBASE MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        _isGoogleSubmitting = false;
        _errorText = _messageForAuthError(e);
      });

      return;
    } catch (e) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isGoogleSubmitting = false;
        _errorText = 'Google sign-in failed. Please try again.';
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _isGoogleSubmitting = false;
    });

    await _routeAfterSignIn();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Enter your email and password.';
      });
      return;
    }

    try {
      // Same Firebase project signup_screen.dart registers into — the
      // register endpoint creates the account server-side, this call
      // just establishes the client session against it.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = _messageForAuthError(e);
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = 'Something went wrong. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    await _routeAfterSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        type: AppBackgroundType.auth,
        child: SafeArea(
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
                  decoration: const InputDecoration(
                    hintText: 'Username or email address',
                  ),
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: (_isSubmitting || _isGoogleSubmitting)
                      ? null
                      : _handleSignIn,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
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
                  onPressed: (_isSubmitting || _isGoogleSubmitting)
                      ? null
                      : _handleGoogleSignIn,
                  icon: _isGoogleSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata, size: 22),
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
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
