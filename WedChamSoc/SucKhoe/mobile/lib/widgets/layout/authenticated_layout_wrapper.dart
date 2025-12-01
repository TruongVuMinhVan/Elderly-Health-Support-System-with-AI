import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // Cache all screens to avoid rebuilding
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Pre-build all screens for instant switching
    _screens = [
      const Dashboard(),
      const HealthScreen(),
      const MedicationsScreen(),
      const SchedulesScreen(),
      const ChatScreen(),
    ];
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    
    // Instant switch using setState - no navigation needed
    setState(() {
      _currentIndex = index;
    });
  }

  /// Handle back button press
  /// If not on dashboard, go to dashboard
  /// If on dashboard, exit app (or do nothing)
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on dashboard, switch to dashboard instead of popping
      setState(() {
        _currentIndex = 0;
      });
      return false; // Prevent default back behavior
    }
    // If on dashboard, allow back to exit app (or show exit confirmation)
    return true; // Allow default back behavior (exit app)
  }


  @override
  Widget build(BuildContext context) {
    // Use IndexedStack to keep all screens in memory for instant switching
    return PopScope(
      canPop: _currentIndex == 0, // Only allow pop when on dashboard
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) {
          // If back was pressed and not on dashboard, go to dashboard
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
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
      ),
    );
  }
}

