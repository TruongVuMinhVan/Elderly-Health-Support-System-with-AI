import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'styles/theme.dart';
import 'widgets/landing/landing_page.dart';
import 'widgets/dashboard/dashboard.dart';
import 'widgets/layout/authenticated_layout_wrapper.dart';
import 'widgets/auth/auth_guard.dart';
import 'widgets/auth/static_theme_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/medications/medications_screen.dart';
import 'screens/schedules/schedules_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/quick_scan/quick_scan_screen.dart';
import 'screens/chatbot_consult/chatbot_consult_screen.dart';
import 'screens/doctors/doctors_screen.dart';
import 'screens/root/root_router.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart';
import 'providers/app_settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await NotificationService().initialize();
  
  // Load app settings
  await AppSettingsProvider().loadSettings();
  
  // Initialize reminder service (sẽ sync reminders từ API)
  // ReminderService sẽ được khởi tạo sau khi user login
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Use a GlobalKey to preserve navigation state when MaterialApp rebuilds
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // Cache routes to prevent rebuilding them when settings change
  late final Map<String, WidgetBuilder> _routes;

  @override
  void initState() {
    super.initState();
    // Build routes once and cache them - this prevents route recreation on rebuild
    _routes = {
      '/root': (_) => StaticThemeWrapper(child: const RootRouter()),
      '/': (_) => StaticThemeWrapper(child: const LandingPage()),
      '/login': (_) => StaticThemeWrapper(child: const LoginScreen()),
      '/register': (_) => StaticThemeWrapper(child: const RegisterScreen()),
      '/dashboard': (_) => AuthGuard(
            child: AuthenticatedLayoutWrapper(
              initialIndex: 0,
              child: const Dashboard(),
            ),
          ),
      '/profile': (_) => AuthGuard(child: const ProfileScreen()),
      '/settings': (_) => AuthGuard(child: const SettingsScreen()),
      '/health': (_) => AuthGuard(
            child: AuthenticatedLayoutWrapper(
              initialIndex: 1,
              child: const HealthScreen(),
            ),
          ),
      '/medications': (_) => AuthGuard(
            child: AuthenticatedLayoutWrapper(
              initialIndex: 2,
              child: const MedicationsScreen(),
            ),
          ),
      '/schedules': (_) => AuthGuard(
            child: AuthenticatedLayoutWrapper(
              initialIndex: 3,
              child: const SchedulesScreen(),
            ),
          ),
      '/chat': (_) => AuthGuard(
            child: AuthenticatedLayoutWrapper(
              initialIndex: 4,
              child: const ChatScreen(),
            ),
          ),
      '/quick-scan': (_) => const QuickScanScreen(),
      '/chatbot-consult': (_) => const ChatbotConsultScreen(),
      '/doctors': (_) => const DoctorsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = AppSettingsProvider();
    
    return ListenableBuilder(
      listenable: settingsProvider,
      builder: (context, _) {
        // Get current settings
        final themeMode = settingsProvider.getThemeMode();
        final fontSize = settingsProvider.fontSize;
        final language = settingsProvider.language;
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // Use navigatorKey to preserve navigation state when theme changes
          navigatorKey: _navigatorKey,
          // Don't use ValueKey - it causes full rebuild and resets navigation
          // NavigatorKey will preserve the navigation stack
          theme: buildLightTheme(fontSize: fontSize),
          darkTheme: buildDarkTheme(fontSize: fontSize),
          themeMode: themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: settingsProvider.getTextScaleFactor(),
              ),
              child: child!,
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('vi', 'VN'),
          ],
          locale: language == 'en'
              ? const Locale('en', 'US')
              : const Locale('vi', 'VN'),
          initialRoute: '/root',
          routes: _routes,
        );
      },
    );
  }
}
