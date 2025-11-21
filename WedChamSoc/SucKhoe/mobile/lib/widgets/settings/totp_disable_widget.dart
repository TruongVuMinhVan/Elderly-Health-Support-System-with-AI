import 'package:flutter/material.dart';

/// Widget for TOTP 2FA disable UI
class TOTPDisableWidget extends StatelessWidget {
  final String verificationCode;
  final ValueChanged<String> onVerificationCodeChanged;
  final VoidCallback onDisable;

  const TOTPDisableWidget({
    super.key,
    required this.verificationCode,
    required this.onVerificationCodeChanged,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tắt TOTP 2FA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nhập mã xác thực để tắt TOTP 2FA',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            onChanged: (value) {
              onVerificationCodeChanged(value.replaceAll(RegExp(r'[^0-9]'), ''));
            },
            controller: TextEditingController(text: verificationCode)
              ..selection = TextSelection.collapsed(offset: verificationCode.length),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: verificationCode.length == 6 ? onDisable : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tắt TOTP 2FA'),
          ),
        ],
      ),
    );
  }
}

