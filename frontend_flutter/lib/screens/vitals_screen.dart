import 'package:flutter/material.dart';

import '../config/app_identity.dart';
import '../services/wearable_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_ui.dart';

class VitalsScreen extends StatefulWidget {
  final WearableService? service;

  const VitalsScreen({super.key, this.service});

  @override
  State<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  late final WearableService _service = widget.service ?? WearableService();
  WearableSnapshot _snapshot = const WearableSnapshot(
    status: WearableStatus.notConnected,
  );
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _service.loadLatestFromBackend();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _connectAndSync() async {
    setState(() => _syncing = true);
    final snapshot = await _service.connectAndSync();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _syncing = false;
      _loading = false;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_syncStatusMessage(snapshot)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Vitals'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            eyebrow: 'Wearables',
            title: 'Vitals',
            subtitle:
                'Sync Health Connect data from your smartwatch or fitness band.',
            trailing: AppIconButton(
              icon: Icons.sync_rounded,
              onTap: _syncing ? null : _connectAndSync,
            ),
          ),
          const SizedBox(height: 22),
          if (_loading)
            const AppCard(child: Center(child: CircularProgressIndicator()))
          else
            _buildStateContent(context),
        ],
      ),
    );
  }

  Widget _buildStateContent(BuildContext context) {
    return switch (_snapshot.status) {
      WearableStatus.notConnected => _StateCard(
        icon: Icons.watch_rounded,
        title: 'Connect Health Connect',
        message:
            'Link Health Connect to read heart rate, steps, sleep, calories, and oxygen saturation from synced devices.',
        diagnostics: _snapshot.diagnostics,
        buttonLabel: 'Connect',
        loading: _syncing,
        onPressed: _connectAndSync,
      ),
      WearableStatus.permissionDenied => _StateCard(
        icon: Icons.lock_rounded,
        title: 'Permission needed',
        message:
            _snapshot.message ??
            'Grant Health Connect permissions so ${AppIdentity.appName} can show wearable vitals.',
        diagnostics: _snapshot.diagnostics,
        buttonLabel: 'Try again',
        loading: _syncing,
        onPressed: _connectAndSync,
      ),
      WearableStatus.noData => _StateCard(
        icon: Icons.hourglass_empty_rounded,
        title: 'No wearable data yet',
        message:
            _snapshot.message ??
            'Health Connect is reachable, but no supported vitals were found in the last 7 days.',
        diagnostics: _snapshot.diagnostics,
        buttonLabel: 'Sync again',
        loading: _syncing,
        onPressed: _connectAndSync,
      ),
      WearableStatus.error => _StateCard(
        icon: Icons.error_outline_rounded,
        title: 'Vitals unavailable',
        message:
            _snapshot.message ??
            'The app could not load wearable data. Check Health Connect and the backend.',
        diagnostics: _snapshot.diagnostics,
        buttonLabel: 'Retry',
        loading: _syncing,
        onPressed: _connectAndSync,
      ),
      WearableStatus.connected => _VitalsContent(
        snapshot: _snapshot,
        syncing: _syncing,
        onSync: _connectAndSync,
      ),
    };
  }

  String _syncStatusMessage(WearableSnapshot snapshot) {
    return switch (snapshot.status) {
      WearableStatus.connected => 'Vitals synced successfully.',
      WearableStatus.noData =>
        'Sync finished, but Health Connect returned no supported vitals.',
      WearableStatus.permissionDenied =>
        'Health Connect permission is still needed.',
      WearableStatus.notConnected => 'Health Connect is not connected yet.',
      WearableStatus.error => snapshot.message ?? 'Vitals sync failed.',
    };
  }
}

class _VitalsContent extends StatelessWidget {
  final WearableSnapshot snapshot;
  final bool syncing;
  final VoidCallback onSync;

  const _VitalsContent({
    required this.snapshot,
    required this.syncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = snapshot.metrics;
    final risk = snapshot.risk;
    final riskLevel = risk['risk_level']?.toString() ?? 'low';
    final riskScore = risk['risk_score']?.toString() ?? '0';
    final riskColor = switch (riskLevel) {
      'high' => AppTheme.coral,
      'moderate' => AppTheme.amber,
      _ => AppTheme.clinicalGreen,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy, riskColor],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppBadge(
                    text: riskLevel.toUpperCase(),
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                  const Spacer(),
                  Text(
                    'Risk $riskScore/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Wearable risk summary',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _firstText(
                  risk['factors'],
                  'No major wearable risk marker detected today',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: syncing ? null : onSync,
                icon: syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: Text(syncing ? 'Syncing' : 'Sync now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.navy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle(title: 'Today'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _VitalCard(
                icon: Icons.favorite_rounded,
                label: 'Heart rate',
                value: _formatNumber(
                  metrics['latest_heart_rate'],
                  suffix: ' bpm',
                ),
                subvalue:
                    'Avg ${_formatNumber(metrics['average_heart_rate'], suffix: ' bpm')}',
                color: AppTheme.coral,
              ),
              _VitalCard(
                icon: Icons.directions_walk_rounded,
                label: 'Steps',
                value: _formatNumber(metrics['steps']),
                subvalue: 'Today',
                color: AppTheme.blue,
              ),
              _VitalCard(
                icon: Icons.bedtime_rounded,
                label: 'Sleep',
                value: _formatSleep(metrics['sleep_minutes']),
                subvalue: 'Last session total',
                color: AppTheme.violet,
              ),
              _VitalCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories',
                value: _formatNumber(metrics['calories'], suffix: ' kcal'),
                subvalue: 'Active energy',
                color: AppTheme.amber,
              ),
              _VitalCard(
                icon: Icons.air_rounded,
                label: 'SpO2',
                value: _formatNumber(metrics['spo2'], suffix: '%'),
                subvalue: 'Latest reading',
                color: AppTheme.aqua,
              ),
            ];
            final crossAxisCount = constraints.maxWidth > 760 ? 3 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: constraints.maxWidth > 760 ? 2.1 : 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: cards,
            );
          },
        ),
        const SizedBox(height: 22),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next step', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _firstText(
                  risk['recommendations'],
                  'Keep syncing wearable data to build a more useful trend.',
                ),
                style: const TextStyle(color: AppTheme.textMuted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _firstText(dynamic items, String fallback) {
    if (items is List && items.isNotEmpty) {
      return items.first.toString();
    }
    return fallback;
  }

  static String _formatNumber(dynamic value, {String suffix = ''}) {
    if (value == null) return '--';
    if (value is num) {
      final formatted = value % 1 == 0
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
      return '$formatted$suffix';
    }
    return '$value$suffix';
  }

  static String _formatSleep(dynamic value) {
    if (value is! num || value <= 0) return '--';
    final hours = value ~/ 60;
    final minutes = (value % 60).round();
    return '${hours}h ${minutes}m';
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subvalue;
  final Color color;

  const _VitalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subvalue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            subvalue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final List<String> diagnostics;
  final String buttonLabel;
  final bool loading;
  final VoidCallback onPressed;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.diagnostics = const [],
    required this.buttonLabel,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.scrub,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.clinicalGreen),
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.45),
          ),
          if (diagnostics.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sync details',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...diagnostics.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.35,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: loading ? null : onPressed,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.watch_rounded),
            label: Text(loading ? 'Connecting' : buttonLabel),
          ),
        ],
      ),
    );
  }
}
