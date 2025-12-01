import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/theme.dart';
import '../api/api_client.dart';
import '../api/user_service.dart';

/// Provider để quản lý app settings (theme, font size, language)
/// Settings được lưu theo từng user trên backend và cache local
class AppSettingsProvider extends ChangeNotifier {
  static final AppSettingsProvider _instance = AppSettingsProvider._internal();
  factory AppSettingsProvider() => _instance;
  AppSettingsProvider._internal();

  String _theme = 'light';
  String _fontSize = 'large';
  String _language = 'vi';
  bool _isInitialized = false;
  bool _isLoadingFromBackend = false;
  int? _currentUserId; // Track current user ID to detect user switch

  String get theme => _theme;
  String get fontSize => _fontSize;
  String get language => _language;
  bool get isInitialized => _isInitialized;
  bool get isLoadingFromBackend => _isLoadingFromBackend;

  /// Load settings từ SharedPreferences (local cache)
  /// Sau đó sync từ backend nếu user đã login
  Future<void> loadSettings() async {
    if (_isInitialized && !_shouldReloadForNewUser()) return;

    try {
      // Load from local cache first (for quick startup)
      final prefs = await SharedPreferences.getInstance();
      _theme = prefs.getString('display.theme') ?? 'light';
      _fontSize = prefs.getString('display.fontSize') ?? 'large';
      _language = prefs.getString('display.language') ?? 'vi';
      
      _isInitialized = true;
      notifyListeners();

      // Try to load from backend if user is logged in
      await _loadFromBackend();
    } catch (e) {
      // Use defaults if error
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Check if we should reload settings (e.g., user switched)
  bool _shouldReloadForNewUser() {
    try {
      // Check if user ID changed by checking auth token
      // This is a simple check - in production you might want to store user ID
      return false; // For now, always allow reload
    } catch (e) {
      return false;
    }
  }

  /// Load settings from backend (for current logged-in user)
  Future<void> _loadFromBackend() async {
    try {
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        // User not logged in, use local settings only
        return;
      }

      _isLoadingFromBackend = true;
      notifyListeners();

      final api = ApiClient();
      final userService = UserService(api);
      
      // Get user ID from token or current user
      try {
        final user = await userService.getCurrentUser();
        final userId = user['id'] as int?;
        
        // If user ID changed, we need to reload settings
        if (userId != null && userId != _currentUserId) {
          _currentUserId = userId;
          
          // Load settings from backend
          final settings = await userService.getSettings();
          
          // Convert to map
          final settingsMap = <String, String>{};
          for (var setting in settings) {
            if (setting is Map<String, dynamic>) {
              final key = setting['setting_key'] as String?;
              final value = setting['setting_value'] as String?;
              if (key != null && value != null) {
                settingsMap[key] = value;
              }
            }
          }

          // Update local state if backend has settings
          bool changed = false;
          if (settingsMap.containsKey('display.theme')) {
            final newTheme = settingsMap['display.theme']!;
            if (_theme != newTheme) {
              _theme = newTheme;
              changed = true;
            }
          }
          
          if (settingsMap.containsKey('display.fontSize')) {
            final newFontSize = settingsMap['display.fontSize']!;
            if (_fontSize != newFontSize) {
              _fontSize = newFontSize;
              changed = true;
            }
          }
          
          if (settingsMap.containsKey('display.language')) {
            final newLanguage = settingsMap['display.language']!;
            if (_language != newLanguage) {
              _language = newLanguage;
              changed = true;
            }
          }

          if (changed) {
            // Save to local cache
            await _saveAllSettings();
            // Force notify listeners to rebuild MaterialApp
            notifyListeners();
          } else if (settingsMap.isNotEmpty) {
            // Even if no changes detected, notify to ensure MaterialApp is aware
            // This handles the case where settings match current values but MaterialApp needs to rebuild
            notifyListeners();
          }
        }
      } catch (e) {
        // If error (e.g., token expired), just use local settings
        // Don't throw - we can still use local cache
      }
    } catch (e) {
      // Ignore errors - use local settings
    } finally {
      _isLoadingFromBackend = false;
      // Always notify at the end to ensure UI is updated
      notifyListeners();
    }
  }

  /// Force reload settings from backend (e.g., after login)
  Future<void> reloadFromBackend() async {
    _currentUserId = null; // Reset to force reload
    _isLoadingFromBackend = true;
    notifyListeners(); // Notify immediately to show loading state
    await _loadFromBackend();
    // Final notify to ensure MaterialApp rebuilds with new settings
    notifyListeners();
  }

  /// Clear settings when user logs out - reset to default values
  Future<void> clearUserSettings() async {
    _currentUserId = null;
    
    // Reset to default values
    final defaultTheme = 'light';
    final defaultFontSize = 'large';
    final defaultLanguage = 'vi';
    
    bool changed = false;
    
    if (_theme != defaultTheme) {
      _theme = defaultTheme;
      changed = true;
    }
    
    if (_fontSize != defaultFontSize) {
      _fontSize = defaultFontSize;
      changed = true;
    }
    
    if (_language != defaultLanguage) {
      _language = defaultLanguage;
      changed = true;
    }
    
    // Save default values to local cache
    if (changed) {
      await _saveAllSettings();
      // Force notify listeners to rebuild MaterialApp
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

  /// Save setting to SharedPreferences (local cache) and backend
  Future<void> _saveSetting(String key, String value) async {
    try {
      // Save to local cache first (for offline support)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      
      // Try to save to backend if user is logged in
      await _saveToBackend(key, value);
    } catch (e) {
      // Ignore errors - local save succeeded
    }
  }

  /// Save setting to backend
  Future<void> _saveToBackend(String key, String value) async {
    try {
      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        // User not logged in, skip backend save
        return;
      }

      final api = ApiClient();
      final userService = UserService(api);
      
      // Save to backend
      await userService.updateSetting(key, value);
    } catch (e) {
      // Ignore errors - local save already succeeded
      // Settings will be synced next time user logs in
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

