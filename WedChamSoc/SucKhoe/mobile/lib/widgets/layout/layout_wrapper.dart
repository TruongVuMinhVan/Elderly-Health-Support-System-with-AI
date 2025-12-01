import 'package:flutter/material.dart';
import 'header.dart';
import 'footer.dart';

/// Widget Layout tổng hợp cho toàn bộ app
/// Gắn header, body, và footer ở cuối trang.
class LayoutWrapper extends StatefulWidget {
  final Widget child;
  final int? currentIndex;

  const LayoutWrapper({
    super.key,
    required this.child,
    this.currentIndex,
  });

  @override
  State<LayoutWrapper> createState() => _LayoutWrapperState();
}

class _LayoutWrapperState extends State<LayoutWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Khởi tạo index, sẽ được cập nhật trong build() dựa trên route
    _currentIndex = widget.currentIndex ?? 0;
  }

  int _getCurrentIndexFromRoute() {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/dashboard':
        return 0;
      case '/health':
        return 1;
      case '/medications':
        return 2;
      case '/schedules':
        return 3;
      case '/chat':
        return 4;
      default:
        return 0;
    }
  }

  void _onTabTapped(int index) {
    // Nếu đã ở trang đó rồi thì không làm gì
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Điều hướng đến trang tương ứng
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/health');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/medications');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/schedules');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cập nhật index khi route thay đổi
    final newIndex = _getCurrentIndexFromRoute();
    if (newIndex != _currentIndex) {
      // Sử dụng WidgetsBinding để tránh setState trong build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex != newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        }
      });
    }

    return Scaffold(
      // AppBar
      appBar: const Header(),
      // Body nội dung chính
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: widget.child,
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
      // Thanh điều hướng dưới (mobile)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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
