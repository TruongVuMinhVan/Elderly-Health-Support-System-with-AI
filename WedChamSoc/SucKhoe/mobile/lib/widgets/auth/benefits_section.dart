import 'package:flutter/material.dart';

/// Benefits section for registration
class BenefitsSection extends StatelessWidget {
  const BenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lợi ích khi đăng ký:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const BenefitRow(text: 'Theo dõi sức khỏe cá nhân hóa'),
        const BenefitRow(text: 'Nhắc nhở uống thuốc thông minh'),
        const BenefitRow(text: 'Tư vấn AI 24/7 miễn phí'),
        const BenefitRow(text: 'Báo cáo sức khỏe chi tiết'),
      ],
    );
  }
}

/// Single benefit row
class BenefitRow extends StatelessWidget {
  final String text;
  const BenefitRow({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

