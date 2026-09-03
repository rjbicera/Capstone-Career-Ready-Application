import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'main_navigation.dart';

class DemographicProfileScreen extends StatefulWidget {
  const DemographicProfileScreen({super.key});

  @override
  State<DemographicProfileScreen> createState() =>
      _DemographicProfileScreenState();
}

class _DemographicProfileScreenState extends State<DemographicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _genderController = TextEditingController();

  String? _course;
  String? _yearLevel;

  bool _isSubmitting = false;
  String? _errorText;

  static const List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  @override
  void dispose() {
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSubmitting) {
      return;
    }

    if (_course == null) {
      setState(() {
        _errorText = 'Please select your program.';
      });
      return;
    }

    if (_yearLevel == null) {
      setState(() {
        _errorText = 'Please select your year level.';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _errorText = 'Your session has expired. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      // Get the currently signed-in Firebase ID token.
      final idToken = await user.getIdToken();

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'invalid-id-token');
      }

      // Save demographic information to the backend.
      await AuthApiService.updateDemographics(
        idToken: idToken,
        course: _course!,
        yearLevel: _yearLevel!,
        gender: _genderController.text.trim().isEmpty
            ? null
            : _genderController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      // Profile is complete.
      // Remove previous screens and enter the main application.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = e.message;
        _isSubmitting = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = e.message;
        _isSubmitting = false;
      });
    } on FirebaseAuthException catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText =
            'Your session could not be verified. Please sign in again.';
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Something went wrong while saving your profile.';
        _isSubmitting = false;
      });
    }
  }

  Widget _programCard({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = _course == value;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _course = value;
                _errorText = null;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueLight : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.blue : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        type: AppBackgroundType.auth,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tell us about yourself',
                    style: AppTextStyles.headline,
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'This helps us personalize your career preparation experience.',
                    style: AppTextStyles.body,
                  ),

                  const SizedBox(height: 32),

                  const Text('Program', style: AppTextStyles.caption),

                  const SizedBox(height: 8),

                  _programCard(
                    value: 'BSIT',
                    title: 'BSIT',
                    description: 'Information Technology and computing careers',
                    icon: Icons.computer_outlined,
                  ),

                  const SizedBox(height: 10),

                  _programCard(
                    value: 'BSBA',
                    title: 'BSBA',
                    description: 'Business and management-related careers',
                    icon: Icons.business_center_outlined,
                  ),

                  const SizedBox(height: 24),

                  const Text('Year level', style: AppTextStyles.caption),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    initialValue: _yearLevel,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(
                      hintText: 'Select your year level',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: _yearLevels.map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _yearLevel = value;
                              _errorText = null;
                            });
                          },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Select your year level.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  const Text('Gender', style: AppTextStyles.caption),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _genderController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Optional',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Optional. This information is used only for demographic profiling.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),

                  if (_errorText != null) ...[
                    const SizedBox(height: 16),

                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveProfile,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Text(
                      'You can update your profile later in Settings.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
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
