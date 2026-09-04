import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'demographic_profile_screen.dart';
import 'main_navigation.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  final _confirmController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: const ['email']);

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  String? _submitError;

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();

    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Enter your email.';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter a password.';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  String _messageForApiError(ApiException e) {
    switch (e.code) {
      case 'EMAIL_IN_USE':
        return 'An account with this email already exists.';

      case 'WEAK_PASSWORD':
        return 'Choose a stronger password.';

      case 'VALIDATION_ERROR':
        return e.message;

      default:
        return e.message;
    }
  }

  String _messageForGoogleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another sign-in method.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';

      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Google sign-in was cancelled.';

      case 'user-disabled':
        return 'This account has been disabled.';

      default:
        return e.message ?? 'Google sign-up failed. Please try again.';
    }
  }

  Future<void> _routeAfterSignIn() async {
    if (!mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(code: 'no-current-user');
      }

      final idToken = await user.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'invalid-id-token');
      }

      final me = await AuthApiService.me(idToken: idToken);

      if (!mounted) return;

      final Widget destination = me['profileComplete'] == true
          ? const MainNavigation()
          : const DemographicProfileScreen();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isGoogleSubmitting = false;
        _submitError = e.message;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isGoogleSubmitting = false;
        _submitError = e.message;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isGoogleSubmitting = false;
        _submitError = _messageForGoogleError(e);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isGoogleSubmitting = false;
        _submitError = 'Could not load your profile. Please try again.';
      });
    }
  }

  Future<void> _handleGoogleSignUp() async {
    if (_isSubmitting || _isGoogleSubmitting) {
      return;
    }

    setState(() {
      _isGoogleSubmitting = true;
      _submitError = null;
    });

    try {
      final googleUser = await _googleSignIn.signIn();

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

      // Firebase automatically creates the
      // account if this Google account is new.
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE SIGN-UP ERROR: ${e.code}');

      debugPrint('GOOGLE SIGN-UP MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        _isGoogleSubmitting = false;
        _submitError = _messageForGoogleError(e);
      });

      return;
    } catch (e) {
      debugPrint('GOOGLE SIGN-UP ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isGoogleSubmitting = false;
        _submitError = 'Google sign-up failed. Please try again.';
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _isGoogleSubmitting = false;
    });

    await _routeAfterSignIn();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final email = _emailController.text.trim();

    final password = _passwordController.text;

    final fullName = _nameController.text.trim();

    try {
      // Create Firebase Auth account
      // through the backend.
      await AuthApiService.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Establish the client Firebase session.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submitError = _messageForApiError(e);
      });

      return;
    } on NetworkException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submitError = e.message;
      });

      return;
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submitError =
            e.message ?? 'Could not sign in after creating the account.';
      });

      return;
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submitError = 'Something went wrong. Please try again.';
      });

      return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    await _routeAfterSignIn();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isSubmitting || _isGoogleSubmitting;

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: AppBackground(
        type: AppBackgroundType.auth,

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),

            child: Form(
              key: _formKey,

              autovalidateMode: AutovalidateMode.onUserInteraction,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  IconButton(
                    onPressed: busy
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                          },

                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),

                    padding: EdgeInsets.zero,

                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Create your account',
                    style: AppTextStyles.headline,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Start prepping for the career you want',
                    style: AppTextStyles.body,
                  ),

                  const SizedBox(height: 28),

                  const Text('Full name', style: AppTextStyles.caption),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _nameController,

                    textCapitalization: TextCapitalization.words,

                    decoration: const InputDecoration(hintText: 'Jenard Reyes'),

                    validator: _validateName,
                  ),

                  const SizedBox(height: 16),

                  const Text('Email', style: AppTextStyles.caption),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _emailController,

                    keyboardType: TextInputType.emailAddress,

                    autocorrect: false,

                    decoration: const InputDecoration(
                      hintText: 'you@email.com',
                    ),

                    validator: _validateEmail,
                  ),

                  const SizedBox(height: 16),

                  const Text('Password', style: AppTextStyles.caption),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _passwordController,

                    obscureText: _obscurePassword,

                    decoration: InputDecoration(
                      hintText: 'At least 8 characters',

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,

                          color: AppColors.textMuted,

                          size: 20,
                        ),

                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    validator: _validatePassword,
                  ),

                  const SizedBox(height: 16),

                  const Text('Confirm password', style: AppTextStyles.caption),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _confirmController,

                    obscureText: _obscureConfirm,

                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,

                          color: AppColors.textMuted,

                          size: 20,
                        ),

                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),

                    validator: _validateConfirm,
                  ),

                  if (_submitError != null) ...[
                    const SizedBox(height: 14),

                    Text(
                      _submitError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: busy ? null : _handleSignUp,

                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Create account'),
                    ),
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

                  SizedBox(
                    width: double.infinity,

                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _handleGoogleSignUp,

                      icon: _isGoogleSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 24),

                      label: const Text('Continue with Google'),
                    ),
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
                          const TextSpan(text: 'Already have an account? '),

                          TextSpan(
                            text: 'Sign in',

                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),

                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).maybePop();
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
      ),
    );
  }
}
