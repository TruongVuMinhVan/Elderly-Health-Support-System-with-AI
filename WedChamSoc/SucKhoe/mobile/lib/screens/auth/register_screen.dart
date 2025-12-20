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
        const SnackBar(
          content: Text('Đăng ký thành công'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Đăng ký thất bại';
      
      // Xử lý lỗi cụ thể từ backend
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('email already registered') || 
          errorStr.contains('email đã được đăng ký') ||
          errorStr.contains('already exists')) {
        errorMessage = 'Email này đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.';
      } else if (errorStr.contains('password') && errorStr.contains('6')) {
        errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      } else if (errorStr.contains('invalid email') || errorStr.contains('email không hợp lệ')) {
        errorMessage = 'Email không hợp lệ. Vui lòng kiểm tra lại.';
      } else if (errorStr.contains('detail')) {
        // Lấy message từ detail nếu có
        final match = RegExp(r'detail[:\s]+(.+?)(?:\.|$)').firstMatch(errorStr);
        if (match != null) {
          errorMessage = match.group(1) ?? errorMessage;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
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
          'Đăng ký',
          style: TextStyle(color: Colors.white),
        ),
      ),
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


