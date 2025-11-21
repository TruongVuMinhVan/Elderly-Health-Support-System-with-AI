import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'styles/theme.dart';
import 'widgets/landing/landing_page.dart';
import 'widgets/dashboard/dashboard.dart';
import 'widgets/layout/authenticated_layout_wrapper.dart';
import 'widgets/auth/auth_guard.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/medications/medications_screen.dart';
import 'screens/schedules/schedules_screen.dart';
import 'screens/chat/chat_screen.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = AppSettingsProvider();
    
    return ListenableBuilder(
      listenable: settingsProvider,
      builder: (context, _) {
        final themeMode = settingsProvider.getThemeMode();
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(fontSize: settingsProvider.fontSize),
          darkTheme: buildDarkTheme(fontSize: settingsProvider.fontSize),
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
          locale: settingsProvider.language == 'en'
              ? const Locale('en', 'US')
              : const Locale('vi', 'VN'),
          initialRoute: '/root',
          routes: {
        '/root': (_) => const RootRouter(),
        '/': (_) => const LandingPage(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/dashboard': (_) => AuthGuard(
              child: AuthenticatedLayoutWrapper(
                initialIndex: 0,
                child: const Dashboard(),
              ),
            ),
        '/profile': (_) => AuthGuard(
              child: const ProfileScreen(),
            ),
        '/settings': (_) => AuthGuard(
              child: const SettingsScreen(),
            ),
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
          },
        );
      },
    );
  }
}
