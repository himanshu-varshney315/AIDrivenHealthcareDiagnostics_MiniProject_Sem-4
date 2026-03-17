import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../widgets/app_bottom_bar.dart';
import 'upload_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'User Name';
  String _userEmail = '';
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

  @override
  Widget build(BuildContext context) {
    const int steps = 8450;
    const int goal = 10000;
    const String sleepDuration = '7h 15m';
    const double hydrationProgress = 0.74;
    final double stepProgress = (steps / goal).clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
                      const Expanded(
                        child: Text(
                          'Health Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderActionButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            onTap: () => _showComingSoon('Messages'),
                          ),
                          const SizedBox(width: 12),
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
                        colors: [Color(0xFFF5FBFF), Color(0xFFF7F1FF)],
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F6FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wb_sunny_outlined,
                                size: 16,
                                color: Color(0xFF468AD8),
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
                        const SizedBox(height: 18),
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_greeting()},\n$_userName!',
                          style: const TextStyle(
                            fontSize: 40,
                            height: 1.03,
                            fontWeight: FontWeight.w800,
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
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
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
                        const _SuggestionCard(),
                        const SizedBox(height: 22),
                        Wrap(
                          spacing: 18,
                          runSpacing: 16,
                          children: [
                            _QuickAction(
                              icon: Icons.upload_file_rounded,
                              label: 'Upload\nReport',
                              iconColor: const Color(0xFFF0A247),
                              backgroundColor: const Color(0xFFFFEEDA),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportScreen(),
                                ),
                              ),
                            ),
                            _QuickAction(
                              icon: Icons.monitor_heart_outlined,
                              label: 'System\nLog',
                              iconColor: const Color(0xFFE77992),
                              backgroundColor: const Color(0xFFFFE8EF),
                              onTap: () => _showComingSoon('System Log'),
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
                                steps: steps,
                                goal: goal,
                                progress: stepProgress,
                              ),
                              const _SleepCard(durationLabel: sleepDuration),
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
                        const _MiniSummaryRow(
                          hydrationProgress: hydrationProgress,
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
              colors: [Color(0xFFEAF6FF), Color(0xFFF6F0FF), Color(0xFFF8FAFD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const Positioned(
          top: -40,
          right: -10,
          child: _GlowBubble(size: 180, color: Color(0x80D9D2FF)),
        ),
        const Positioned(
          top: 80,
          left: -30,
          child: _GlowBubble(size: 140, color: Color(0x8097E2FF)),
        ),
        const Positioned(
          bottom: 120,
          right: -20,
          child: _GlowBubble(size: 160, color: Color(0x80FFE4C7)),
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
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 62,
          height: 62,
          child: Icon(icon, size: 28, color: const Color(0xFF1F2430)),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F5FA), Color(0xFFF9FBFF)],
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
              color: const Color(0xFFEDEAF9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFF8270D8),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health AI Suggestion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Your sleep pattern is improving. Try to maintain the same bedtime tonight for better recovery and focus tomorrow.',
                  style: TextStyle(
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
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.15,
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
                child: Icon(
                  Icons.directions_walk_rounded,
                  color: Color(0xFF5798E9),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Steps',
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
                        'steps',
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
            '${(progress * 100).round()}% of today\'s movement target',
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
                child: Icon(Icons.nightlight_round, color: Color(0xFF9B6AE4)),
              ),
              SizedBox(width: 10),
              Text(
                'Sleep',
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
            'Steady rest rhythm through the night',
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
  final double hydrationProgress;

  const _MiniSummaryRow({required this.hydrationProgress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.water_drop_outlined,
            title: 'Hydration',
            subtitle: '${(hydrationProgress * 100).round()}% complete',
            accentColor: const Color(0xFF4AA5F1),
            backgroundColor: const Color(0xFFEAF6FF),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MiniStatCard(
            icon: Icons.favorite_outline_rounded,
            title: 'Recovery',
            subtitle: 'Resting strong today',
            accentColor: Color(0xFFE26E7D),
            backgroundColor: Color(0xFFFFEEF1),
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
