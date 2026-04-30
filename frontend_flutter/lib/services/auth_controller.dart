import 'package:flutter/material.dart';

import 'auth_service.dart';

class AuthController {
  AuthController._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<AuthSession?> loadSession() {
    return AuthService().loadSession();
  }

  static bool hasActiveSession(AuthSession? session) {
    return session != null &&
        session.userEmail.trim().isNotEmpty &&
        session.token.trim().isNotEmpty;
  }

  static bool isAdmin(AuthSession? session) {
    return (session?.role.trim().toLowerCase() ?? '') == 'admin';
  }

  static bool hasRole(AuthSession? session, String role) {
    return (session?.role.trim().toLowerCase() ?? '') ==
        role.trim().toLowerCase();
  }

  static Future<void> clearSession() {
    return AuthService().clearSession();
  }

  static Future<void> handleUnauthorized({String? fromRoute}) async {
    await clearSession();
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final arguments = <String, String>{
      'authMessage': 'Your session expired. Please sign in again.',
    };
    if (fromRoute != null) {
      arguments['fromRoute'] = fromRoute;
    }

    navigator.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
      arguments: arguments,
    );
  }
}
