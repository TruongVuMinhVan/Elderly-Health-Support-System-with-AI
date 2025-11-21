import 'package:flutter/material.dart';

/// Login form widget
class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onNavigateToRegister;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.isLoading,
    required this.onLogin,
    required this.onNavigateToRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Nhập địa chỉ email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Nhập mật khẩu',
                ),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isLoading ? null : onLogin,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login),
                label: const Text('Đăng nhập'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? '),
                  InkWell(
                    onTap: onNavigateToRegister,
                    child: Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

