import 'package:flutter/material.dart';

import '../config/app_identity.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;
  String? _statusMessage;
  bool _routeMessageLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeMessageLoaded) return;
    _routeMessageLoaded = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final authMessage = args?['authMessage']?.toString().trim();
    if (authMessage?.isNotEmpty == true) {
      setState(() => _statusMessage = authMessage);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _statusMessage = 'Checking your credentials...';
    });

    try {
      final apiService = ApiService();
      final response = await apiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      if (response != null &&
          (response['token'] != null || response['status'] == 'success')) {
        setState(
          () => _statusMessage = 'Login successful. Opening dashboard...',
        );
        final String userName =
            (response['user']?['name'] as String?)?.trim().isNotEmpty == true
            ? (response['user']['name'] as String).trim()
            : emailController.text.trim().split('@').first;
        final String userId = (response['user']?['id']?.toString() ?? '')
            .trim();
        final String userEmail =
            (response['user']?['email'] as String?)?.trim().isNotEmpty == true
            ? (response['user']['email'] as String).trim()
            : emailController.text.trim();
        final String token = (response['token'] as String? ?? '').trim();
        final String role = (response['user']?['role'] as String? ?? 'user')
            .trim();

        await AuthService().persistSession(
          userId: userId,
          userName: userName,
          userEmail: userEmail,
          token: token,
          role: role,
        );
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'userName': userName, 'userEmail': userEmail},
        );
      } else {
        setState(() {
          _statusMessage = response?['message'] ?? 'Invalid credentials';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Invalid credentials'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _statusMessage = 'Connection error. Please check the backend service.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: AppIdentity.appName,
      title: 'Welcome back to Ayuva',
      subtitle: AppIdentity.appShortDescription,
      stats: const [
        AuthStat(label: 'AI review', value: '24/7', tint: AppTheme.aqua),
        AuthStat(label: 'Privacy', value: 'Secure', tint: AppTheme.blue),
      ],
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('New here?'),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue to your reports, symptom guidance, and care history.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(
                label: 'Email address',
                hint: 'doctor@example.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration:
                  _fieldDecoration(
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot password'),
              ),
            ),
            const SizedBox(height: 8),
            if (_statusMessage != null) ...[
              AuthStatusBanner(message: _statusMessage!),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: AppTheme.clinicalGreen,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.softSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_moon_outlined, color: AppTheme.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your session is stored locally after login so your dashboard and profile stay in sync.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    );
  }
}
