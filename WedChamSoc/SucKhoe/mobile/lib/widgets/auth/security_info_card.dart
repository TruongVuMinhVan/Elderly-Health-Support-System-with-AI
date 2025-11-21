import 'package:flutter/material.dart';

/// Security information card
class SecurityInfoCard extends StatelessWidget {
  const SecurityInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đăng nhập an toàn', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'Chúng tôi sử dụng công nghệ bảo mật để bảo vệ thông tin của bạn. Không bao giờ chia sẻ mật khẩu với người khác.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

