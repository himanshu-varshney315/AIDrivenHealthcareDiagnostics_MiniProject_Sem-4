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
  void initState() {
    super.initState();
  }

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString(_nameKey) ?? (args?['userName'] as String? ?? '');
      _emailController.text = prefs.getString(_emailKey) ?? (args?['userEmail'] as String? ?? '');
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
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 900);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_didLoad) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF4B73FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFE7EDFF),
                          backgroundImage: (_imagePath != null && File(_imagePath!).existsSync())
                              ? FileImage(File(_imagePath!))
                              : null,
                          child: (_imagePath == null || !File(_imagePath!).existsSync())
                              ? const Icon(Icons.person, size: 64, color: Color(0xFF5D72A8))
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B73FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: PopupMenuButton<String>(
                              tooltip: 'Change photo',
                              color: Colors.white,
                              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                              onSelected: (value) {
                                if (value == 'camera') {
                                  _pickImage(ImageSource.camera);
                                } else {
                                  _pickImage(ImageSource.gallery);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'camera', child: Text('Take Photo')),
                                PopupMenuItem(value: 'gallery', child: Text('Choose from Gallery')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Personal Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    _profileField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.badge_outlined,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _profileField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Email is required';
                        if (!value.contains('@')) return 'Enter a valid email';
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Get reminders for hydration and reports'),
                      value: _notificationsEnabled,
                      activeThumbColor: const Color(0xFF4B73FF),
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Share Reports with Doctor'),
                      subtitle: const Text('Enable easier consultation follow-ups'),
                      value: _shareReportsWithDoctor,
                      activeThumbColor: const Color(0xFF4B73FF),
                      onChanged: (value) {
                        setState(() => _shareReportsWithDoctor = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B73FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
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
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF7F9FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
