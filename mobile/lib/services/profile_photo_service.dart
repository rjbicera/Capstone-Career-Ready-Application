import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Picks a profile picture and uploads it to Firebase Storage.
///
/// The image bytes go straight from the device to Storage — the
/// Express backend never handles them. All the backend stores is the
/// resulting download URL (via PATCH /auth/me/profile), which keeps
/// the API free of multipart upload handling.
class ProfilePhotoService {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the gallery or camera and returns the chosen file, or null
  /// if the user backed out.
  static Future<File?> pickImage({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      // Resize and compress on-device before upload. A modern phone
      // camera shot is several MB; a profile avatar displayed at 80px
      // does not need that, and uploading it wastes the user's data
      // and Storage quota.
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  /// Uploads [file] to `profile_photos/{uid}.jpg` and returns its
  /// public download URL.
  ///
  /// The path is keyed by UID (not a random name) so re-uploading
  /// overwrites the previous picture instead of leaving orphaned files
  /// accumulating in the bucket.
  static Future<String> uploadPhoto(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to upload a photo.',
      );
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('${user.uid}.jpg');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return task.ref.getDownloadURL();
  }

  /// Removes the stored photo. Ignores "not found" so removing a photo
  /// the user never had doesn't surface as an error.
  static Future<void> deletePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg')
          .delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
