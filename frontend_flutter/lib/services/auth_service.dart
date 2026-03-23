import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  final String userId;
  final String userName;
  final String userEmail;
  final String token;
  final String role;

  const AuthSession({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.token,
    required this.role,
  });
}

class AuthService {
  static const _activeUserIdKey = 'active_user_id';
  static const _activeUserNameKey = 'active_user_name';
  static const _activeUserEmailKey = 'active_user_email';
  static const _activeUserTokenKey = 'active_user_token';
  static const _activeUserRoleKey = 'active_user_role';

  Future<void> persistSession({
    required String userId,
    required String userName,
    required String userEmail,
    required String token,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeUserIdKey, userId.trim());
    await prefs.setString(_activeUserNameKey, userName.trim());
    await prefs.setString(_activeUserEmailKey, userEmail.trim().toLowerCase());
    await prefs.setString(_activeUserTokenKey, token.trim());
    await prefs.setString(
      _activeUserRoleKey,
      role.trim().isEmpty ? 'user' : role.trim(),
    );
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString(_activeUserEmailKey)?.trim() ?? '';
    final token = prefs.getString(_activeUserTokenKey)?.trim() ?? '';
    if (userEmail.isEmpty) {
      return null;
    }

    return AuthSession(
      userId: prefs.getString(_activeUserIdKey)?.trim() ?? '',
      userName: prefs.getString(_activeUserNameKey)?.trim() ?? '',
      userEmail: userEmail,
      token: token,
      role: prefs.getString(_activeUserRoleKey)?.trim() ?? 'user',
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeUserIdKey);
    await prefs.remove(_activeUserNameKey);
    await prefs.remove(_activeUserEmailKey);
    await prefs.remove(_activeUserTokenKey);
    await prefs.remove(_activeUserRoleKey);
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
