import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../styles/theme.dart';

/// Wrapper để các trang landing/auth luôn sử dụng light theme cố định
/// Không áp dụng theme, font size, hoặc language từ AppSettingsProvider
/// Đảm bảo landing và auth pages luôn có giao diện nhất quán
class StaticThemeWrapper extends StatelessWidget {
  final Widget child;
  final String? language; // Optional: 'vi' or 'en', default to 'vi'

  const StaticThemeWrapper({
    super.key,
    required this.child,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    // Override theme to always use light theme
    final staticTheme = ThemeData.light(useMaterial3: false);
    
    // Override font size to default (1.0)
    final staticTextScale = 1.0;
    
    // Use provided language or default to 'vi'
    final locale = language == 'en' 
        ? const Locale('en', 'US') 
        : const Locale('vi', 'VN');

    return Localizations(
      locale: locale,
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: staticTextScale,
        ),
        child: Theme(
          data: staticTheme,
          child: child,
        ),
      ),
    );
  }
}

