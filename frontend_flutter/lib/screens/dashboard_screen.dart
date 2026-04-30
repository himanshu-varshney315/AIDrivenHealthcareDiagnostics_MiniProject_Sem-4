import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analysis_history_service.dart';
import '../services/api_service.dart';
import '../services/auth_controller.dart';
import '../services/auth_exceptions.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'User';
  String _userEmail = '';
  Map<String, dynamic>? _latestAnalysis;
  Map<String, dynamic>? _trendSummary;
  Map<String, dynamic>? _wearableSummary;
  List<Map<String, dynamic>> _history = const [];
  int _notificationCount = 0;
  int _profileCompletion = 0;
  bool _loaded = false;
  bool _isAdmin = false;
  String? _bannerMessage;

  static const _profileNameKey = 'profile_name';
  static const _profileEmailKey = 'profile_email';
  static const _profilePhoneKey = 'profile_phone';
  static const _profileAgeKey = 'profile_age';
  static const _profileBloodKey = 'profile_blood_group';
  static const _profileEmergencyKey = 'profile_emergency';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final activeEmail =
        session?.userEmail.trim().toLowerCase() ??
        (args?['userEmail'] as String? ?? '').trim().toLowerCase();
    final activeName =
        session?.userName.trim() ?? (args?['userName'] as String? ?? '').trim();
    final accessDeniedMessage =
        args?['accessDeniedMessage']?.toString().trim() ?? '';

    final savedName = prefs.getString(
      AuthService.scopedKey(activeEmail, _profileNameKey),
    );
    final savedEmail = prefs.getString(
      AuthService.scopedKey(activeEmail, _profileEmailKey),
    );
    final profileFields = [
      savedName,
      savedEmail,
      prefs.getString(AuthService.scopedKey(activeEmail, _profilePhoneKey)),
      prefs.getString(AuthService.scopedKey(activeEmail, _profileAgeKey)),
      prefs.getString(AuthService.scopedKey(activeEmail, _profileBloodKey)),
      prefs.getString(AuthService.scopedKey(activeEmail, _profileEmergencyKey)),
    ];
    final latest = await AnalysisHistoryService().loadLastAnalysis();
    final notifications = await NotificationService().load();
    Map<String, dynamic> historyResponse = const {};
    try {
      historyResponse = await ApiService().fetchReportHistory(limit: 6);
    } on AuthException {
      historyResponse = const {};
    }
    Map<String, dynamic> wearableResponse = const {};
    try {
      wearableResponse = await ApiService().fetchWearableLatest();
    } on AuthException {
      wearableResponse = const {};
    }

    if (!mounted) return;
    setState(() {
      _isAdmin = AuthController.isAdmin(session);
      _userName = (savedName?.trim().isNotEmpty == true)
          ? savedName!.trim()
          : (activeName.isEmpty ? 'User' : activeName);
      _userEmail = (savedEmail?.trim().isNotEmpty == true)
          ? savedEmail!.trim()
          : activeEmail;
      _latestAnalysis = latest;
      _notificationCount = notifications.length;
      _bannerMessage = accessDeniedMessage.isEmpty ? null : accessDeniedMessage;
      _profileCompletion =
          ((profileFields
                          .where((item) => item?.trim().isNotEmpty == true)
                          .length /
                      profileFields.length) *
                  100)
              .round();
      if ((historyResponse['status_code'] ?? 200) < 400) {
        _trendSummary =
            historyResponse['trend_summary'] as Map<String, dynamic>?;
        _history = (historyResponse['history'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _latestAnalysis ??= _history.isNotEmpty ? _history.first : null;
      }
      if ((wearableResponse['status_code'] ?? 200) < 400) {
        _wearableSummary = wearableResponse['summary'] as Map<String, dynamic>?;
      }
    });
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, '/profile');
    if (!mounted) return;
    await _load();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final confidence = ((_latestAnalysis?['confidence'] ?? 0) as num)
        .toDouble();
    final prediction =
        _latestAnalysis?['prediction']?.toString() ?? 'No recent review yet';
    final urgency = (_latestAnalysis?['urgency']?.toString() ?? 'ready')
        .toLowerCase();
    final trend = _trendSummary?['direction']?.toString() ?? 'Stable';
    final message =
        _trendSummary?['message']?.toString() ??
        'Upload a report or describe symptoms to keep your care story current.';

    return AppPage(
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Dashboard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            eyebrow: _greeting,
            title: _userName,
            subtitle: _userEmail.isEmpty
                ? 'Your care overview is ready.'
                : 'Signed in as $_userEmail',
            trailing: AppIconButton(
              icon: Icons.notifications_rounded,
              badgeCount: _notificationCount,
              onTap: () => Navigator.pushNamed(context, '/system-log'),
            ),
          ),
          const SizedBox(height: 22),
          if (_bannerMessage != null) ...[
            AppCard(
              color: AppTheme.alertSoft,
              border: Border.all(color: AppTheme.coral.withValues(alpha: 0.2)),
              child: Text(
                _bannerMessage!,
                style: const TextStyle(
                  color: AppTheme.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          AppCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.heroGradient,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBadge(
                      text: _labelForUrgency(urgency),
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                    ),
                    const Spacer(),
                    Text(
                      'Confidence ${(confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Today\'s care summary',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prediction,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: confidence.clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/reports'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.navy,
                        ),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Upload report'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/health-ai'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.26),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Ask Health AI'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Quick actions'),
          const SizedBox(height: 12),
          SizedBox(
            height: 122,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StoryChip(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Sync Vitals',
                  color: AppTheme.coral,
                  onTap: () => Navigator.pushNamed(context, '/vitals'),
                ),
                const SizedBox(width: 12),
                StoryChip(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload report',
                  color: AppTheme.clinicalGreen,
                  onTap: () => Navigator.pushNamed(context, '/reports'),
                ),
                const SizedBox(width: 12),
                StoryChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Describe symptoms',
                  color: AppTheme.blue,
                  onTap: () => Navigator.pushNamed(context, '/health-ai'),
                ),
                const SizedBox(width: 12),
                StoryChip(
                  icon: Icons.local_hospital_rounded,
                  label: 'Find nearby care',
                  color: AppTheme.aqua,
                  onTap: () => Navigator.pushNamed(context, '/clinics'),
                ),
                if (_profileCompletion < 100) ...[
                  const SizedBox(width: 12),
                  StoryChip(
                    icon: Icons.person_rounded,
                    label: 'Complete profile',
                    color: AppTheme.violet,
                    onTap: _openProfile,
                  ),
                ],
                if (_isAdmin) ...[
                  const SizedBox(width: 12),
                  StoryChip(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin overview',
                    color: AppTheme.coral,
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin-overview'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Today at a glance'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wearableMetrics = Map<String, dynamic>.from(
                _wearableSummary?['metrics'] as Map? ?? const {},
              );
              final wearableRisk = Map<String, dynamic>.from(
                _wearableSummary?['risk'] as Map? ?? const {},
              );
              final latestHeartRate = wearableMetrics['latest_heart_rate'];
              final cards = [
                MetricPill(
                  icon: Icons.timeline_rounded,
                  label: 'Trend',
                  value: trend,
                  color: AppTheme.blue,
                ),
                MetricPill(
                  icon: Icons.folder_open_rounded,
                  label: 'Records',
                  value: '${_history.length}',
                  color: AppTheme.aqua,
                ),
                MetricPill(
                  icon: Icons.notifications_active_rounded,
                  label: 'Alerts',
                  value: '$_notificationCount',
                  color: AppTheme.amber,
                ),
                if (_wearableSummary != null)
                  MetricPill(
                    icon: Icons.monitor_heart_rounded,
                    label: latestHeartRate == null
                        ? 'Vitals risk'
                        : 'Heart rate',
                    value: latestHeartRate == null
                        ? (wearableRisk['risk_level']?.toString() ?? 'Ready')
                        : '${(latestHeartRate as num).round()} bpm',
                    color: AppTheme.coral,
                  ),
              ];
              return GridView.count(
                crossAxisCount: constraints.maxWidth > 700 ? cards.length : 2,
                childAspectRatio: constraints.maxWidth > 700 ? 2.3 : 1.9,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: cards,
              );
            },
          ),
          const SizedBox(height: 22),
          if (_profileCompletion < 100) ...[
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundRaised,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: AppTheme.clinicalGreen,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finish your care profile',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You are $_profileCompletion% complete. Add medical details and an emergency contact so follow-up is simpler.',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (_profileCompletion / 100)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: AppTheme.backgroundRaised,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.clinicalGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: _openProfile,
                    child: const Text('Finish'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
          SectionTitle(
            title: 'Recent activity',
            action: 'View log',
            onAction: () => Navigator.pushNamed(context, '/system-log'),
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            const AppCard(
              child: Text(
                'Your first report or symptom review will appear here with urgency, confidence, and next-step guidance.',
                style: TextStyle(color: AppTheme.textMuted, height: 1.45),
              ),
            )
          else
            ..._history.take(3).map((entry) => _ActivityTile(entry: entry)),
        ],
      ),
    );
  }

  String _labelForUrgency(String urgency) {
    return switch (urgency) {
      'high' => 'High priority',
      'low' => 'Low urgency',
      'ready' => 'Ready for review',
      _ => 'Watch closely',
    };
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _ActivityTile({required this.entry});

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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.monitor_heart_rounded, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['prediction']?.toString() ?? 'Analysis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
