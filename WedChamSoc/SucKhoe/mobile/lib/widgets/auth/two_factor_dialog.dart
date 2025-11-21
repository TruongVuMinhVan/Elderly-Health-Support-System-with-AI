import 'package:flutter/material.dart';

/// Dialog for 2FA verification
class TwoFactorDialog {
  /// Shows the 2FA dialog and returns the OTP entered by the user
  static Future<String?> show(BuildContext context, {String? message}) {
    final otpCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác thực 2 bước'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message ?? 'Vui lòng nhập mã OTP gửi qua email'),
              const SizedBox(height: 12),
              TextField(
                controller: otpCtrl,
                decoration: const InputDecoration(labelText: 'Mã OTP'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                otpCtrl.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = otpCtrl.text.trim();
                otpCtrl.dispose();
                Navigator.pop(ctx, result);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}

