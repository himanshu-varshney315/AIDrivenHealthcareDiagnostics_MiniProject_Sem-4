import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';

enum WearableStatus { notConnected, permissionDenied, noData, connected, error }

class WearableSnapshot {
  final WearableStatus status;
  final Map<String, dynamic>? summary;
  final String? message;
  final List<String> diagnostics;

  const WearableSnapshot({
    required this.status,
    this.summary,
    this.message,
    this.diagnostics = const [],
  });

  bool get hasData => summary != null;

  Map<String, dynamic> get metrics =>
      Map<String, dynamic>.from(summary?['metrics'] as Map? ?? const {});

  Map<String, dynamic> get risk =>
      Map<String, dynamic>.from(summary?['risk'] as Map? ?? const {});
}

class WearableService {
  final Health _health;
  final ApiService _api;

  WearableService({Health? health, ApiService? api})
    : _health = health ?? Health(),
      _api = api ?? ApiService();

  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WALKING_HEART_RATE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.BLOOD_OXYGEN,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<WearableSnapshot> loadLatestFromBackend() async {
    final response = await _api.fetchWearableLatest();
    if ((response['status_code'] ?? 200) >= 400) {
      return WearableSnapshot(
        status: WearableStatus.error,
        message: response['message']?.toString(),
      );
    }

    final summary = response['summary'] as Map<String, dynamic>?;
    final connected = response['connected'] == true;
    if (summary != null) {
      return WearableSnapshot(
        status: WearableStatus.connected,
        summary: summary,
      );
    }
    return WearableSnapshot(
      status: connected ? WearableStatus.noData : WearableStatus.notConnected,
    );
  }

  Future<WearableSnapshot> connectAndSync() async {
    if (!_isSupportedPlatform) {
      return const WearableSnapshot(
        status: WearableStatus.permissionDenied,
        message: 'Wearable sync is available on Android with Health Connect.',
        diagnostics: ['This device is not running Android Health Connect.'],
      );
    }

    try {
      await _health.configure();
      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted && !activityStatus.isLimited) {
        return const WearableSnapshot(
          status: WearableStatus.permissionDenied,
          message: 'Activity recognition permission is needed for steps.',
          diagnostics: ['Android activity recognition permission was denied.'],
        );
      }

      final authorized = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      final grantedTypes = authorized ? _types : await _grantedTypes();
      if (grantedTypes.isEmpty) {
        return WearableSnapshot(
          status: WearableStatus.permissionDenied,
          message: 'Health Connect permission was not granted.',
          diagnostics: const [
            'Health Connect did not grant all requested read permissions.',
          ],
        );
      }

      return syncFromHealth(
        grantedTypes: grantedTypes,
        permissionDiagnostics: authorized
            ? const []
            : [
                'Health Connect granted ${grantedTypes.length} of ${_types.length} requested read permissions.',
                'Syncing the vitals that were allowed.',
              ],
      );
    } catch (error) {
      return WearableSnapshot(
        status: WearableStatus.error,
        message: 'Could not connect to Health Connect: $error',
        diagnostics: ['Health Connect setup failed before reading data.'],
      );
    }
  }

  Future<WearableSnapshot> syncFromHealth({
    List<HealthDataType>? grantedTypes,
    List<String> permissionDiagnostics = const [],
  }) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));
    final readableTypes = grantedTypes ?? _types;

    try {
      final readResult = await _readReadableData(
        readableTypes,
        startTime: weekStart,
        endTime: now,
      );
      final points = readResult.points;
      final uniquePoints = _health.removeDuplicates(points);
      final summaryResult = await _latestSummaryWithData(
        uniquePoints,
        startOfToday,
        now,
        canReadSteps: readableTypes.contains(HealthDataType.STEPS),
      );
      final summary = summaryResult.summary;
      final diagnostics = [
        ...permissionDiagnostics,
        'Requested ${readableTypes.length} readable Health Connect data types.',
        ...readResult.diagnostics,
        'Read ${points.length} total Health Connect records.',
        'Kept ${uniquePoints.length} unique records.',
        ...summaryResult.diagnostics,
      ];
      if (!_hasAnyMetric(summary['metrics'] as Map<String, dynamic>)) {
        return WearableSnapshot(
          status: WearableStatus.noData,
          diagnostics: [
            ...diagnostics,
            'No steps, heart rate, sleep, calories, or SpO2 values were returned.',
          ],
        );
      }

      final response = await _api.syncWearableSummary(summary);
      if ((response['status_code'] ?? 200) >= 400) {
        return WearableSnapshot(
          status: WearableStatus.error,
          message: response['message']?.toString(),
          diagnostics: [
            ...diagnostics,
            'Health Connect returned data, but backend sync failed.',
          ],
        );
      }

      final synced = response['summary'] as Map<String, dynamic>?;
      return WearableSnapshot(
        status: synced == null
            ? WearableStatus.noData
            : WearableStatus.connected,
        summary: synced,
        diagnostics: [
          ...diagnostics,
          synced == null
              ? 'Backend accepted the request but returned no summary.'
              : 'Synced ${summary['date']} vitals to the backend.',
        ],
      );
    } catch (error) {
      return WearableSnapshot(
        status: WearableStatus.error,
        message: 'Could not sync wearable data: $error',
        diagnostics: ['Health Connect read failed.'],
      );
    }
  }

  Future<_HealthReadResult> _readReadableData(
    List<HealthDataType> readableTypes, {
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final points = <HealthDataPoint>[];
    final diagnostics = <String>[];

    for (final type in readableTypes) {
      try {
        final typePoints = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: startTime,
          endTime: endTime,
        );
        points.addAll(typePoints);
        diagnostics.add('${_typeLabel(type)}: ${typePoints.length} records.');
      } catch (error) {
        diagnostics.add('${_typeLabel(type)}: read failed.');
      }
    }

    return _HealthReadResult(points: points, diagnostics: diagnostics);
  }

  String _typeLabel(HealthDataType type) {
    return switch (type) {
      HealthDataType.HEART_RATE => 'Heart rate',
      HealthDataType.RESTING_HEART_RATE => 'Resting heart rate',
      HealthDataType.WALKING_HEART_RATE => 'Walking heart rate',
      HealthDataType.STEPS => 'Steps records',
      HealthDataType.ACTIVE_ENERGY_BURNED => 'Active calories',
      HealthDataType.TOTAL_CALORIES_BURNED => 'Total calories',
      HealthDataType.SLEEP_ASLEEP => 'Sleep asleep',
      HealthDataType.SLEEP_LIGHT => 'Light sleep',
      HealthDataType.SLEEP_DEEP => 'Deep sleep',
      HealthDataType.SLEEP_REM => 'REM sleep',
      HealthDataType.SLEEP_SESSION => 'Sleep sessions',
      HealthDataType.BLOOD_OXYGEN => 'SpO2',
      _ => type.name,
    };
  }

  Map<String, dynamic> _summarize(
    List<HealthDataPoint> points,
    DateTime start,
    DateTime end,
  ) {
    final windowPoints = points
        .where((point) => point.dateTo.isAfter(start))
        .where((point) => point.dateFrom.isBefore(end))
        .toList();

    final heartRatePoints =
        windowPoints
            .where(
              (point) =>
                  point.type == HealthDataType.HEART_RATE ||
                  point.type == HealthDataType.RESTING_HEART_RATE ||
                  point.type == HealthDataType.WALKING_HEART_RATE,
            )
            .toList()
          ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    final heartRates = heartRatePoints
        .map(_numericValue)
        .whereType<double>()
        .toList();

    final steps = windowPoints
        .where((point) => point.type == HealthDataType.STEPS)
        .map(_numericValue)
        .whereType<double>()
        .fold<double>(0, (total, value) => total + value);
    final calories = windowPoints
        .where(
          (point) =>
              point.type == HealthDataType.ACTIVE_ENERGY_BURNED ||
              point.type == HealthDataType.TOTAL_CALORIES_BURNED,
        )
        .map(_numericValue)
        .whereType<double>()
        .fold<double>(0, (total, value) => total + value);
    final sleepPoints = windowPoints
        .where(
          (point) =>
              point.type == HealthDataType.SLEEP_ASLEEP ||
              point.type == HealthDataType.SLEEP_LIGHT ||
              point.type == HealthDataType.SLEEP_DEEP ||
              point.type == HealthDataType.SLEEP_REM,
        )
        .toList();
    final sessionSleepMinutes = windowPoints
        .where((point) => point.type == HealthDataType.SLEEP_SESSION)
        .fold<int>(
          0,
          (total, point) => total + _overlapMinutes(point, start, end),
        );
    final stagedSleepMinutes = sleepPoints.fold<int>(
      0,
      (total, point) => total + _overlapMinutes(point, start, end),
    );
    final sleepMinutes = stagedSleepMinutes > 0
        ? stagedSleepMinutes
        : sessionSleepMinutes;
    final spo2Points =
        windowPoints
            .where((point) => point.type == HealthDataType.BLOOD_OXYGEN)
            .toList()
          ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
    final spo2 = spo2Points.isEmpty
        ? null
        : _normalizeSpo2(_numericValue(spo2Points.last));

    return {
      'date': _dateOnly(start),
      'metrics': {
        'latest_heart_rate': heartRates.isEmpty
            ? null
            : heartRates.last.round(),
        'average_heart_rate': heartRates.isEmpty ? null : _average(heartRates),
        'steps': steps <= 0 ? null : steps.round(),
        'sleep_minutes': sleepMinutes <= 0 ? null : sleepMinutes,
        'calories': calories <= 0 ? null : calories.round(),
        'spo2': spo2,
      },
    };
  }

  Future<_LatestSummaryResult> _latestSummaryWithData(
    List<HealthDataPoint> points,
    DateTime startOfToday,
    DateTime now, {
    required bool canReadSteps,
  }) async {
    final diagnostics = <String>[];
    for (var dayOffset = 0; dayOffset < 7; dayOffset += 1) {
      final dayStart = startOfToday.subtract(Duration(days: dayOffset));
      final dayEnd = dayOffset == 0
          ? now
          : dayStart.add(const Duration(days: 1));
      final summary = _summarize(points, dayStart, dayEnd);
      final metrics = Map<String, dynamic>.from(summary['metrics'] as Map);
      final totalSteps = canReadSteps
          ? await _totalSteps(dayStart, dayEnd)
          : null;
      if (totalSteps != null && totalSteps > 0) {
        metrics['steps'] = totalSteps;
        summary['metrics'] = metrics;
        diagnostics.add(
          'Step total API found $totalSteps steps for ${_dateOnly(dayStart)}.',
        );
      }
      if (_hasAnyMetric(metrics)) {
        return _LatestSummaryResult(
          summary: summary,
          diagnostics: [
            ...diagnostics,
            'Found supported vitals for ${summary['date']}.',
          ],
        );
      }
    }

    return _LatestSummaryResult(
      summary: _summarize(points, startOfToday, now),
      diagnostics: [
        ...diagnostics,
        'Checked the last 7 days for supported vitals.',
      ],
    );
  }

  Future<int?> _totalSteps(DateTime start, DateTime end) async {
    try {
      return await _health.getTotalStepsInInterval(start, end);
    } catch (_) {
      return null;
    }
  }

  Future<List<HealthDataType>> _grantedTypes() async {
    final granted = <HealthDataType>[];
    for (final type in _types) {
      try {
        final hasPermission =
            await _health.hasPermissions(
              [type],
              permissions: const [HealthDataAccess.READ],
            ) ??
            false;
        if (hasPermission) granted.add(type);
      } catch (_) {
        // Some Android devices do not expose every Health Connect data type.
      }
    }
    return granted;
  }

  double? _numericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    final encoded = value.toJson();
    final raw = encoded['numeric_value'] ?? encoded['value'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  double _average(List<double> values) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return double.parse((total / values.length).toStringAsFixed(1));
  }

  double? _normalizeSpo2(double? value) {
    if (value == null) return null;
    final normalized = value <= 1 ? value * 100 : value;
    return double.parse(normalized.toStringAsFixed(1));
  }

  int _overlapMinutes(HealthDataPoint point, DateTime start, DateTime end) {
    final overlapStart = point.dateFrom.isAfter(start) ? point.dateFrom : start;
    final overlapEnd = point.dateTo.isBefore(end) ? point.dateTo : end;
    if (!overlapEnd.isAfter(overlapStart)) return 0;
    return overlapEnd.difference(overlapStart).inMinutes;
  }

  bool _hasAnyMetric(Map<String, dynamic> metrics) {
    return metrics.values.any((value) => value != null);
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}

class _HealthReadResult {
  final List<HealthDataPoint> points;
  final List<String> diagnostics;

  const _HealthReadResult({required this.points, required this.diagnostics});
}

class _LatestSummaryResult {
  final Map<String, dynamic> summary;
  final List<String> diagnostics;

  const _LatestSummaryResult({
    required this.summary,
    required this.diagnostics,
  });
}
