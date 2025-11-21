import 'package:flutter/material.dart';
import 'header.dart';
import 'sidebar.dart';
import 'footer.dart';

/// Widget Layout tổng hợp cho toàn bộ app
/// Gắn header, sidebar (drawer), body, và footer ở cuối trang.
class LayoutWrapper extends StatelessWidget {
  final Widget child;
  final bool showSidebar;

  const LayoutWrapper({
    super.key,
    required this.child,
    this.showSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: const Header(),
      // Drawer (sidebar)
      drawer: showSidebar ? const Sidebar() : null,
      // Body nội dung chính
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
      // Thanh điều hướng dưới (mobile)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // TODO: thêm navigation logic thật khi tích hợp router
          final pages = ['Trang chủ', 'Sức khỏe', 'Thuốc', 'Lịch hẹn', 'Chat'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đi tới: ${pages[index]}')),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Sức khỏe'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Thuốc'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch hẹn'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
        ],
      ),
    );
  }
}
