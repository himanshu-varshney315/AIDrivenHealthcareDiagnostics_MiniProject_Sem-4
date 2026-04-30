import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_exceptions.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _topPredictions = const [];
  List<Map<String, dynamic>> _recentAnalyses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService().fetchAdminOverview(limit: 10);
      if ((response['status_code'] ?? 200) >= 400) {
        throw Exception(response['message']?.toString() ?? 'Request failed.');
      }
      if (!mounted) return;
      setState(() {
        _summary = response['summary'] as Map<String, dynamic>?;
        _topPredictions =
            (response['top_predictions'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
        _recentAnalyses =
            (response['recent_analyses'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
      });
    } on ForbiddenException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Please sign in again to continue.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load the admin overview right now.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary ?? const <String, dynamic>{};
    final sourceBreakdown =
        summary['source_breakdown'] as Map<String, dynamic>? ??
        const <String, dynamic>{};

    return AppPage(
      bottomNavigationBar: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            eyebrow: 'Admin',
            title: 'System overview',
            subtitle:
                'Track platform activity, urgent analyses, and recent prediction patterns.',
            trailing: AppIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            AppCard(
              color: AppTheme.alertSoft,
              border: Border.all(color: AppTheme.coral.withValues(alpha: 0.2)),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppTheme.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryMetric(
                  label: 'Users',
                  value: '${summary['total_users'] ?? 0}',
                  color: AppTheme.blue,
                ),
                _SummaryMetric(
                  label: 'Analyses',
                  value: '${summary['total_analyses'] ?? 0}',
                  color: AppTheme.clinicalGreen,
                ),
                _SummaryMetric(
                  label: 'High urgency',
                  value: '${summary['high_urgency_count'] ?? 0}',
                  color: AppTheme.coral,
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Source breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricPill(
                          icon: Icons.description_rounded,
                          label: 'Reports',
                          value: '${sourceBreakdown['report'] ?? 0}',
                          color: AppTheme.aqua,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricPill(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Symptoms',
                          value: '${sourceBreakdown['symptom'] ?? 0}',
                          color: AppTheme.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top predictions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  if (_topPredictions.isEmpty)
                    const Text(
                      'No aggregated predictions yet.',
                      style: TextStyle(color: AppTheme.textMuted),
                    )
                  else
                    ..._topPredictions.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item['prediction']?.toString() ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            AppBadge(
                              text: '${item['count'] ?? 0}',
                              color: AppTheme.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Recent analyses'),
            const SizedBox(height: 12),
            if (_recentAnalyses.isEmpty)
              const AppCard(
                child: Text(
                  'No analyses have been recorded yet.',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              )
            else
              ..._recentAnalyses.map(
                (entry) => _AdminAnalysisTile(entry: entry),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: MetricPill(
        icon: Icons.analytics_rounded,
        label: label,
        value: value,
        color: color,
      ),
    );
  }
}

class _AdminAnalysisTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _AdminAnalysisTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final urgency = (entry['urgency']?.toString() ?? 'medium').toLowerCase();
    final color = switch (urgency) {
      'high' => AppTheme.coral,
      'low' => AppTheme.aqua,
      _ => AppTheme.amber,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.monitor_heart_rounded, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['prediction']?.toString() ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry['source_type'] ?? 'report'} - ${urgency.toUpperCase()}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry['explanation']?.toString() ??
                        'No explanation returned.',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
