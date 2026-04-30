import 'package:flutter/material.dart';

import '../services/auth_controller.dart';
import '../services/auth_service.dart';

class ProtectedRoute extends StatefulWidget {
  final Widget child;
  final String? requiredRole;

  const ProtectedRoute({super.key, required this.child, this.requiredRole});

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  late final Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthController.loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data;
        if (!AuthController.hasActiveSession(session)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (_) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final requiredRole = widget.requiredRole;
        if (requiredRole != null &&
            !AuthController.hasRole(session, requiredRole)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final fallbackRoute = AuthController.hasActiveSession(session)
                ? '/dashboard'
                : '/login';
            Navigator.of(context).pushNamedAndRemoveUntil(
              fallbackRoute,
              (_) => false,
              arguments: {
                'accessDeniedMessage':
                    'You do not have permission to access this page.',
              },
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.child;
      },
    );
  }
}

class PublicOnlyRoute extends StatefulWidget {
  final Widget child;

  const PublicOnlyRoute({super.key, required this.child});

  @override
  State<PublicOnlyRoute> createState() => _PublicOnlyRouteState();
}

class _PublicOnlyRouteState extends State<PublicOnlyRoute> {
  late final Future<AuthSession?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthController.loadSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (AuthController.hasActiveSession(snapshot.data)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/dashboard', (_) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.child;
      },
    );
  }
}
