import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/auth_service.dart';
import '../../widgets/auth/login_form.dart';
import '../../widgets/auth/security_info_card.dart';
import '../../widgets/auth/elderly_friendly_card.dart';
import '../../widgets/auth/two_factor_dialog.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/reminder_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handle2FA(TwoFactorRequired twoFa) async {
    final result = await TwoFactorDialog.show(
      context,
      message: twoFa.message ?? 'Vui lòng nhập mã OTP gửi qua email',
    );

    if (result == null || result.isEmpty) return;

    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final auth = AuthService(api);
      await auth.verifyEmail2FA(twoFa.tempToken, _emailCtrl.text.trim(), result);
      if (!mounted) return;
      
      // Navigate immediately for faster login experience
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      
      // Load settings and initialize services in background (non-blocking)
      final settingsProvider = AppSettingsProvider();
      settingsProvider.reloadFromBackend().catchError((e) {
        // Silently handle errors - settings will use defaults
      });
      
      // Initialize reminder service in background
      ReminderService().initialize().catchError((e) {
        // Silently handle errors - reminders will sync later
      });
      
      // Show success message after navigation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xác thực 2 bước thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final auth = AuthService(api);
      final res = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (res is TwoFactorRequired) {
        await _handle2FA(res);
        return;
      }
      if (!mounted) return;
      
      // Navigate immediately for faster login experience
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      
      // Load settings and initialize services in background (non-blocking)
      final settingsProvider = AppSettingsProvider();
      settingsProvider.reloadFromBackend().catchError((e) {
        // Silently handle errors - settings will use defaults
      });
      
      // Initialize reminder service in background
      ReminderService().initialize().catchError((e) {
        // Silently handle errors - reminders will sync later
      });
      
      // Show success message after navigation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thành công')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        title: const Text(
          'Đăng nhập',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Đăng nhập vào tài khoản',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chăm sóc sức khỏe thông minh cho người cao tuổi',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Login form
            LoginForm(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              isLoading: _loading,
              onLogin: _submit,
              onNavigateToRegister: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // Security info
            const SecurityInfoCard(),

            const SizedBox(height: 16),

            // Elderly friendly section
            const ElderlyFriendlyCard(),
          ],
        ),
      ),
    );
  }
}


