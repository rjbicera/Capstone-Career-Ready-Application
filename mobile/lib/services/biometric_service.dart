import 'dart:io' show Platform;

import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why the biometric toggle is (or isn't) available right now.
enum BiometricStatus {
  /// Hardware present, biometrics enrolled, platform supported.
  available,

  /// local_auth has no implementation for this platform at all —
  /// Windows is the common case in this project, since the app also
  /// runs as a Flutter Windows desktop build.
  unsupportedPlatform,

  /// The device has no fingerprint/face sensor.
  noHardware,

  /// There's a sensor, but the user hasn't enrolled a fingerprint or
  /// face on this device/emulator yet.
  notEnrolled,

  /// Checking failed for some other reason. [message] has detail.
  error,
}

class BiometricCheckResult {
  const BiometricCheckResult(this.status, {this.message});
  final BiometricStatus status;
  final String? message;

  bool get isAvailable => status == BiometricStatus.available;
}

/// Fingerprint / face unlock for re-entering the app.
///
/// Important scope note: this does NOT replace Firebase authentication.
/// Firebase already keeps the user signed in between app launches, so
/// what biometrics add here is a local lock in front of that existing
/// session — the app asks for a fingerprint before revealing the
/// signed-in user's data. It cannot sign a signed-out user back in,
/// because the device has no credentials to hand Firebase.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _enabledKey = 'biometric_login_enabled';

  /// local_auth only ships Android and iOS implementations. Calling it
  /// on Windows/web/etc. previously just threw, got swallowed by a
  /// blanket try/catch, and left the toggle looking permanently
  /// "broken" with no explanation. Checking this up front avoids
  /// touching the plugin at all on a platform it doesn't support —
  /// relevant here since this project also ships a Windows desktop
  /// build target.
  static bool get _platformSupported => Platform.isAndroid || Platform.isIOS;

  /// Full diagnostic check — use this to show the RIGHT explanation in
  /// Settings instead of a single generic "not available".
  static Future<BiometricCheckResult> checkStatus() async {
    if (!_platformSupported) {
      return const BiometricCheckResult(
        BiometricStatus.unsupportedPlatform,
        message: 'Biometric login is only available on Android and iOS.',
      );
    }

    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return const BiometricCheckResult(
          BiometricStatus.noHardware,
          message: 'This device has no biometric hardware.',
        );
      }

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        return const BiometricCheckResult(
          BiometricStatus.noHardware,
          message: 'This device can\'t check biometrics right now.',
        );
      }

      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return const BiometricCheckResult(
          BiometricStatus.notEnrolled,
          message:
              'No fingerprint or face is enrolled on this device yet. '
              'Add one in your device\'s security settings first.',
        );
      }

      return const BiometricCheckResult(BiometricStatus.available);
    } catch (e) {
      return BiometricCheckResult(BiometricStatus.error, message: '$e');
    }
  }

  /// Convenience boolean for call sites that only need yes/no.
  static Future<bool> isAvailable() async =>
      (await checkStatus()).isAvailable;

  /// The user's saved opt-in. Defaults to false.
  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Shows the system biometric prompt. Returns true only on a
  /// successful scan. Used both when enabling the setting (to prove
  /// it works before saving the preference) and on app launch.
  static Future<bool> authenticate({
    String reason = 'Confirm your identity to continue',
  }) async {
    if (!_platformSupported) return false;

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Biometrics only — falling back to the device PIN would
          // weaken this to "anyone who knows the passcode", which
          // isn't what the setting promises.
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
