import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _emergencyController = TextEditingController();

  String? _imagePath;
  bool _notificationsEnabled = true;
  bool _shareReportsWithDoctor = false;
  bool _didLoad = false;
  bool _isInitialized = false;

  static const _nameKey = 'profile_name';
  static const _emailKey = 'profile_email';
  static const _phoneKey = 'profile_phone';
  static const _ageKey = 'profile_age';
  static const _bloodGroupKey = 'profile_blood_group';
  static const _emergencyKey = 'profile_emergency';
  static const _imagePathKey = 'profile_image_path';
  static const _notificationsKey = 'profile_notifications';
  static const _shareReportsKey = 'profile_share_reports';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _nameController.text =
          prefs.getString(_nameKey) ?? (args?['userName'] as String? ?? '');
      _emailController.text =
          prefs.getString(_emailKey) ?? (args?['userEmail'] as String? ?? '');
      _phoneController.text = prefs.getString(_phoneKey) ?? '';
      _ageController.text = prefs.getString(_ageKey) ?? '';
      _bloodGroupController.text = prefs.getString(_bloodGroupKey) ?? '';
      _emergencyController.text = prefs.getString(_emergencyKey) ?? '';
      _imagePath = prefs.getString(_imagePathKey);
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _shareReportsWithDoctor = prefs.getBool(_shareReportsKey) ?? false;
      _didLoad = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (picked == null) return;

    setState(() {
      _imagePath = picked.path;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _nameController.text.trim());
    await prefs.setString(_emailKey, _emailController.text.trim());
    await prefs.setString(_phoneKey, _phoneController.text.trim());
    await prefs.setString(_ageKey, _ageController.text.trim());
    await prefs.setString(_bloodGroupKey, _bloodGroupController.text.trim());
    await prefs.setString(_emergencyKey, _emergencyController.text.trim());
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
    await prefs.setBool(_shareReportsKey, _shareReportsWithDoctor);
    if (_imagePath != null) {
      await prefs.setString(_imagePathKey, _imagePath!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved successfully')));
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_didLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasImage = _imagePath != null && File(_imagePath!).existsSync();
    final imageProvider = hasImage ? FileImage(File(_imagePath!)) : null;
    final displayName = _nameController.text.trim().isEmpty
        ? 'Your Profile'
        : _nameController.text.trim();
    final displayEmail = _emailController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF5FF), Color(0xFFF4EEFF), Color(0xFFF8F9FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE4F4FF), Color(0xFFF4EBFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 18,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: Colors.white,
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 58,
                                      color: Color(0xFF61708E),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: const Color(0xFF263145),
                                borderRadius: BorderRadius.circular(999),
                                child: PopupMenuButton<String>(
                                  tooltip: 'Change photo',
                                  color: Colors.white,
                                  icon: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'camera') {
                                      _pickImage(ImageSource.camera);
                                    } else {
                                      _pickImage(ImageSource.gallery);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'camera',
                                      child: Text('Take Photo'),
                                    ),
                                    PopupMenuItem(
                                      value: 'gallery',
                                      child: Text('Choose from Gallery'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (displayEmail.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            displayEmail,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          'Keep your health details updated so reports and care history stay easy to manage.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            color: Colors.black.withValues(alpha: 0.72),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _StatusChip(
                                icon: Icons.notifications_active_outlined,
                                label: 'Alerts',
                                value: _notificationsEnabled ? 'On' : 'Off',
                                color: const Color(0xFF5F8EF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatusChip(
                                icon: Icons.shield_outlined,
                                label: 'Reports',
                                value: _shareReportsWithDoctor
                                    ? 'Shared'
                                    : 'Private',
                                color: const Color(0xFF9A63E4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Personal Information',
                    child: Column(
                      children: [
                        _profileField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.badge_outlined,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _profileField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _profileField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _profileField(
                                controller: _ageController,
                                label: 'Age',
                                icon: Icons.calendar_month_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _profileField(
                                controller: _bloodGroupController,
                                label: 'Blood Group',
                                icon: Icons.bloodtype_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _profileField(
                          controller: _emergencyController,
                          label: 'Emergency Contact',
                          icon: Icons.local_hospital_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Preferences',
                    child: Column(
                      children: [
                        _PreferenceTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Get reminders for hydration and reports',
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        _PreferenceTile(
                          icon: Icons.volunteer_activism_outlined,
                          title: 'Share Reports with Doctor',
                          subtitle: 'Enable easier consultation follow-ups',
                          value: _shareReportsWithDoctor,
                          onChanged: (value) {
                            setState(() => _shareReportsWithDoctor = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Account',
                    child: Column(
                      children: [
                        _AccountActionTile(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          subtitle:
                              'Return to the login screen from your profile',
                          accentColor: const Color(0xFFE46A77),
                          backgroundColor: const Color(0xFFFFEEF0),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF243148),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5C6884)),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(width: 52, height: 52, child: Icon(icon, size: 20)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
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
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF626A78),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF597FF1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666D79),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF243148),
            activeTrackColor: const Color(0xFFCAD5F7),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6C707A),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
