import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

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
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
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
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'course': course,
          'yearLevel': yearLevel,
          'gender': gender,
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
}
