import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  final String userName;
  final String userEmail;

  const AuthSession({required this.userName, required this.userEmail});
}

class AuthService {
  static const _activeUserNameKey = 'active_user_name';
  static const _activeUserEmailKey = 'active_user_email';

  Future<void> persistSession({
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeUserNameKey, userName.trim());
    await prefs.setString(_activeUserEmailKey, userEmail.trim().toLowerCase());
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString(_activeUserEmailKey)?.trim() ?? '';
    if (userEmail.isEmpty) {
      return null;
    }

    return AuthSession(
      userName: prefs.getString(_activeUserNameKey)?.trim() ?? '',
      userEmail: userEmail,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserNameKey);
    await prefs.remove(_activeUserEmailKey);
  }

  static String scopedKey(String userEmail, String baseKey) {
    final normalized = userEmail.trim().toLowerCase();
    if (normalized.isEmpty) {
      return baseKey;
    }

    final safeEmail = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return 'user_${safeEmail}_$baseKey';
  }
}
