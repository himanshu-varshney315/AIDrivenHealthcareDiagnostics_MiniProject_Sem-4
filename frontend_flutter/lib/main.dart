import 'package:flutter/material.dart';

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
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Healthcare App',
      debugShowCheckedModeBanner: false,

      // First screen when app starts
      initialRoute: '/',

      // App routes
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/clinics': (context) => const ClinicsScreen(),
        '/health-ai': (context) => const HealthAiScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/find-clinics': (context) => const FindClinicsScreen(),
        '/system-log': (context) => const SystemLogScreen(),
        '/reports': (context) => const ReportScreen(),
      },

      theme: AppTheme.light,
    );
  }
}
