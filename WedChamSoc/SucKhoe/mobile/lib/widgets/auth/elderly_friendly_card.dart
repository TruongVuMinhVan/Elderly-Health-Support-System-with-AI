import 'package:flutter/material.dart';

/// Card showing elderly-friendly features
class ElderlyFriendlyCard extends StatelessWidget {
  const ElderlyFriendlyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text('Dành cho người cao tuổi', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('Font chữ lớn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Dễ đọc, dễ nhìn', style: TextStyle(color: Colors.black54)),
            SizedBox(height: 12),
            Text('Đơn giản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Giao diện thân thiện', style: TextStyle(color: Colors.black54)),
            SizedBox(height: 12),
            Text('24/7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Hỗ trợ mọi lúc', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

