import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = _resolveBaseUrl();
  static const Duration _requestTimeout = Duration(seconds: 12);

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
      return _networkError("Cannot reach backend at $baseUrl");
    } on TimeoutException {
      return _networkError("Request timed out. Backend may be down.");
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
      return _networkError("Cannot reach backend at $baseUrl");
    } on TimeoutException {
      return _networkError("Request timed out. Backend may be down.");
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  // ---------------- REPORT UPLOAD ----------------

  Future uploadReport(File file) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/upload-report"),
      );

      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      var response = await request.send().timeout(_requestTimeout);
      var responseData = await response.stream.bytesToString();

      if (response.statusCode >= 400) {
        String message = "Request failed";
        try {
          final parsed = jsonDecode(responseData) as Map<String, dynamic>;
          message = parsed["message"]?.toString() ?? message;
        } catch (_) {}

        return {
          "message": message,
          "status_code": response.statusCode,
          "body": responseData,
        };
      }

      return jsonDecode(responseData);
    } on SocketException {
      return _networkError("Cannot reach backend at $baseUrl");
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
      var response = await http
          .post(
            Uri.parse("$baseUrl/analyze-symptoms"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"symptoms_text": symptomsText}),
          )
          .timeout(_requestTimeout);

      return _decodeResponse(response);
    } on SocketException {
      return _networkError("Cannot reach backend at $baseUrl");
    } on TimeoutException {
      return _networkError("Request timed out. Backend may be down.");
    } on HttpException catch (e) {
      return _networkError(e.message);
    } catch (e) {
      return _networkError("Unexpected error: $e");
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        "message": "Invalid server response",
        "status_code": response.statusCode,
      };
    }

    data["status_code"] = response.statusCode;
    return data;
  }

  Map<String, dynamic> _networkError(String message) {
    return {"message": message, "status_code": 0};
  }
}
