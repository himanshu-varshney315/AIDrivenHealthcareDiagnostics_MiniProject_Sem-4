import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_ui.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();
  final _blood = TextEditingController();
  final _emergency = TextEditingController();
  String _activeEmail = '';
  String? _imagePath;
  bool _notifications = true;
  bool _shareReports = false;
  bool _loaded = false;

  static const _nameKey = 'profile_name';
  static const _emailKey = 'profile_email';
  static const _phoneKey = 'profile_phone';
  static const _ageKey = 'profile_age';
  static const _bloodKey = 'profile_blood_group';
  static const _emergencyKey = 'profile_emergency';
  static const _imageKey = 'profile_image_path';
  static const _notificationsKey = 'profile_notifications';
  static const _shareKey = 'profile_share_reports';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _age.dispose();
    _blood.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final session = await AuthService().loadSession();
    final email = session?.userEmail.trim().toLowerCase() ?? '';
    String read(String key, [String fallback = '']) =>
        prefs.getString(AuthService.scopedKey(email, key)) ?? fallback;
    if (!mounted) return;
    setState(() {
      _activeEmail = email;
      _name.text = read(_nameKey, session?.userName ?? '');
      _email.text = read(_emailKey, email);
      _phone.text = read(_phoneKey);
      _age.text = read(_ageKey);
      _blood.text = read(_bloodKey);
      _emergency.text = read(_emergencyKey);
      _imagePath = read(_imageKey).trim().isEmpty ? null : read(_imageKey);
      _notifications =
          prefs.getBool(AuthService.scopedKey(email, _notificationsKey)) ??
          true;
      _shareReports =
          prefs.getBool(AuthService.scopedKey(email, _shareKey)) ?? false;
      _loaded = true;
    });
  }

  String _key(String base) => AuthService.scopedKey(_activeEmail, base);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_nameKey), _name.text.trim());
    await prefs.setString(_key(_emailKey), _email.text.trim());
    await prefs.setString(_key(_phoneKey), _phone.text.trim());
    await prefs.setString(_key(_ageKey), _age.text.trim());
    await prefs.setString(_key(_bloodKey), _blood.text.trim());
    await prefs.setString(_key(_emergencyKey), _emergency.text.trim());
    await prefs.setBool(_key(_notificationsKey), _notifications);
    await prefs.setBool(_key(_shareKey), _shareReports);
    if (_imagePath != null) await prefs.setString(_key(_imageKey), _imagePath!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 900,
    );
    if (picked == null) return;
    setState(() => _imagePath = picked.path);
  }

  Future<void> _logout() async {
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  int get _completion {
    final fields = [
      _name.text.trim(),
      _email.text.trim(),
      _phone.text.trim(),
      _age.text.trim(),
      _blood.text.trim(),
      _emergency.text.trim(),
    ];
    return ((fields.where((value) => value.isNotEmpty).length / fields.length) *
            100)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hasImage = _imagePath != null && File(_imagePath!).existsSync();

    return AppPage(
      bottomNavigationBar: const AppBottomBar(selectedItem: 'My Profile'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(
              eyebrow: 'Profile',
              title: 'Your care profile',
              subtitle:
                  'Keep identity, medical context, and preferences ready for faster follow-up.',
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
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white,
                        backgroundImage: hasImage
                            ? FileImage(File(_imagePath!))
                            : null,
                        child: hasImage
                            ? null
                            : const Icon(
                                Icons.person_rounded,
                                size: 46,
                                color: AppTheme.clinicalGreen,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: PopupMenuButton<ImageSource>(
                          icon: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          color: Colors.white,
                          onSelected: _pickImage,
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: ImageSource.camera,
                              child: Text('Camera'),
                            ),
                            PopupMenuItem(
                              value: ImageSource.gallery,
                              child: Text('Gallery'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name.text.trim().isEmpty
                              ? 'Health AI user'
                              : _name.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _email.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AppBadge(
                          text: '$_completion% complete',
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                        ),
                      ],
                    ),
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
                    'Identity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _Field(controller: _name, label: 'Full name', icon: Icons.badge),
                  _Field(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _Field(
                    controller: _phone,
                    label: 'Phone',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _age,
                          label: 'Age',
                          icon: Icons.cake_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: _blood,
                          label: 'Blood group',
                          icon: Icons.bloodtype_rounded,
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    controller: _emergency,
                    label: 'Emergency contact',
                    icon: Icons.local_hospital_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _SwitchTile(
                    title: 'Notifications',
                    subtitle: 'Analysis status and urgent health alerts',
                    icon: Icons.notifications_rounded,
                    value: _notifications,
                    onChanged: (value) => setState(() => _notifications = value),
                  ),
                  _SwitchTile(
                    title: 'Doctor sharing',
                    subtitle: 'Mark reports as share-ready for appointments',
                    icon: Icons.ios_share_rounded,
                    value: _shareReports,
                    onChanged: (value) => setState(() => _shareReports = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save profile'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) =>
            label == 'Full name' && (value == null || value.trim().isEmpty)
            ? 'Name is required'
            : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.softSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppTheme.clinicalGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
