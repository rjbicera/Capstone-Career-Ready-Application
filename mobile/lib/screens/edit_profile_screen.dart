import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../services/auth_api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _careerGoalController;
  late final TextEditingController _customGenderController;

  String? _course;
  String? _yearLevel;
  String? _gender;

  bool _isSaving = false;
  String? _errorText;

  static const List<String> _courses = ['BSIT', 'BSBA'];
  static const List<String> _yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  // Same inclusive list as the demographic-profiling step, so gender
  // stays editable with the same LGBTQ+-inclusive options here too.
  static const String _selfDescribeOption = 'Prefer to self-describe';
  static const List<String> _genderOptions = [
    'Woman',
    'Man',
    'Non-binary',
    'Transgender woman',
    'Transgender man',
    'Genderqueer',
    'Genderfluid',
    'Agender',
    _selfDescribeOption,
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill from AppState — this user's own saved values, not a
    // shared placeholder.
    final state = AppState.instance;
    _nameController = TextEditingController(text: state.fullName ?? '');
    _nicknameController = TextEditingController(text: state.nickname ?? '');
    _careerGoalController =
        TextEditingController(text: state.careerGoal ?? '');
    _course = _courses.contains(state.course) ? state.course : null;
    _yearLevel = _yearLevels.contains(state.yearLevel) ? state.yearLevel : null;

    final savedGender = state.gender;
    if (savedGender != null && _genderOptions.contains(savedGender)) {
      _gender = savedGender;
      _customGenderController = TextEditingController();
    } else if (savedGender != null && savedGender.isNotEmpty) {
      // A custom value saved earlier — preselect "Prefer to
      // self-describe" and restore their own wording.
      _gender = _selfDescribeOption;
      _customGenderController = TextEditingController(text: savedGender);
    } else {
      _customGenderController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _careerGoalController.dispose();
    _customGenderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      setState(() => _errorText = 'Full name can\'t be empty.');
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
      _isSaving = true;
      _errorText = null;
    });

    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(code: 'invalid-id-token');
      }

      String? genderToSend;
      if (_gender == _selfDescribeOption) {
        final custom = _customGenderController.text.trim();
        genderToSend = custom.isEmpty ? null : custom;
      } else {
        genderToSend = _gender;
      }

      final nickname = _nicknameController.text.trim();
      final careerGoal = _careerGoalController.text.trim();

      final result = await AuthApiService.updateProfile(
        idToken: idToken,
        fullName: fullName,
        nickname: nickname.isEmpty ? null : nickname,
        careerGoal: careerGoal.isEmpty ? null : careerGoal,
        course: _course,
        yearLevel: _yearLevel,
        gender: genderToSend,
      );

      if (!mounted) return;

      // Push the saved profile straight into AppState so Home's
      // greeting and Profile's header update immediately — no need
      // to re-fetch or pass a callback back up the navigator.
      AppState.instance.loadProfile(result);

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _isSaving = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.message;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Something went wrong while saving your profile.';
        _isSaving = false;
      });
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: hint != null ? InputDecoration(hintText: hint) : null,
          ),
        ],
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<T> options,
    required String hint,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: value,
            dropdownColor: AppColors.card,
            isExpanded: true,
            decoration: InputDecoration(hintText: hint),
            items: options
                .map(
                  (o) => DropdownMenuItem<T>(
                    value: o,
                    child: Text('$o', overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _isSaving ? null : onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Edit profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.blueLight,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: open image picker for a new profile photo.
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              _field(label: 'Full name', controller: _nameController),

              _field(
                label: 'Nickname',
                controller: _nicknameController,
                hint: 'What Home should greet you as',
              ),

              _dropdownField<String>(
                label: 'Program',
                value: _course,
                options: _courses,
                hint: 'Select your program',
                onChanged: (value) => setState(() => _course = value),
              ),

              _dropdownField<String>(
                label: 'Year level',
                value: _yearLevel,
                options: _yearLevels,
                hint: 'Select your year level',
                onChanged: (value) => setState(() => _yearLevel = value),
              ),

              _field(
                label: 'Career goal',
                controller: _careerGoalController,
                hint: 'e.g. Cloud Engineer',
              ),

              _dropdownField<String>(
                label: 'Gender',
                value: _gender,
                options: _genderOptions,
                hint: 'Optional',
                onChanged: (value) => setState(() => _gender = value),
              ),

              if (_gender == _selfDescribeOption)
                _field(
                  label: 'Tell us how you identify',
                  controller: _customGenderController,
                ),

              if (_errorText != null) ...[
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
