import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'find_clinics_screen.dart';
import 'system_log_screen.dart';
import 'upload_report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "User Name";
  String _userEmail = "";
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();

    final argUserName = (args?['userName'] as String?)?.trim();
    final argUserEmail = (args?['userEmail'] as String?)?.trim();
    final savedUserName = prefs.getString(_profileNameKey)?.trim();
    final savedUserEmail = prefs.getString(_profileEmailKey)?.trim();
    final hasRouteUser = argUserEmail != null && argUserEmail.isNotEmpty;
    final resolvedUserName = hasRouteUser
        ? ((argUserName == null || argUserName.isEmpty) ? "User Name" : argUserName)
        : ((savedUserName != null && savedUserName.isNotEmpty) ? savedUserName : "User Name");
    final resolvedUserEmail = hasRouteUser
        ? argUserEmail
        : ((savedUserEmail != null && savedUserEmail.isNotEmpty) ? savedUserEmail : "");

    if (!mounted) return;
    setState(() {
      _userName = resolvedUserName;
      _userEmail = resolvedUserEmail;
      _profileImagePath = prefs.getString(_profileImagePathKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    const double steps = 6450;
    const double goal = 10000;
    final double stepProgress = (steps / goal).clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopHeader(
              userName: _userName,
              profileImagePath: _profileImagePath,
              onLogout: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 22),
                  const Text(
                    "Health At a Glance",
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActionItem(
                        icon: Icons.upload_file_rounded,
                        label: "Upload\nReport",
                        iconColor: const Color(0xFFF0A247),
                        bgColor: const Color(0xFFFFEEDA),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReportScreen()),
                        ),
                      ),
                      _ActionItem(
                        icon: Icons.monitor_heart_outlined,
                        label: "System\nLog",
                        iconColor: const Color(0xFFE87079),
                        bgColor: const Color(0xFFFFE7EA),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SystemLogScreen()),
                        ),
                      ),
                      _ActionItem(
                        icon: Icons.add,
                        label: "Find\nClinics",
                        iconColor: const Color(0xFF2BC57B),
                        bgColor: const Color(0xFFE0F8EC),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FindClinicsScreen()),
                        ),
                      ),
                      _ActionItem(
                        icon: Icons.person,
                        label: "My\nProfile",
                        iconColor: const Color(0xFFAF5BE9),
                        bgColor: const Color(0xFFF2E8FB),
                        profileImagePath: _profileImagePath,
                        onTap: () async {
                          await Navigator.pushNamed(
                          context,
                          '/profile',
                          arguments: {
                            'userName': _userName,
                            'userEmail': _userEmail,
                          },
                        );
                          await _loadDashboardData();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    "Your Stats",
                    style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StepsCard(
                          steps: steps.toInt(),
                          goal: goal.toInt(),
                          progress: stepProgress,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: _SleepCard(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _HydrationCard(value: 0.74),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String userName;
  final String? profileImagePath;
  final VoidCallback onLogout;

  const _TopHeader({
    required this.userName,
    required this.profileImagePath,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 58, 24, 42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFA1DFF6), Color(0xFF94B8FF), Color(0xFFC9B2F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(120),
          bottomRight: Radius.circular(120),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Health Dashboard",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: "Logout",
                  onPressed: onLogout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text("Welcome back,", style: TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            "Good morning,\n$userName!",
            style: const TextStyle(fontSize: 52, height: 1.05, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text("How are you today?", style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final String? profileImagePath;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    this.profileImagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfileImage = profileImagePath != null && File(profileImagePath!).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: bgColor,
              backgroundImage: hasProfileImage ? FileImage(File(profileImagePath!)) : null,
              child: hasProfileImage ? null : Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.15),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 14, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFE0F4E8),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF39C978)),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_walk, color: Color(0xFF39C978), size: 28),
                    const SizedBox(height: 4),
                    Text("$steps", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700)),
                    const Text("steps", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text("Step/$goal", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 14, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFF0E4FF),
                child: Icon(Icons.nightlight_round, color: Color(0xFF8E5DD7), size: 26),
              ),
              SizedBox(width: 10),
              Text("Sleep", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 72, width: double.infinity, child: _SleepWave()),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("00 am", style: TextStyle(fontSize: 18)),
              Text("01 am", style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepWave extends StatelessWidget {
  const _SleepWave();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SleepWavePainter(),
    );
  }
}

class _SleepWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF8E5DD7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.92,
        size.width * 0.42,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.14,
        size.width * 0.82,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.72,
        size.width,
        size.height * 0.45,
      );

    canvas.drawPath(path, linePaint);
    final bars = <double>[0.78, 0.92, 0.55, 0.94, 0.42, 0.96, 0.50];
    final dxStep = size.width / (bars.length - 1);

    for (var i = 0; i < bars.length; i++) {
      final x = i * dxStep;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * bars[i]),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HydrationCard extends StatelessWidget {
  final double value;

  const _HydrationCard({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 14, offset: Offset(0, 7)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFDEF4FF),
            child: Icon(Icons.water_drop_rounded, color: Color(0xFF5EC9E7), size: 34),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hydration Level",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 14,
                    value: value,
                    color: const Color(0xFF80D6EE),
                    backgroundColor: const Color(0xFFCDEFFD),
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
