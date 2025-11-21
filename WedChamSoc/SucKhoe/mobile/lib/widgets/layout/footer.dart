import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Hệ thống hỗ trợ sức khỏe người cao tuổi",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 8,
            children: const [
              Text("Về chúng tôi",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              Text("Liên hệ",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              Text("Chính sách bảo mật",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 0.8),
          const SizedBox(height: 6),
          Text(
            "© 2025 SucKhoeApp. Tất cả quyền được bảo lưu.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
