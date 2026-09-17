import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Renders Privacy Policy / Terms of Service in-app.
///
/// Deliberately bundled rather than loaded from a URL: the app has no
/// hosted marketing site yet, and an in-app copy still works offline
/// and can't 404 during a demo. Swap in a WebView or url_launcher once
/// there's a real hosted version to point at.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.sections,
    required this.lastUpdated,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  /// NOTE FOR THE TEAM: this is placeholder text written to be
  /// reasonable and honest about what the app actually does. It is not
  /// legal advice and should be reviewed before any public release.
  factory LegalDocumentScreen.privacyPolicy() {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      lastUpdated: 'Last updated: September 2026',
      sections: [
        LegalSection(
          heading: 'Information we collect',
          body:
              'When you create an account we collect your name, email address, '
              'and the demographic details you provide during profile setup — '
              'your nickname, program (BSIT or BSBA), year level, and, if you '
              'choose to share it, your gender. Gender is optional and you may '
              'skip it or select "Prefer not to say".\n\n'
              'We also store the content you create in the app: uploaded '
              'resumes, skills assessment results, and mock interview activity.',
        ),
        LegalSection(
          heading: 'How we use your information',
          body:
              'Your information is used to operate the app and personalize your '
              'experience — for example, greeting you by your nickname, and '
              'tailoring career content to your program and year level. '
              'Demographic data may be analyzed in aggregate to understand how '
              'students across programs use the app.\n\n'
              'We do not sell your personal information, and we do not use it '
              'for advertising.',
        ),
        LegalSection(
          heading: 'Where your data is stored',
          body:
              'Account credentials are managed by Firebase Authentication. '
              'Profile information is stored in Google Cloud Firestore, and '
              'uploaded files (such as profile photos) are stored in Firebase '
              'Storage. These services are operated by Google and subject to '
              'their own security practices.',
        ),
        LegalSection(
          heading: 'Your choices and rights',
          body:
              'You can view and change your profile information at any time '
              'from Edit Profile. You can download a copy of the data we hold '
              'about you from Settings > Export my data.\n\n'
              'You can permanently delete your account from Settings > Delete '
              'account. Deleting your account removes your profile and sign-in '
              'credentials, and cannot be undone.',
        ),
        LegalSection(
          heading: 'Data retention',
          body:
              'We keep your information for as long as your account is active. '
              'When you delete your account, your profile data is removed from '
              'our database and your authentication record is deleted.',
        ),
        LegalSection(
          heading: 'Contact us',
          body:
              'Questions about this policy or your data can be sent to '
              'careerready.support@example.com.',
        ),
      ],
    );
  }

  factory LegalDocumentScreen.termsOfService() {
    return const LegalDocumentScreen(
      title: 'Terms of Service',
      lastUpdated: 'Last updated: September 2026',
      sections: [
        LegalSection(
          heading: 'Acceptance of terms',
          body:
              'By creating an account and using Career Ready, you agree to '
              'these terms. If you do not agree, please do not use the app.',
        ),
        LegalSection(
          heading: 'Who can use Career Ready',
          body:
              'Career Ready is intended for students preparing for entry into '
              'the workforce. You are responsible for providing accurate '
              'information during registration and for keeping your account '
              'credentials secure.',
        ),
        LegalSection(
          heading: 'Your content',
          body:
              'You retain ownership of the resumes and other materials you '
              'upload. You grant us permission to process them solely to '
              'provide the app\'s features — for example, generating resume '
              'feedback and readiness scores.\n\n'
              'Do not upload content you do not have the right to share, or '
              'that contains another person\'s private information.',
        ),
        LegalSection(
          heading: 'Guidance, not professional advice',
          body:
              'Career Ready provides automated feedback and practice tools to '
              'help you prepare. This guidance is informational and does not '
              'guarantee employment, interview success, or any particular '
              'outcome. Always use your own judgment when making career '
              'decisions.',
        ),
        LegalSection(
          heading: 'Acceptable use',
          body:
              'Do not attempt to disrupt the service, access other users\' '
              'accounts or data, reverse-engineer the app, or use it for any '
              'unlawful purpose. We may suspend accounts that violate these '
              'terms.',
        ),
        LegalSection(
          heading: 'Availability and changes',
          body:
              'Career Ready is under active development. Features may change, '
              'and the service may occasionally be unavailable. We may update '
              'these terms as the app evolves; continued use after an update '
              'means you accept the revised terms.',
        ),
        LegalSection(
          heading: 'Contact us',
          body:
              'Questions about these terms can be sent to '
              'careerready.support@example.com.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              lastUpdated,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.heading,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: AppTextStyles.body.copyWith(
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalSection {
  const LegalSection({required this.heading, required this.body});

  final String heading;
  final String body;
}
