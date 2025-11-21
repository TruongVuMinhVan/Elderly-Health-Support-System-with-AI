import 'package:flutter/material.dart';
import '../../screens/health/health_screen.dart';
import '../../screens/medications/medications_screen.dart';
import '../../screens/schedules/schedules_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../widgets/dashboard/dashboard.dart';

class AuthenticatedLayoutWrapper extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const AuthenticatedLayoutWrapper({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  State<AuthenticatedLayoutWrapper> createState() => _AuthenticatedLayoutWrapperState();
}

class _AuthenticatedLayoutWrapperState extends State<AuthenticatedLayoutWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

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
    // Wrap child with bottom navigation
    // Note: Child should already have Scaffold, we just add bottomNavigationBar
    final child = widget.child;
    
    // If child is a Scaffold, we need to extract it and add bottomNavigationBar
    if (child is Scaffold) {
      return Scaffold(
        key: child.key,
        appBar: child.appBar,
        body: child.body,
        floatingActionButton: child.floatingActionButton,
        floatingActionButtonLocation: child.floatingActionButtonLocation,
        persistentFooterButtons: child.persistentFooterButtons,
        persistentFooterAlignment: child.persistentFooterAlignment,
        drawer: child.drawer,
        endDrawer: child.endDrawer,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Sức khỏe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Thuốc',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Lịch hẹn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble),
              label: 'Tư vấn AI',
            ),
          ],
        ),
      );
    }
    
    // If not Scaffold, wrap it
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Sức khỏe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Thuốc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Tư vấn AI',
          ),
        ],
      ),
    );
  }
}

