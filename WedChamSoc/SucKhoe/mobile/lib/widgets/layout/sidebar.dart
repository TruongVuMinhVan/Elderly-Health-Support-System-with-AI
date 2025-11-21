import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  Widget _navTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Row(
                children: const [
                  CircleAvatar(radius: 30, child: Icon(Icons.person)),
                  SizedBox(width: 10),
                  Text('Người dùng', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            _navTile(context, Icons.home, 'Trang chủ', () {}),
            _navTile(context, Icons.favorite, 'Sức khỏe', () {}),
            _navTile(context, Icons.medical_services, 'Thuốc', () {}),
            _navTile(context, Icons.calendar_today, 'Lịch hẹn', () {}),
            _navTile(context, Icons.chat_bubble, 'Tư vấn AI', () {}),
            const Spacer(),
            _navTile(context, Icons.help_outline, 'Trợ giúp', () {}),
          ],
        ),
      ),
    );
  }
}
