import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend_flutter/screens/vitals_screen.dart';
import 'package:frontend_flutter/services/wearable_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'active_user_email': 'user@example.com',
      'active_user_token': 'token',
      'active_user_name': 'Vitals User',
      'active_user_role': 'user',
    });
  });

  testWidgets('vitals screen renders connect state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        service: _FakeWearableService(
          latest: const WearableSnapshot(status: WearableStatus.notConnected),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect Health Connect'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets('vitals screen renders permission denied state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        service: _FakeWearableService(
          latest: const WearableSnapshot(
            status: WearableStatus.permissionDenied,
            message: 'Health Connect permission was not granted.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permission needed'), findsOneWidget);
    expect(find.text('Health Connect permission was not granted.'), findsOneWidget);
  });

  testWidgets('vitals screen renders empty data state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        service: _FakeWearableService(
          latest: const WearableSnapshot(status: WearableStatus.noData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No wearable data yet'), findsOneWidget);
  });

  testWidgets('vitals screen renders loaded vitals state', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        service: _FakeWearableService(
          latest: const WearableSnapshot(
            status: WearableStatus.connected,
            summary: {
              'metrics': {
                'latest_heart_rate': 78,
                'average_heart_rate': 74,
                'steps': 6400,
                'sleep_minutes': 420,
                'calories': 260,
                'spo2': 98,
              },
              'risk': {
                'risk_score': 12,
                'risk_level': 'low',
                'factors': ['No major wearable risk marker detected today'],
                'recommendations': ['Keep syncing wearable data'],
              },
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wearable risk summary'), findsOneWidget);
    expect(find.text('78 bpm'), findsOneWidget);
    expect(find.text('6,400'), findsNothing);
    expect(find.text('6400'), findsOneWidget);
    expect(find.text('7h 0m'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final WearableService service;

  const _TestApp({required this.service});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: VitalsScreen(service: service));
  }
}

class _FakeWearableService extends WearableService {
  final WearableSnapshot latest;

  _FakeWearableService({required this.latest});

  @override
  Future<WearableSnapshot> loadLatestFromBackend() async => latest;

  @override
  Future<WearableSnapshot> connectAndSync() async => latest;
}
