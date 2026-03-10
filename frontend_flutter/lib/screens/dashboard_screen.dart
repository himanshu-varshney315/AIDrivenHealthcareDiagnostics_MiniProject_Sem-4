import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'upload_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = 'User Name';
  String _userEmail = '';
  String? _profileImagePath;
  bool _isInitialized = false;

  static const _profileImagePathKey = 'profile_image_path';
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

    final argUserName = (args?['userName'] as String?)?.trim();
    final argUserEmail = (args?['userEmail'] as String?)?.trim();

    if (!mounted) return;
    setState(() {
      _userName = (prefs.getString(_profileNameKey)?.trim().isNotEmpty == true)
          ? prefs.getString(_profileNameKey)!.trim()
          : ((argUserName == null || argUserName.isEmpty)
                ? 'User Name'
                : argUserName);
      _userEmail =
          (prefs.getString(_profileEmailKey)?.trim().isNotEmpty == true)
          ? prefs.getString(_profileEmailKey)!.trim()
          : (argUserEmail ?? '');
      _profileImagePath = prefs.getString(_profileImagePathKey);
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userName': _userName, 'userEmail': _userEmail},
    );
    await _loadDashboardData();
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
    final double stepProgress = (steps / goal).clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      bottomNavigationBar: _DashboardBottomBar(
        profileImagePath: _profileImagePath,
        onProfileTap: _openProfile,
        onItemTap: _showComingSoon,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE7F3FF), Color(0xFFF4EDFF), Color(0xFFF8F9FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
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
                    _HeaderActionButton(
                      icon: Icons.share_outlined,
                      onTap: () => _showComingSoon('Share'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_greeting()},\n$_userName!',
                  style: const TextStyle(
                    fontSize: 46,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'How are you today?',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 24,
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
                        spacing: 26,
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
                            iconColor: const Color(0xFFE88A99),
                            backgroundColor: const Color(0xFFFFE8EE),
                            onTap: () => _showComingSoon('System Log'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Your Key Stats',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _StepsCard(
                              steps: steps,
                              goal: goal,
                              progress: stepProgress,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: _SleepCard(durationLabel: sleepDuration),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      color: Colors.white.withValues(alpha: 0.72),
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
        color: const Color(0xFFF6F3F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: Color(0xFF9BA0AE), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health AI Suggestion:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Your sleep pattern is improving. Try to maintain the same bedtime tonight for optimal recovery.',
                  style: TextStyle(fontSize: 16, height: 1.22),
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
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: backgroundColor,
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.08,
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
        color: Colors.white,
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
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
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
                          fontSize: 20,
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
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: _formatSteps(steps),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' / ${_formatSteps(goal)}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF707582),
                  ),
                ),
              ],
            ),
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
        color: Colors.white,
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
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(
            height: 100,
            width: double.infinity,
            child: _SleepChart(),
          ),
          const SizedBox(height: 12),
          Text(
            durationLabel,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
      ..color = const Color(0xFFE5E6EB)
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
      0.20,
      0.62,
      0.44,
      0.71,
      0.35,
      0.82,
      0.49,
      0.28,
      0.58,
      0.33,
      0.66,
      0.30,
    ];
    final step = size.width / (bars.length - 1);

    for (var i = 0; i < bars.length; i++) {
      final dx = i * step;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), guidePaint);

      final top = size.height * bars[i];
      canvas.drawLine(
        Offset(dx, top),
        Offset(dx, size.height * 0.94),
        i.isEven ? purplePaint : bluePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardBottomBar extends StatelessWidget {
  final String? profileImagePath;
  final VoidCallback onProfileTap;
  final ValueChanged<String> onItemTap;

  const _DashboardBottomBar({
    required this.profileImagePath,
    required this.onProfileTap,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _BottomBarItem(
                label: 'Dashboard',
                icon: Icons.home_outlined,
                selected: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'Health AI',
                icon: Icons.smart_toy_outlined,
                accentColor: const Color(0xFF7F74D8),
                onTap: () => onItemTap('Health AI'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'Analytics',
                icon: Icons.bar_chart_rounded,
                onTap: () => onItemTap('Analytics'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'Clinics',
                icon: Icons.add_location_alt_outlined,
                onTap: () => onItemTap('Clinics'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'My Profile',
                icon: Icons.person_outline_rounded,
                profileImagePath: profileImagePath,
                onTap: onProfileTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final String? profileImagePath;
  final Color accentColor;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.profileImagePath,
    this.accentColor = const Color(0xFF646A76),
  });

  @override
  Widget build(BuildContext context) {
    final hasProfileImage =
        profileImagePath != null && File(profileImagePath!).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            if (hasProfileImage)
              CircleAvatar(
                radius: 18,
                backgroundImage: FileImage(File(profileImagePath!)),
              )
            else
              Icon(
                icon,
                color: selected ? Colors.black : accentColor,
                size: 28,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.black : const Color(0xFF3F4450),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
