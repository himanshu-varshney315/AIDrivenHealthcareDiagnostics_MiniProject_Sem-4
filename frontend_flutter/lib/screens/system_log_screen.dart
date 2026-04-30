import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  List<AppNotification> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService().load();
    if (!mounted) return;
    setState(() => _notifications = items);
  }

  Future<void> _clear() async {
    await NotificationService().clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      bottomNavigationBar: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            eyebrow: 'Activity',
            title: 'Notifications',
            subtitle: 'Analysis updates, alerts, and app health events.',
            trailing: AppIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.heroGradient,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _notifications.isEmpty
                        ? 'No notifications yet. Your report and AI activity will appear here.'
                        : '${_notifications.length} updates in your health timeline.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_notifications.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Clear all'),
              ),
            ),
          if (_notifications.isEmpty)
            const AppCard(
              child: Text(
                'Try uploading a report or asking Health AI a question. Status updates will land here like a care inbox.',
                style: TextStyle(color: AppTheme.textMuted, height: 1.45),
              ),
            )
          else
            ..._notifications.map((item) => _NotificationTile(item: item)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final severity = item.severity.toLowerCase();
    final color = switch (severity) {
      'critical' => AppTheme.coral,
      'warning' => AppTheme.amber,
      _ => AppTheme.aqua,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.circle_notifications_rounded, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        _time(item.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.45,
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

  String _time(DateTime date) {
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
