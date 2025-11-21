import 'package:flutter/material.dart';

/// Widget for Email 2FA setup UI
class Email2FASetupWidget extends StatelessWidget {
  final String otpCode;
  final ValueChanged<String> onOtpCodeChanged;
  final VoidCallback onEnable;
  final VoidCallback onResend;
  final VoidCallback onCancel;
  final bool isSendingOtp;

  const Email2FASetupWidget({
    super.key,
    required this.otpCode,
    required this.onOtpCodeChanged,
    required this.onEnable,
    required this.onResend,
    required this.onCancel,
    this.isSendingOtp = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.green[900]!.withOpacity(0.2) : Colors.green[50],
        border: Border.all(color: isDark ? Colors.green[700]! : Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thiết lập Email 2FA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mã xác thực đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư và nhập mã 6 số:',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Mã xác thực',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            onChanged: (value) {
              onOtpCodeChanged(value.replaceAll(RegExp(r'[^0-9]'), ''));
            },
            controller: TextEditingController(text: otpCode)
              ..selection = TextSelection.collapsed(offset: otpCode.length),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: otpCode.length == 6 ? onEnable : null,
                  child: const Text('Bật Email 2FA'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isSendingOtp ? null : onResend,
                child: Text(isSendingOtp ? 'Đang gửi...' : 'Gửi lại mã'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onCancel,
                child: const Text('Hủy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

