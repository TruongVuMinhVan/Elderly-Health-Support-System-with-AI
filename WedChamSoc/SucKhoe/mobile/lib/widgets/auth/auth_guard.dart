import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/auth/login_screen.dart';
import '../../api/api_client.dart';
import '../../api/user_service.dart';
import '../../services/reminder_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null && token.isNotEmpty) {
        // Verify token with backend by making a simple API call
        try {
          await UserService(ApiClient()).getCurrentUser();
          // Token is valid
          // Initialize reminder service để sync notifications
          await ReminderService().initialize();
          
          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _isChecking = false;
            });
          }
        } on TokenExpiredException {
          // Token expired
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
              _isChecking = false;
            });
            _redirectToLogin('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
          }
        } catch (e) {
          // Other errors - treat as unauthenticated
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
              _isChecking = false;
            });
            _redirectToLogin('Vui lòng đăng nhập để tiếp tục');
          }
        }
      } else {
        // No token
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isChecking = false;
          });
          _redirectToLogin('Vui lòng đăng nhập để tiếp tục');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
        });
        _redirectToLogin('Vui lòng đăng nhập để tiếp tục');
      }
    }
  }

  void _redirectToLogin([String? message]) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    if (mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.child;
  }
}

