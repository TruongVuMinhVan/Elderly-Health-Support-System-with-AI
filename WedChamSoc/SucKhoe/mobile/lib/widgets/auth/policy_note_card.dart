import 'package:flutter/material.dart';

/// Policy note card
class PolicyNoteCard extends StatelessWidget {
  const PolicyNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: const Text(
        'Bảo mật & Quyền riêng tư: Chúng tôi bảo vệ thông tin của bạn và không chia sẻ cho bên thứ ba. Bằng việc đăng ký, bạn đồng ý với điều khoản sử dụng.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}

