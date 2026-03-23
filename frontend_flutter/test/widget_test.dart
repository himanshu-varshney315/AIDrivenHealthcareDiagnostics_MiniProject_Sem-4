import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('app renders splash route', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Health AI'), findsOneWidget);
    expect(find.text('Upload reports'), findsOneWidget);
  });

  testWidgets('splash screen navigates to login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 8200));

    expect(find.text('Login'), findsWidgets);
  });
}
