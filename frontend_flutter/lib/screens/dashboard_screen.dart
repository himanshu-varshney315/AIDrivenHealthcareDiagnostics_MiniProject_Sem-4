import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analysis_history_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'User Name';
  String _userEmail = '';
  Map<String, dynamic>? _latestAnalysis;
  Map<String, dynamic>? _trendSummary;
  List<Map<String, dynamic>> _analysisHistory = const [];
  bool _isInitialized = false;

  static const _profileNameKey = 'profile_name';
  static const _profileEmailKey = 'profile_email';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();

    final argUserName = (args?['userName'] as String?)?.trim() ?? '';
    final argUserEmail =
        (args?['userEmail'] as String?)?.trim().toLowerCase() ?? '';
    final activeEmail = (session?.userEmail.trim().isNotEmpty == true)
        ? session!.userEmail.trim().toLowerCase()
        : argUserEmail;
    final activeName = (session?.userName.trim().isNotEmpty == true)
        ? session!.userName.trim()
        : argUserName;
    final savedName = _readScopedValue(
      prefs: prefs,
      activeEmail: activeEmail,
      baseKey: _profileNameKey,
    );
    final savedEmail = _readScopedValue(
      prefs: prefs,
      activeEmail: activeEmail,
      baseKey: _profileEmailKey,
    );
    if (!mounted) return;
    setState(() {
      _userName = (savedName?.trim().isNotEmpty == true)
          ? savedName!.trim()
          : (activeName.isEmpty ? 'User Name' : activeName);
      _userEmail = (savedEmail?.trim().isNotEmpty == true)
          ? savedEmail!.trim()
          : activeEmail;
    });

    final latestAnalysis = await AnalysisHistoryService().loadLastAnalysis();
    final historyResponse = await ApiService().fetchReportHistory(limit: 6);
    if (!mounted) return;
    setState(() {
      _latestAnalysis = latestAnalysis;
      if ((historyResponse['status_code'] ?? 200) < 400) {
        _trendSummary =
            historyResponse['trend_summary'] as Map<String, dynamic>?;
        _analysisHistory =
            (historyResponse['history'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
        if (_latestAnalysis == null && _analysisHistory.isNotEmpty) {
          _latestAnalysis = _analysisHistory.first;
        }
      }
    });
  }

  String? _readScopedValue({
    required SharedPreferences prefs,
    required String activeEmail,
    required String baseKey,
    bool trimValue = true,
  }) {
    final scopedValue = prefs.getString(
      AuthService.scopedKey(activeEmail, baseKey),
    );
    if (scopedValue != null && (!trimValue || scopedValue.trim().isNotEmpty)) {
      return scopedValue;
    }

    final legacyValue = prefs.getString(baseKey);
    final legacyEmail =
        prefs.getString(_profileEmailKey)?.trim().toLowerCase() ?? '';
    if (legacyValue != null &&
        legacyEmail.isNotEmpty &&
        legacyEmail == activeEmail) {
      return legacyValue;
    }

    return null;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is coming soon')));
  }

  String _urgencyLabel() {
    final urgency = (_latestAnalysis?['urgency'] as String? ?? '')
        .toLowerCase();
    if (urgency.isEmpty) return 'No recent analysis';
    return '${urgency[0].toUpperCase()}${urgency.substring(1)} priority';
  }

  int _highUrgencyCount() {
    return (_trendSummary?['high_urgency_count'] as num?)?.toInt() ?? 0;
  }

  String _trendDirectionLabel() {
    final direction = (_trendSummary?['direction'] as String? ?? 'stable')
        .toLowerCase();
    switch (direction) {
      case 'improving':
        return 'Improving';
      case 'worsening':
        return 'Needs attention';
      case 'changed':
        return 'Pattern changed';
      case 'baseline':
        return 'Baseline ready';
      default:
        return 'Stable';
    }
  }

  String _currentDateLabel() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final int analysisCount = _analysisHistory.length;
    final int historyGoal = 6;
    final double averageConfidence =
        ((_trendSummary?['average_confidence'] ?? 0) as num).toDouble();
    final double historyProgress = (analysisCount / historyGoal).clamp(0, 1);
    final String confidenceLabel =
        '${(averageConfidence * 100).toStringAsFixed(1)}%';

    return Scaffold(
      backgroundColor: AppTheme.background,
      bottomNavigationBar: const AppBottomBar(selectedItem: 'Dashboard'),
      body: Stack(
        children: [
          const _DashboardBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health AI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 30),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currentDateLabel(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            onTap: () => _showComingSoon('Messages'),
                          ),
                          const SizedBox(width: 10),
                          _HeaderActionButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () => _showComingSoon('Notifications'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF7FBFE), Color(0xFFF1F7FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 24,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4F8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppTheme.aqua,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'For you',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Medical updates and quick actions',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4F8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.wb_sunny_outlined,
                                    size: 16,
                                    color: AppTheme.aqua,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Daily overview',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black.withValues(alpha: 0.68),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFE0E8EE)),
                              ),
                              child: Text(
                                '${analysisCount.toString().padLeft(2, '0')} reports tracked',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_greeting()}, $_userName',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 34,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _userEmail.isEmpty
                              ? 'How are you feeling today?'
                              : 'Signed in as $_userEmail',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/reports'),
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('View reports'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InsightChip(
                              icon: Icons.favorite_border_rounded,
                              label: 'Consistency',
                              value: 'Strong',
                            ),
                            _InsightChip(
                              icon: Icons.water_drop_outlined,
                              label: 'Hydration',
                              value: '74%',
                            ),
                            _InsightChip(
                              icon: Icons.insights_outlined,
                              label: 'Last analysis',
                              value: _urgencyLabel(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 20,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommended for you',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SuggestionCard(
                          message:
                              _trendSummary?['message']?.toString() ??
                              'Keep uploading reports over time so Health AI can compare patterns and show meaningful changes.',
                        ),
                        if (_latestAnalysis != null) ...[
                          const SizedBox(height: 18),
                          _LatestAnalysisCard(analysis: _latestAnalysis!),
                        ],
                        if (_trendSummary != null) ...[
                          const SizedBox(height: 18),
                          _TrendComparisonCard(
                            trendSummary: _trendSummary!,
                            history: _analysisHistory,
                          ),
                        ],
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 18,
                          runSpacing: 16,
                          children: [
                            _QuickAction(
                              icon: Icons.upload_file_rounded,
                              label: 'Upload report',
                              iconColor: AppTheme.blue,
                              backgroundColor: const Color(0xFFEAF3FF),
                              onTap: () => Navigator.pushNamed(context, '/reports'),
                            ),
                            _QuickAction(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Ask Health AI',
                              iconColor: AppTheme.aqua,
                              backgroundColor: const Color(0xFFEAF8F6),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/health-ai'),
                            ),
                            _QuickAction(
                              icon: Icons.monitor_heart_outlined,
                              label: 'System log',
                              iconColor: const Color(0xFF2B8F83),
                              backgroundColor: const Color(0xFFEAF7F4),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/system-log'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Your Key Stats',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = [
                              _StepsCard(
                                steps: analysisCount,
                                goal: historyGoal,
                                progress: historyProgress,
                              ),
                              _SleepCard(durationLabel: confidenceLabel),
                            ];

                            if (constraints.maxWidth < 380) {
                              return Column(
                                children: [
                                  cards[0],
                                  const SizedBox(height: 14),
                                  cards[1],
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 14),
                                Expanded(child: cards[1]),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _MiniSummaryRow(
                          trendLabel: _trendDirectionLabel(),
                          highUrgencyCount: _highUrgencyCount(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5FAFC), Color(0xFFF0F6FA), Color(0xFFEDF5F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const Positioned(
          top: -40,
          right: -10,
          child: _GlowBubble(size: 180, color: Color(0x4DCAE7E4)),
        ),
        const Positioned(
          top: 80,
          left: -30,
          child: _GlowBubble(size: 140, color: Color(0x4DAFD5F3)),
        ),
        const Positioned(
          bottom: 120,
          right: -20,
          child: _GlowBubble(size: 160, color: Color(0x33C7E4DD)),
        ),
      ],
    );
  }
}

class _GlowBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4A87D7)),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, size: 24, color: const Color(0xFF1F2430)),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String message;

  const _SuggestionCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6FBFC), Color(0xFFF8FCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medical_information_outlined,
              color: AppTheme.aqua,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health AI Suggestion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: Color(0xFF505665),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendComparisonCard extends StatelessWidget {
  final Map<String, dynamic> trendSummary;
  final List<Map<String, dynamic>> history;

  const _TrendComparisonCard({
    required this.trendSummary,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final direction = (trendSummary['direction']?.toString() ?? 'stable')
        .toLowerCase();
    final directionColor = switch (direction) {
      'improving' => const Color(0xFF2EA36D),
      'worsening' => const Color(0xFFE46E76),
      'changed' => const Color(0xFF4F84ED),
      _ => const Color(0xFFF0A247),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trend Comparison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: directionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  direction.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: directionColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            trendSummary['message']?.toString() ??
                'More reports will help compare your health trend over time.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF576070),
            ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 62,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: history
                    .take(6)
                    .toList()
                    .reversed
                    .map((entry) => Expanded(child: _TrendBar(entry: entry)))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _TrendBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    final confidence = ((entry['confidence'] ?? 0) as num).toDouble().clamp(
      0,
      1,
    );
    final urgency = (entry['urgency']?.toString() ?? 'medium').toLowerCase();
    final color = switch (urgency) {
      'high' => const Color(0xFFE46E76),
      'low' => const Color(0xFF2EA36D),
      _ => const Color(0xFFF0A247),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 22,
                height: 18 + (confidence * 40),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry['source_type']?.toString() == 'symptom' ? 'AI' : 'PDF',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF657082),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const _LatestAnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final prediction = analysis['prediction']?.toString() ?? 'Unknown';
    final confidence = ((analysis['confidence'] ?? 0) as num).toDouble();
    final urgency = (analysis['urgency']?.toString() ?? 'medium').toLowerCase();
    final precautions = (analysis['precautions'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final color = switch (urgency) {
      'high' => const Color(0xFFE46E76),
      'low' => const Color(0xFF45A979),
      _ => const Color(0xFFF0A247),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFFFF7EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Latest Report Snapshot',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  urgency.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            prediction,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence.clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFFE6EAF1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence ${(confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5E6675),
            ),
          ),
          if (precautions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              precautions.first,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF555D6A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE7EDF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  final int steps;
  final int goal;
  final double progress;

  const _StepsCard({
    required this.steps,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFE8F2FF),
                child: Icon(Icons.timeline_rounded, color: Color(0xFF5798E9)),
              ),
              SizedBox(width: 10),
              Text(
                'Analyses',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFE6E8ED),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF5E88F4),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatSteps(steps),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'records',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555A66),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: _formatSteps(steps),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' / ${_formatSteps(goal)} goal',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF707582),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).round()}% of your comparison history target',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7483)),
          ),
        ],
      ),
    );
  }

  static String _formatSteps(int value) {
    final text = value.toString();
    if (text.length <= 3) return text;
    final start = text.substring(0, text.length - 3);
    final end = text.substring(text.length - 3);
    return '$start,$end';
  }
}

class _SleepCard extends StatelessWidget {
  final String durationLabel;

  const _SleepCard({required this.durationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFBF7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFF1E8FF),
                child: Icon(Icons.analytics_outlined, color: Color(0xFF9B6AE4)),
              ),
              SizedBox(width: 10),
              Text(
                'Confidence',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(
            height: 104,
            width: double.infinity,
            child: _SleepChart(),
          ),
          const SizedBox(height: 18),
          Text(
            durationLabel,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Average confidence across recent analyses',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7483)),
          ),
        ],
      ),
    );
  }
}

class _SleepChart extends StatelessWidget {
  const _SleepChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SleepChartPainter());
  }
}

class _SleepChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0xFFE9E8EE)
      ..strokeWidth = 1;
    final purplePaint = Paint()
      ..color = const Color(0xFF8C59D5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final bluePaint = Paint()
      ..color = const Color(0xFF5AB0F1)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final bars = <double>[
      0.22,
      0.68,
      0.48,
      0.78,
      0.38,
      0.80,
      0.54,
      0.34,
      0.64,
      0.40,
      0.70,
      0.32,
    ];
    final step = size.width / (bars.length - 1);

    for (var i = 0; i < bars.length; i++) {
      final dx = i * step;
      canvas.drawLine(
        Offset(dx, size.height * 0.12),
        Offset(dx, size.height * 0.92),
        guidePaint,
      );

      final top = size.height * bars[i];
      canvas.drawLine(
        Offset(dx, top),
        Offset(dx, size.height * 0.9),
        i.isEven ? purplePaint : bluePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniSummaryRow extends StatelessWidget {
  final String trendLabel;
  final int highUrgencyCount;

  const _MiniSummaryRow({
    required this.trendLabel,
    required this.highUrgencyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.insights_outlined,
            title: 'Trend',
            subtitle: trendLabel,
            accentColor: const Color(0xFF4AA5F1),
            backgroundColor: const Color(0xFFEAF6FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.warning_amber_rounded,
            title: 'High Urgency',
            subtitle: '$highUrgencyCount recent alerts',
            accentColor: const Color(0xFFE26E7D),
            backgroundColor: const Color(0xFFFFEEF1),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;

  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
