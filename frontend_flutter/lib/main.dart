import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/find_clinics_screen.dart';
import 'screens/system_log_screen.dart';

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
        '/profile': (context) => const ProfileScreen(),
        '/find-clinics': (context) => const FindClinicsScreen(),
        '/system-log': (context) => const SystemLogScreen(),
      },

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
