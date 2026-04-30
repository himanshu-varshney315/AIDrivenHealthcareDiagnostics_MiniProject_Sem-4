import 'package:flutter/material.dart';

import 'config/app_identity.dart';
import 'screens/admin_overview_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clinics_screen.dart';
import 'screens/health_ai_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/find_clinics_screen.dart';
import 'screens/system_log_screen.dart';
import 'screens/upload_report_screen.dart';
import 'services/auth_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/route_guards.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthController.navigatorKey,
      title: AppIdentity.appName,
      debugShowCheckedModeBanner: false,

      // First screen when app starts
      initialRoute: '/',

      // App routes
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const PublicOnlyRoute(child: LoginScreen()),
        '/signup': (context) => const PublicOnlyRoute(child: SignupScreen()),
        '/dashboard': (context) =>
            const ProtectedRoute(child: DashboardScreen()),
        '/clinics': (context) => const ProtectedRoute(child: ClinicsScreen()),
        '/health-ai': (context) =>
            const ProtectedRoute(child: HealthAiScreen()),
        '/profile': (context) => const ProtectedRoute(child: ProfileScreen()),
        '/find-clinics': (context) =>
            const ProtectedRoute(child: FindClinicsScreen()),
        '/system-log': (context) =>
            const ProtectedRoute(child: SystemLogScreen()),
        '/reports': (context) => const ProtectedRoute(child: ReportScreen()),
        '/admin-overview': (context) => const ProtectedRoute(
          requiredRole: 'admin',
          child: AdminOverviewScreen(),
        ),
      },

      theme: AppTheme.light,
    );
  }
}
