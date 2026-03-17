import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class AppBottomBar extends StatefulWidget {
  final String selectedItem;

  const AppBottomBar({super.key, required this.selectedItem});

  @override
  State<AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<AppBottomBar> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(covariant AppBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem != widget.selectedItem) {
      _loadProfileImage();
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final activeEmail = session?.userEmail.trim().toLowerCase() ?? '';
    final scopedKey = AuthService.scopedKey(activeEmail, 'profile_image_path');
    final scopedImage = prefs.getString(scopedKey);
    final legacyImage = prefs.getString('profile_image_path');
    final nextImage = (scopedImage?.trim().isNotEmpty == true)
        ? scopedImage
        : legacyImage;

    if (!mounted) return;
    setState(() {
      _profileImagePath = nextImage;
    });
  }

  void _onTap(String label) {
    if (label == widget.selectedItem) {
      return;
    }

    if (label == 'Analytics') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Analytics is coming soon')));
      return;
    }

    final route = switch (label) {
      'Dashboard' => '/dashboard',
      'Health AI' => '/health-ai',
      'Clinics' => '/clinics',
      'My Profile' => '/profile',
      _ => null,
    };

    if (route == null) return;
    Navigator.pushReplacementNamed(context, route);
  }

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
                selected: widget.selectedItem == 'Dashboard',
                onTap: () => _onTap('Dashboard'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'Health AI',
                icon: Icons.android_rounded,
                customIcon: const _HealthAiNavIcon(),
                accentColor: const Color(0xFF7F74D8),
                selected: widget.selectedItem == 'Health AI',
                onTap: () => _onTap('Health AI'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'Analytics',
                icon: Icons.bar_chart_rounded,
                selected: widget.selectedItem == 'Analytics',
                onTap: () => _onTap('Analytics'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'Clinics',
                icon: Icons.add_location_alt_outlined,
                selected: widget.selectedItem == 'Clinics',
                onTap: () => _onTap('Clinics'),
              ),
            ),
            Expanded(
              child: _BottomBarItem(
                label: 'My Profile',
                icon: Icons.person_outline_rounded,
                profileImagePath: _profileImagePath,
                selected: widget.selectedItem == 'My Profile',
                onTap: () => _onTap('My Profile'),
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
  final Widget? customIcon;
  final Color accentColor;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.profileImagePath,
    this.customIcon,
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
            else if (customIcon != null)
              customIcon!
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

class _HealthAiNavIcon extends StatelessWidget {
  const _HealthAiNavIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 6,
            child: Container(
              width: 22,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF7F74D8), width: 1.6),
              ),
            ),
          ),
          const Positioned(
            top: 2,
            child: SizedBox(
              width: 2,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF7F74D8)),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            child: Icon(Icons.circle, size: 4, color: Color(0xFF7F74D8)),
          ),
          const Positioned(
            top: 12,
            left: 9,
            child: Icon(Icons.circle, size: 3.6, color: Color(0xFF7F74D8)),
          ),
          const Positioned(
            top: 12,
            right: 9,
            child: Icon(Icons.circle, size: 3.6, color: Color(0xFF7F74D8)),
          ),
          Positioned(
            top: 17,
            child: Container(
              width: 9,
              height: 4.5,
              decoration: const BoxDecoration(
                color: Color(0xFF4EB7C5),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
            ),
          ),
          const Positioned(
            right: 1,
            top: 4,
            child: Icon(Icons.auto_awesome, size: 11, color: Color(0xFF4EB7C5)),
          ),
        ],
      ),
    );
  }
}
