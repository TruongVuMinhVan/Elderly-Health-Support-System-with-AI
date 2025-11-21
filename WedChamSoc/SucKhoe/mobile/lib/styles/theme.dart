import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF0EA5E9); // approx primary-600
  static const Color primary700 = Color(0xFF0284C7);
  static const Color secondary100 = Color(0xFFF1F5F9);
  static const Color secondary900 = Color(0xFF0F172A);
  static const Color elderlyBg = Color(0xFFF8FAFC);
  static const Color elderlyText = Color(0xFF0F172A);
  static const Color elderlyTextLight = Color(0xFF475569);
  static const Color elderlyBorder = Color(0xFFE2E8F0);

  static const Color healthNormal = Color(0xFF16A34A);
  static const Color healthWarning = Color(0xFFEAB308);
  static const Color healthDanger = Color(0xFFDC2626);
}

/// Build theme với support cho dark mode và font size
ThemeData buildAppTheme({
  ThemeMode themeMode = ThemeMode.light,
  String fontSize = 'large',
}) {
  final isDark = themeMode == ThemeMode.dark;
  final base = isDark 
      ? ThemeData.dark(useMaterial3: false)
      : ThemeData.light(useMaterial3: false);

  // Calculate font sizes based on fontSize setting
  double baseBodyLarge = 18;
  double baseBodyMedium = 16;
  double baseTitleLarge = 20;
  double baseAppBar = 18;

  switch (fontSize) {
    case 'small':
      baseBodyLarge = 15;
      baseBodyMedium = 13;
      baseTitleLarge = 17;
      baseAppBar = 16;
      break;
    case 'medium':
      baseBodyLarge = 16;
      baseBodyMedium = 14;
      baseTitleLarge = 18;
      baseAppBar = 17;
      break;
    case 'large':
      baseBodyLarge = 18;
      baseBodyMedium = 16;
      baseTitleLarge = 20;
      baseAppBar = 18;
      break;
    case 'extra-large':
      baseBodyLarge = 22;
      baseBodyMedium = 20;
      baseTitleLarge = 24;
      baseAppBar = 22;
      break;
  }

  final textColor = isDark ? Colors.white : AppColors.elderlyText;
  final textColorLight = isDark ? Colors.grey[300] : AppColors.elderlyTextLight;
  final bgColor = isDark ? const Color(0xFF1E1E1E) : AppColors.elderlyBg;
  final surfaceColor = isDark ? const Color(0xFF2D2D2D) : Colors.white;
  final borderColor = isDark ? Colors.grey[700]! : AppColors.elderlyBorder;

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    bodyLarge: GoogleFonts.inter(
      fontSize: baseBodyLarge,
      height: 1.6,
      color: textColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: baseBodyMedium,
      height: 1.6,
      color: textColor,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: baseTitleLarge,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: bgColor,
    primaryColor: AppColors.primary,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: isDark ? Colors.grey[800]! : AppColors.secondary100,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: isDark ? Colors.white : AppColors.secondary900,
      onSurface: textColor,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      foregroundColor: textColor,
      titleTextStyle: GoogleFonts.inter(
        fontSize: baseAppBar,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: isDark ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) => AppColors.primary),
      trackColor: MaterialStateProperty.resolveWith((states) => AppColors.primary.withOpacity(0.3)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      iconColor: textColor,
      textColor: textColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[900],
    ),
    dividerColor: borderColor,
  );
}

/// Build dark theme
ThemeData buildDarkTheme({String fontSize = 'large'}) {
  return buildAppTheme(themeMode: ThemeMode.dark, fontSize: fontSize);
}

/// Build light theme (default)
ThemeData buildLightTheme({String fontSize = 'large'}) {
  return buildAppTheme(themeMode: ThemeMode.light, fontSize: fontSize);
}


