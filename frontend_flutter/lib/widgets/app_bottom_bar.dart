import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppBottomBar extends StatefulWidget {
  final String selectedItem;

  const AppBottomBar({super.key, required this.selectedItem});

  @override
  State<AppBottomBar> createState() => _AppBottomBarState();
}

class _AppBottomBarState extends State<AppBottomBar> {
  String? _profileImagePath;

  static const _items = [
    _NavItem('Dashboard', 'Home', Icons.home_rounded, '/dashboard'),
    _NavItem('Health AI', 'AI', Icons.auto_awesome_rounded, '/health-ai'),
    _NavItem('Reports', 'Reports', Icons.description_rounded, '/reports'),
    _NavItem('Clinics', 'Care', Icons.location_on_rounded, '/clinics'),
    _NavItem('My Profile', 'Profile', Icons.person_rounded, '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
    setState(() => _profileImagePath = nextImage);
  }

  void _go(_NavItem item) {
    if (item.label == widget.selectedItem) return;
    Navigator.pushReplacementNamed(context, item.route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1410222D),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: _items
              .map(
                (item) => Expanded(
                  child: _BottomItem(
                    item: item,
                    selected: item.label == widget.selectedItem,
                    profileImagePath: item.label == 'My Profile'
                        ? _profileImagePath
                        : null,
                    onTap: () => _go(item),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final String? profileImagePath;
  final VoidCallback onTap;

  const _BottomItem({
    required this.item,
    required this.selected,
    required this.profileImagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfileImage =
        profileImagePath != null && File(profileImagePath!).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.scrub : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasProfileImage)
              CircleAvatar(
                radius: 14,
                backgroundImage: FileImage(File(profileImagePath!)),
              )
            else
              Icon(
                item.icon,
                size: 22,
                color: selected ? AppTheme.clinicalGreen : AppTheme.textMuted,
              ),
            const SizedBox(height: 6),
            Text(
              item.display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppTheme.clinicalGreen : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String display;
  final IconData icon;
  final String route;

  const _NavItem(this.label, this.display, this.icon, this.route);
}
