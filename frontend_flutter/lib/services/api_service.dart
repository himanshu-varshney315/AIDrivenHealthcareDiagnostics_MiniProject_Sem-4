import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_controller.dart';
import 'auth_exceptions.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = _resolveBaseUrl();
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _analysisTimeout = Duration(seconds: 180);

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return const String.fromEnvironment(
        "API_BASE_URL",
        defaultValue: "http://127.0.0.1:5000",
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return const String.fromEnvironment(
        "API_BASE_URL",
        defaultValue: "http://10.0.2.2:5000",
      );
    }

    return const String.fromEnvironment(
      "API_BASE_URL",
      defaultValue: "http://127.0.0.1:5000",
    );
  }

  // ---------------- SIGNUP ----------------

  Future signup(String name, String email, String password) async {
    try {
      var response = await http
          .post(
            Uri.parse("$baseUrl/signup"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "password": password,
            }),
          )
          .timeout(_requestTimeout);

      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  // ---------------- LOGIN ----------------

  Future login(String email, String password) async {
    try {
      var response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(_requestTimeout);

      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  // ---------------- REPORT UPLOAD ----------------

  Future uploadReport(File file) async {
    try {
      final headers = await _authorizedHeaders();
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/upload-report"),
      );
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      var response = await request.send().timeout(_analysisTimeout);
      var responseData = await response.stream.bytesToString();

      _throwForProtectedStatus(
        response.statusCode,
        responseData,
        fromRoute: '/reports',
      );

      if (response.statusCode >= 400) {
        String message = "Request failed";
        try {
          final parsed = jsonDecode(responseData) as Map<String, dynamic>;
          message = parsed["message"]?.toString() ?? message;
        } catch (_) {}

        return {
          "message": _friendlyMessage(response.statusCode, message),
          "status_code": response.statusCode,
          "body": responseData,
        };
      }

      return jsonDecode(responseData);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _networkError("Upload timed out. Try a smaller file.");
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  Future analyzeSymptoms(String symptomsText) async {
    try {
      final headers = await _authorizedHeaders();
      var response = await http
          .post(
            Uri.parse("$baseUrl/analyze-symptoms"),
            headers: {...headers, "Content-Type": "application/json"},
            body: jsonEncode({"symptoms_text": symptomsText}),
          )
          .timeout(_analysisTimeout);

      _throwForProtectedStatus(
        response.statusCode,
        response.body,
        fromRoute: '/health-ai',
      );
      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchReportHistory({int limit = 10}) async {
    try {
      final headers = await _authorizedHeaders();
      final response = await http
          .get(
            Uri.parse("$baseUrl/reports/history?limit=$limit"),
            headers: headers,
          )
          .timeout(_requestTimeout);

      _throwForProtectedStatus(
        response.statusCode,
        response.body,
        fromRoute: '/dashboard',
      );
      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchAdminOverview({int limit = 10}) async {
    try {
      final headers = await _authorizedHeaders();
      final response = await http
          .get(
            Uri.parse("$baseUrl/reports/overview?limit=$limit"),
            headers: headers,
          )
          .timeout(_requestTimeout);

      _throwForProtectedStatus(
        response.statusCode,
        response.body,
        fromRoute: '/admin-overview',
      );
      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      return _networkError("Unexpected error: $e");
    }
  }

  Future<Map<String, dynamic>> syncWearableSummary(
    Map<String, dynamic> summary,
  ) async {
    try {
      final headers = await _authorizedHeaders();
      final response = await http
          .post(
            Uri.parse("$baseUrl/wearables/sync"),
            headers: {...headers, "Content-Type": "application/json"},
            body: jsonEncode(summary),
          )
          .timeout(_requestTimeout);

      _throwForProtectedStatus(
        response.statusCode,
        response.body,
        fromRoute: '/vitals',
      );
      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      return _networkError("Unexpected error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchWearableLatest() async {
    try {
      final headers = await _authorizedHeaders();
      final response = await http
          .get(Uri.parse("$baseUrl/wearables/latest"), headers: headers)
          .timeout(_requestTimeout);

      _throwForProtectedStatus(
        response.statusCode,
        response.body,
        fromRoute: '/vitals',
      );
      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      return _networkError("Unexpected error: $e");
    }
  }

  Future<Map<String, dynamic>> fetchWearableHistory({int days = 7}) async {
    try {
      final headers = await _authorizedHeaders();
      final response = await http
          .get(
            Uri.parse("$baseUrl/wearables/history?days=$days"),
            headers: headers,
          )
          .timeout(_requestTimeout);

      _throwForProtectedStatus(
        response.statusCode,
        response.body,
        fromRoute: '/vitals',
      );
      return _decodeResponse(response);
    } on SocketException {
      return _networkError();
    } on TimeoutException {
      return _timeoutError();
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      return _networkError("Unexpected error: $e");
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        "message": _friendlyMessage(
          response.statusCode,
          "Invalid server response",
        ),
        "status_code": response.statusCode,
      };
    }

    data["status_code"] = response.statusCode;
    data["message"] = _friendlyMessage(
      response.statusCode,
      data["message"]?.toString() ?? "",
    );
    return data;
  }

  Map<String, dynamic> _networkError([
    String message = 'Backend is unreachable. Start the backend and try again.',
  ]) {
    return {"message": message, "status_code": 0};
  }

  Map<String, dynamic> _timeoutError() {
    return _networkError(
      'The request timed out. Check that the backend is running.',
    );
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final session = await AuthService().loadSession();
    final token = session?.token.trim() ?? '';
    if (token.isEmpty) {
      throw const UnauthorizedException();
    }
    return {"Authorization": "Bearer $token"};
  }

  void _throwForProtectedStatus(
    int statusCode,
    String body, {
    required String fromRoute,
  }) {
    if (statusCode == 401) {
      unawaited(AuthController.handleUnauthorized(fromRoute: fromRoute));
      throw UnauthorizedException(
        _friendlyMessage(
          statusCode,
          _extractMessage(body, 'Authentication required.'),
        ),
      );
    }
    if (statusCode == 403) {
      throw ForbiddenException(
        _friendlyMessage(
          statusCode,
          _extractMessage(
            body,
            'You do not have permission to access this resource.',
          ),
        ),
      );
    }
  }

  String _extractMessage(String body, String fallback) {
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      return parsed['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static String _friendlyMessage(int statusCode, String message) {
    final normalized = message.trim();
    final lower = normalized.toLowerCase();
    if (statusCode == 0) {
      return normalized.isEmpty
          ? 'Backend is unreachable. Start the backend and try again.'
          : normalized;
    }
    if (statusCode == 401) {
      if (lower.contains('expired')) {
        return 'Your session expired. Please sign in again.';
      }
      if (lower.contains('invalid email') || lower.contains('password')) {
        return 'Invalid email or password. Check your details and try again.';
      }
      return 'Please sign in again to continue.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to access this page.';
    }
    if (statusCode == 400 && lower.contains('user already exists')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (statusCode == 413 || lower.contains('too large')) {
      return 'The selected file is too large. Choose a file under 10 MB.';
    }
    if (statusCode >= 500) {
      return 'The server could not complete this request. Try again shortly.';
    }
    return normalized.isEmpty
        ? 'Request failed. Please try again.'
        : normalized;
  }
}
