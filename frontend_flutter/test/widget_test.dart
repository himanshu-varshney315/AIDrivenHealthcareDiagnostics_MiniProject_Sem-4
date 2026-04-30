import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend_flutter/config/app_identity.dart';
import 'package:frontend_flutter/services/auth_controller.dart';
import 'package:frontend_flutter/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app renders splash route', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text(AppIdentity.appName), findsOneWidget);
    expect(find.text('Upload reports'), findsOneWidget);
  });

  testWidgets('splash login shortcut opens login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Sign in'), findsWidgets);
    expect(
      find.text('Continue to reports, symptom guidance, and nearby care.'),
      findsOneWidget,
    );
  });

  testWidgets('app start with no session lands on login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('app start with valid session lands on dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'active_user_email': 'admin@example.com',
      'active_user_token': 'token',
      'active_user_name': 'Admin User',
      'active_user_role': 'admin',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();

    expect(find.text('Admin User'), findsOneWidget);
  });

  testWidgets('direct protected route without session redirects to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    AuthController.navigatorKey.currentState!.pushNamed('/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('non-admin cannot open admin route', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'active_user_email': 'user@example.com',
      'active_user_token': 'token',
      'active_user_name': 'Regular User',
      'active_user_role': 'user',
    });

    await tester.pumpWidget(const MyApp());
    AuthController.navigatorKey.currentState!.pushNamed('/admin-overview');
    await tester.pumpAndSettle();

    expect(find.text('Regular User'), findsOneWidget);
    expect(
      find.text('You do not have permission to access this page.'),
      findsOneWidget,
    );
  });

  testWidgets('admin can open admin overview route', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'active_user_email': 'admin@example.com',
      'active_user_token': 'token',
      'active_user_name': 'Admin User',
      'active_user_role': 'admin',
    });

    await tester.pumpWidget(const MyApp());
    AuthController.navigatorKey.currentState!.pushNamed('/admin-overview');
    await tester.pumpAndSettle();

    expect(find.text('System overview'), findsOneWidget);
  });
}
