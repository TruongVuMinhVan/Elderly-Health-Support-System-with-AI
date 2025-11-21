import 'package:flutter/material.dart';

/// Card showing registration steps
class RegistrationStepsCard extends StatelessWidget {
  const RegistrationStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF5),
        border: Border.all(color: const Color(0xFF86EFAC)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Quy trình đăng ký đơn giản:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          StepRow(text: 'Nhập email và mật khẩu'),
          StepRow(text: 'Xác minh email'),
          StepRow(text: 'Hoàn thiện hồ sơ sức khỏe'),
          StepRow(text: 'Bắt đầu sử dụng'),
        ],
      ),
    );
  }
}

/// Single step row
class StepRow extends StatelessWidget {
  final String text;
  const StepRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

