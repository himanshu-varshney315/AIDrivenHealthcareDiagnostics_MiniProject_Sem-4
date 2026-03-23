import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class AnalysisHistoryService {
  static const _lastAnalysisKey = 'last_analysis';

  Future<void> saveLastAnalysis(Map<String, dynamic> analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final scopedKey = AuthService.scopedKey(
      session?.userEmail ?? '',
      _lastAnalysisKey,
    );
    await prefs.setString(scopedKey, jsonEncode(analysis));
  }

  Future<Map<String, dynamic>?> loadLastAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final scopedKey = AuthService.scopedKey(
      session?.userEmail ?? '',
      _lastAnalysisKey,
    );
    final raw = prefs.getString(scopedKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }
}
