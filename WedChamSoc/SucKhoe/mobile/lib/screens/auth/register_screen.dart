import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/auth_service.dart';
import '../../widgets/auth/register_form.dart';
import '../../widgets/auth/benefits_section.dart';
import '../../widgets/auth/registration_steps_card.dart';
import '../../widgets/auth/policy_note_card.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final auth = AuthService(api);
      await auth.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const BenefitsSection(),
            const SizedBox(height: 12),

            // Register form
            RegisterForm(
              formKey: _formKey,
              fullNameCtrl: _fullNameCtrl,
              emailCtrl: _emailCtrl,
              phoneCtrl: _phoneCtrl,
              passwordCtrl: _passwordCtrl,
              confirmCtrl: _confirmCtrl,
              isLoading: _loading,
              onRegister: _submit,
              onNavigateToLogin: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // Registration steps
            const RegistrationStepsCard(),

            const SizedBox(height: 12),

            // Policy note
            const PolicyNoteCard(),
          ],
        ),
      ),
    );
  }
}


