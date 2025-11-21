import 'package:flutter/material.dart';

/// Widget for Email 2FA disable UI
class Email2FADisableWidget extends StatelessWidget {
  const Email2FADisableWidget({super.key});

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
            'Tắt Email 2FA',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có thể tắt Email 2FA bằng cách nhấn nút tắt ở trên.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

