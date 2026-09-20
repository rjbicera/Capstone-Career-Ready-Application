import 'dart:convert';
import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException(this.message, {this.code, this.statusCode});

  @override
  String toString() {
    if (code != null) {
      return 'ApiException($code): $message';
    }
    return 'ApiException: $message';
  }
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthApiService {
  // ============================================================
  // CONFIGURATION
  // ============================================================

  static const String baseUrl = 'http://10.0.2.2:4000/api/v1';

  // IMPORTANT:
  // Use ONE shared GoogleSignIn instance throughout the app.
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: const ['email'],
  );

  // ============================================================
  // LOGOUT
  // ============================================================

  /// Signs the user out from both Firebase and Google.
  ///
  /// Firebase signOut() alone can leave the Google Sign-In session
  /// cached. Signing out from both allows another Google account
  /// to be selected the next time the user signs in.
  static Future<void> signOut() async {
    try {
      // First sign out from Firebase.
      await FirebaseAuth.instance.signOut();

      // Then clear the Google Sign-In session.
      await googleSignIn.signOut();
    } catch (e) {
      throw ApiException(
        'Unable to sign out. Please try again.',
        code: 'SIGN_OUT_FAILED',
      );
    }
  }

  // ============================================================
  // REGISTER WITH EMAIL AND PASSWORD
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
        }),
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  // ============================================================
  // GET CURRENT USER PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> me({required String idToken}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _securityHeaders(idToken: idToken),
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  // ============================================================
  // UPDATE DEMOGRAPHIC PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateDemographics({
    required String idToken,
    required String course,
    required String yearLevel,
    String? gender,
    String? nickname,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _securityHeaders(idToken: idToken),
        body: jsonEncode({
          'course': course,
          'yearLevel': yearLevel,
          'gender': gender,
          'nickname': nickname,
        }),
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  // ============================================================
  // UPDATE PROFILE (Edit profile screen — partial update, any time)
  // ============================================================

  /// Only non-null fields are sent, so callers can pass just the
  /// field(s) that changed. Returns the full updated profile.
  static Future<Map<String, dynamic>> updateProfile({
    required String idToken,
    String? fullName,
    String? nickname,
    String? careerGoal,
    String? course,
    String? yearLevel,
    String? gender,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (nickname != null) 'nickname': nickname,
      if (careerGoal != null) 'careerGoal': careerGoal,
      if (course != null) 'course': course,
      if (yearLevel != null) 'yearLevel': yearLevel,
      if (gender != null) 'gender': gender,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/me/profile'),
        headers: await _securityHeaders(idToken: idToken),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  // ============================================================
  // RESUME ANALYSIS
  // ============================================================

  /// Uploads one PDF resume to the backend for temporary processing and
  /// AI analysis. The original PDF is not stored permanently by Career Ready.
  static Future<Map<String, dynamic>> analyzeResume({
    required String idToken,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/resumes/analyze'),
      );

      request.headers['Authorization'] = 'Bearer $idToken';

      final appCheckToken = await FirebaseAppCheck.instance.getToken();

      if (appCheckToken != null && appCheckToken.isNotEmpty) {
        request.headers['X-Firebase-AppCheck'] = appCheckToken;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'resume',
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Unable to upload and analyze the resume.');
    }
  }
  // ============================================================
  // EXPORT MY DATA (Settings)
  // ============================================================

  /// Returns everything the backend holds on this user, ready to be
  /// written to a file and shared.
  static Future<Map<String, dynamic>> exportData({
    required String idToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me/export'),
        headers: await _securityHeaders(idToken: idToken),
      );

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  // ============================================================
  // DELETE ACCOUNT (Settings — danger zone)
  // ============================================================

  /// Deletes the Firestore profile and the Firebase Auth account.
  /// The caller must have reauthenticated the user first — Firebase
  /// rejects this for stale sessions.
  static Future<void> deleteAccount({required String idToken}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _securityHeaders(idToken: idToken),
      );

      _handleResponse(response);
    } on SocketException {
      throw NetworkException(
        'Unable to connect to the server. '
        'Make sure the backend server is running.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        // Ignore JSON parsing errors here and handle below.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'];

    String message = 'Something went wrong.';
    String? code;

    if (error is Map<String, dynamic>) {
      message = error['message']?.toString() ?? message;
      code = error['code']?.toString();
    } else if (body['message'] != null) {
      message = body['message'].toString();
    }

    throw ApiException(message, code: code, statusCode: response.statusCode);
  }

  static Future<Map<String, String>> _securityHeaders({String? idToken}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (idToken != null && idToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    final appCheckToken = await FirebaseAppCheck.instance.getToken();

    if (appCheckToken != null && appCheckToken.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken;
    }

    return headers;
  }
}
