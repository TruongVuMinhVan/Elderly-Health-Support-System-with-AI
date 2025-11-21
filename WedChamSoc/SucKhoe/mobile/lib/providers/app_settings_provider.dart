import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/theme.dart';

/// Provider để quản lý app settings (theme, font size, language)
class AppSettingsProvider extends ChangeNotifier {
  static final AppSettingsProvider _instance = AppSettingsProvider._internal();
  factory AppSettingsProvider() => _instance;
  AppSettingsProvider._internal();

  String _theme = 'light';
  String _fontSize = 'large';
  String _language = 'vi';
  bool _isInitialized = false;

  String get theme => _theme;
  String get fontSize => _fontSize;
  String get language => _language;
  bool get isInitialized => _isInitialized;

  /// Load settings từ SharedPreferences
  Future<void> loadSettings() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _theme = prefs.getString('display.theme') ?? 'light';
      _fontSize = prefs.getString('display.fontSize') ?? 'large';
      _language = prefs.getString('display.language') ?? 'vi';
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Use defaults
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Update theme
  Future<void> setTheme(String theme) async {
    if (_theme == theme) return;
    
    _theme = theme;
    await _saveSetting('display.theme', theme);
    notifyListeners();
  }

  /// Update font size
  Future<void> setFontSize(String fontSize) async {
    if (_fontSize == fontSize) return;
    
    _fontSize = fontSize;
    await _saveSetting('display.fontSize', fontSize);
    notifyListeners();
  }

  /// Update language
  Future<void> setLanguage(String language) async {
    if (_language == language) return;
    
    _language = language;
    await _saveSetting('display.language', language);
    notifyListeners();
  }

  /// Sync settings từ backend (khi user thay đổi trong settings screen)
  Future<void> syncFromBackend(Map<String, String> settingsMap) async {
    final newTheme = settingsMap['display.theme'] ?? _theme;
    final newFontSize = settingsMap['display.fontSize'] ?? _fontSize;
    final newLanguage = settingsMap['display.language'] ?? _language;

    bool changed = false;

    if (_theme != newTheme) {
      _theme = newTheme;
      changed = true;
    }

    if (_fontSize != newFontSize) {
      _fontSize = newFontSize;
      changed = true;
    }

    if (_language != newLanguage) {
      _language = newLanguage;
      changed = true;
    }

    if (changed) {
      await _saveAllSettings();
      notifyListeners();
    }
  }

  /// Save setting to SharedPreferences
  Future<void> _saveSetting(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Save all settings to SharedPreferences
  Future<void> _saveAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('display.theme', _theme);
      await prefs.setString('display.fontSize', _fontSize);
      await prefs.setString('display.language', _language);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get theme mode
  ThemeMode getThemeMode() {
    switch (_theme) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'auto':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  /// Get text scale factor based on font size
  double getTextScaleFactor() {
    switch (_fontSize) {
      case 'small':
        return 0.85;
      case 'medium':
        return 1.0;
      case 'large':
        return 1.15;
      case 'extra-large':
        return 1.3;
      default:
        return 1.0;
    }
  }
}

