import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('app renders splash route', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AI HealthCare'), findsOneWidget);
  });
}
