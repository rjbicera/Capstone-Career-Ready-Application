import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown when the backend responds with its documented
/// { error: { code, message } } shape. The `code` matches
/// docs/api/api-contract.md exactly (e.g. EMAIL_IN_USE, WEAK_PASSWORD,
/// VALIDATION_ERROR) so callers can branch on it if needed, while
/// `message` is already human-readable for direct display.
class ApiException implements Exception {
  ApiException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($code): $message';
}

/// Thrown for anything that isn't a structured API error — no
/// connection, DNS failure, timeout, etc. Kept separate from
/// ApiException so the UI can show a distinct "check your connection"
/// message instead of a made-up error code.
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class AuthApiService {
  AuthApiService._();

  // TODO: point this at your deployed backend URL once one exists.
  //
  // For LOCAL development against `npm run dev` on your machine:
  //  - Android EMULATOR:  http://10.0.2.2:<port>  (10.0.2.2 is the
  //    emulator's special alias for the host machine's localhost —
  //    "localhost" from inside the emulator refers to the emulator
  //    itself, not your computer, which is the #1 cause of this kind
  //    of call silently timing out).
  //  - Physical PHONE on the same Wi-Fi: http://<your-computer's-LAN-IP>:<port>
  //    (e.g. http://192.168.1.23:4000) — find it via `ipconfig` on
  //    Windows (look for IPv4 Address).
  //  - iOS simulator: http://localhost:<port> works fine, unlike Android.
  static const String baseUrl = 'http://10.0.2.2:4000/api/v1';

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String course,
    required String yearLevel,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'fullName': fullName,
              'course': course,
              'yearLevel': yearLevel,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw NetworkException(
        'Couldn\'t reach the server. Check your connection or that the backend is running.',
      );
    } on http.ClientException {
      throw NetworkException('Couldn\'t reach the server.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return body;
    }

    // Matches the { error: { code, message } } shape from
    // docs/api/api-contract.md's global error format.
    final error = body['error'] as Map<String, dynamic>?;
    throw ApiException(
      error?['code'] as String? ?? 'UNKNOWN_ERROR',
      error?['message'] as String? ?? 'Something went wrong.',
    );
  }
}
