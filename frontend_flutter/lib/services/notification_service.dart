import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

class AppNotification {
  final String title;
  final String body;
  final String severity;
  final DateTime createdAt;

  const AppNotification({
    required this.title,
    required this.body,
    required this.severity,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'severity': severity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['title']?.toString() ?? 'Health update',
      body: json['body']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'Healthy',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationService {
  static const _notificationKey = 'health_notifications';
  static const int _maxItems = 20;

  Future<void> add({
    required String title,
    required String body,
    String severity = 'Healthy',
  }) async {
    final items = await load();
    items.insert(
      0,
      AppNotification(
        title: title,
        body: body,
        severity: severity,
        createdAt: DateTime.now(),
      ),
    );
    await _save(items.take(_maxItems).toList());
  }

  Future<List<AppNotification>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final scopedKey = AuthService.scopedKey(
      session?.userEmail ?? '',
      _notificationKey,
    );
    final raw = prefs.getString(scopedKey);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> clear() async {
    await _save([]);
  }

  Future<void> _save(List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final scopedKey = AuthService.scopedKey(
      session?.userEmail ?? '',
      _notificationKey,
    );
    await prefs.setString(
      scopedKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
