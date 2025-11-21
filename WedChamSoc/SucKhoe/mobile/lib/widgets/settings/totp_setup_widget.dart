import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

/// Widget for TOTP 2FA setup UI
class TOTPSetupWidget extends StatelessWidget {
  final Uint8List? qrCodeBytes;
  final String? secret;
  final String verificationCode;
  final ValueChanged<String> onVerificationCodeChanged;
  final VoidCallback onEnable;
  final VoidCallback onCancel;
  final bool isEnabled;

  const TOTPSetupWidget({
    super.key,
    this.qrCodeBytes,
    this.secret,
    required this.verificationCode,
    required this.onVerificationCodeChanged,
    required this.onEnable,
    required this.onCancel,
    this.isEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue[900]!.withOpacity(0.2) : Colors.blue[50],
        border: Border.all(color: isDark ? Colors.blue[700]! : Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thiết lập 2FA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),

          // QR Code
          if (qrCodeBytes != null)
            Column(
              children: [
                Text(
                  'Quét mã QR bằng ứng dụng xác thực:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Image.memory(
                    qrCodeBytes!,
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Theme.of(context).cardColor,
                        child: Center(
                          child: Text(
                            'Không thể tải QR code',
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Manual Secret
          if (secret != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoặc nhập mã thủ công:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          secret!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: secret!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép mã bí mật')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Verification Code Input
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nhập mã 6 số để xác thực',
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

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: verificationCode.length == 6 ? onEnable : null,
                  child: const Text('Bật 2FA'),
                ),
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

