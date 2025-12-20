import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../../api/api_client.dart';
import '../../api/user_service.dart';
import '../../api/two_factor_service.dart';
import '../../api/email_2fa_service.dart';
import '../../widgets/settings/notifications_section.dart';
import '../../widgets/settings/display_section.dart';
import '../../widgets/settings/reminders_section.dart';
import '../../widgets/settings/privacy_section.dart';
import '../../widgets/settings/two_factor_section.dart';
import '../../services/notification_service.dart';
import '../../services/reminder_service.dart';
import '../../providers/app_settings_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  bool _notifEmail = true;
  bool _notifPush = true;
  bool _notifSms = false;
  String _fontSize = 'large';
  String _theme = 'light';
  String _language = 'vi';
  bool _shareData = false;
  bool _analytics = true;
  int _advanceMinutes = 30;
  bool _sound = true;

  // 2FA state
  bool _twoFactorEnabled = false;
  bool _emailOtpEnabled = false;
  String? _preferred2FAMethod;
  
  // TOTP 2FA setup state
  bool _totpSettingUp = false;
  String? _totpSecret;
  String _totpVerificationCode = '';
  List<String> _backupCodes = [];
  bool _showBackupCodes = false;
  Uint8List? _qrCodeBytes;

  // Email 2FA setup state
  bool _email2FASettingUp = false;
  String _email2FAOtpCode = '';
  bool _isSendingOtp = false;

  // Services
  late final UserService _userService;
  late final TwoFactorService _twoFactorService;
  late final Email2FAService _email2FAService;
  
  // UI state
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _saveSuccess = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _userService = UserService(apiClient);
    _twoFactorService = TwoFactorService(apiClient);
    _email2FAService = Email2FAService(apiClient);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadSettings(),
        _load2FAStatus(),
        _loadCurrentUser(),
      ]);
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải cài đặt: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _userService.getSettings();
      final settingsMap = <String, String>{};
      
      for (final s in settings) {
        if (s is Map<String, dynamic>) {
          settingsMap[s['setting_key']] = s['setting_value']?.toString() ?? '';
        }
      }

      if (mounted) {
        setState(() {
          _notifEmail = settingsMap['notifications.email'] == 'true';
          _notifPush = settingsMap['notifications.push'] == 'true';
          _notifSms = settingsMap['notifications.sms'] == 'true';
          _fontSize = settingsMap['display.fontSize'] ?? 'large';
          _theme = settingsMap['display.theme'] ?? 'light';
          _language = settingsMap['display.language'] ?? 'vi';
          _shareData = settingsMap['privacy.shareData'] == 'true';
          _analytics = settingsMap['privacy.analytics'] != 'false';
          _advanceMinutes = int.tryParse(settingsMap['reminders.advanceMinutes'] ?? '30') ?? 30;
          _sound = settingsMap['reminders.sound'] != 'false';
        });
        
        // Sync với AppSettingsProvider để áp dụng ngay lập tức
        AppSettingsProvider().syncFromBackend(settingsMap);
      }
    } catch (e) {
    }
  }

  Future<void> _load2FAStatus() async {
    try {
      final status = await _twoFactorService.getStatus();
      if (mounted) {
        setState(() {
          _twoFactorEnabled = status['two_factor_enabled'] == true;
          _emailOtpEnabled = status['email_otp_enabled'] == true;
          _preferred2FAMethod = status['preferred_2fa_method']?.toString();
        });
      }
    } catch (e) {
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _handleSettingChange(String category, String key, dynamic value) async {
    final settingKey = '$category.$key';
    final settingValue = value.toString();

    try {
      // Lưu vào backend
      await _userService.updateSetting(settingKey, settingValue);
      
      // Lưu vào SharedPreferences để ReminderService có thể đọc ngay
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(settingKey, settingValue);
      
      // Update AppSettingsProvider if it's a display setting
      if (category == 'display') {
        final settingsProvider = AppSettingsProvider();
        switch (key) {
          case 'theme':
            await settingsProvider.setTheme(settingValue);
            break;
          case 'fontSize':
            await settingsProvider.setFontSize(settingValue);
            break;
          case 'language':
            await settingsProvider.setLanguage(settingValue);
            break;
        }
      }
      
      // Nếu là notification settings, cập nhật notification service
      if (category == 'notifications' && key == 'push') {
        await NotificationService().setNotificationEnabled(value as bool);
        if (value as bool) {
          // Nếu bật lại, sync reminders
          await ReminderService().forceSync();
        }
      }
      
      // Nếu là reminder settings, sync lại reminders ngay lập tức
      if (category == 'reminders') {
        // Force sync để áp dụng setting mới ngay lập tức
        await ReminderService().forceSync();
      }
      
      if (mounted) {
        setState(() {
          _saveSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveSuccess = false);
          }
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể lưu cài đặt';
      });
      await _loadSettings();
    }
  }

  // TOTP 2FA methods
  Future<void> _startTOTPSetup() async {
    try {
      setState(() {
        _totpSettingUp = true;
        _error = null;
      });

      final data = await _twoFactorService.startSetup();
      final qrBytes = await _twoFactorService.getQrCodeBytes();

      if (mounted) {
        setState(() {
          _totpSecret = data['secret'];
          _qrCodeBytes = qrBytes;
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể bắt đầu thiết lập 2FA';
        _totpSettingUp = false;
      });
    }
  }

  Future<void> _enableTOTP() async {
    if (_totpVerificationCode.length != 6) return;

    try {
      final data = await _twoFactorService.enable(_totpVerificationCode);
      
      if (mounted) {
        setState(() {
          _twoFactorEnabled = true;
          _backupCodes = List<String>.from(data['backup_codes'] ?? []);
          _showBackupCodes = true;
          _totpSettingUp = false;
          _totpVerificationCode = '';
          _saveSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveSuccess = false);
          }
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Mã xác thực không đúng';
      });
    }
  }

  Future<void> _disableTOTP() async {
    if (_totpVerificationCode.length != 6) return;

    try {
      await _twoFactorService.disable(_totpVerificationCode);
      
      if (mounted) {
        setState(() {
          _twoFactorEnabled = false;
          _totpVerificationCode = '';
          _saveSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveSuccess = false);
          }
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Mã xác thực không đúng';
      });
    }
  }

  // Email 2FA methods
  Future<void> _startEmail2FASetup() async {
    if (_currentUser?['email'] == null) {
      setState(() => _error = 'Không tìm thấy email người dùng');
      return;
    }

    try {
      setState(() {
        _isSendingOtp = true;
        _error = null;
      });

      await _email2FAService.sendOtp(_currentUser!['email']);
      
      if (mounted) {
        setState(() {
          _email2FASettingUp = true;
          _isSendingOtp = false;
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể gửi mã OTP';
        _isSendingOtp = false;
      });
    }
  }

  Future<void> _enableEmail2FA() async {
    if (_email2FAOtpCode.length != 6) return;

    try {
      await _email2FAService.enable(_email2FAOtpCode);
      
      if (mounted) {
        setState(() {
          _emailOtpEnabled = true;
          _email2FASettingUp = false;
          _email2FAOtpCode = '';
          _saveSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveSuccess = false);
          }
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Mã OTP không đúng';
      });
    }
  }

  Future<void> _disableEmail2FA() async {
    try {
      await _email2FAService.disable();
      
      if (mounted) {
        setState(() {
          _emailOtpEnabled = false;
          _saveSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveSuccess = false);
          }
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tắt email 2FA';
      });
    }
  }

  Future<void> _updatePreferred2FAMethod(String method) async {
    try {
      await _twoFactorService.updatePreferredMethod(method);
      
      if (mounted) {
        setState(() {
          _preferred2FAMethod = method;
          _saveSuccess = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _saveSuccess = false);
          }
        });
      }
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể cập nhật phương thức 2FA';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Error message
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[800], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[800], fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadAll,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),

            // Success message
            if (_saveSuccess)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Đã lưu cài đặt thành công!',
                      style: TextStyle(color: Colors.green[800], fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Notification Settings
            NotificationsSection(
              email: _notifEmail,
              push: _notifPush,
              sms: _notifSms,
              onEmailChanged: (v) {
                setState(() => _notifEmail = v);
                _handleSettingChange('notifications', 'email', v);
              },
              onPushChanged: (v) {
                setState(() => _notifPush = v);
                _handleSettingChange('notifications', 'push', v);
              },
              onSmsChanged: (v) {
                setState(() => _notifSms = v);
                _handleSettingChange('notifications', 'sms', v);
              },
            ),

            const SizedBox(height: 16),

            // Display Settings
            DisplaySection(
              fontSize: _fontSize,
              theme: _theme,
              language: _language,
              onFontSizeChanged: (v) async {
                setState(() => _fontSize = v);
                await _handleSettingChange('display', 'fontSize', v);
                // Áp dụng ngay lập tức
                await AppSettingsProvider().setFontSize(v);
              },
              onThemeChanged: (v) async {
                setState(() => _theme = v);
                await _handleSettingChange('display', 'theme', v);
                // Áp dụng ngay lập tức
                await AppSettingsProvider().setTheme(v);
              },
              onLanguageChanged: (v) async {
                setState(() => _language = v);
                await _handleSettingChange('display', 'language', v);
                // Áp dụng ngay lập tức
                await AppSettingsProvider().setLanguage(v);
              },
            ),

            const SizedBox(height: 16),

            // Reminder Settings
            RemindersSection(
              advanceMinutes: _advanceMinutes,
              sound: _sound,
              onAdvanceMinutesChanged: (v) {
                setState(() => _advanceMinutes = v);
                _handleSettingChange('reminders', 'advanceMinutes', v);
              },
              onSoundChanged: (v) {
                setState(() => _sound = v);
                _handleSettingChange('reminders', 'sound', v);
              },
            ),

            const SizedBox(height: 16),

            // Privacy Settings
            PrivacySection(
              shareData: _shareData,
              analytics: _analytics,
              onShareDataChanged: (v) {
                setState(() => _shareData = v);
                _handleSettingChange('privacy', 'shareData', v);
              },
              onAnalyticsChanged: (v) {
                setState(() => _analytics = v);
                _handleSettingChange('privacy', 'analytics', v);
              },
            ),

            const SizedBox(height: 16),

            // 2FA Settings
            TwoFactorSection(
              twoFactorEnabled: _twoFactorEnabled,
              emailOtpEnabled: _emailOtpEnabled,
              preferredMethod: _preferred2FAMethod,
              totpSettingUp: _totpSettingUp,
              totpSecret: _totpSecret,
              qrCodeBytes: _qrCodeBytes,
              totpVerificationCode: _totpVerificationCode,
              email2FASettingUp: _email2FASettingUp,
              email2FAOtpCode: _email2FAOtpCode,
              isSendingOtp: _isSendingOtp,
              onPreferredMethodChanged: _updatePreferred2FAMethod,
              onTOTPToggle: () {
                if (!_twoFactorEnabled) {
                  _startTOTPSetup();
                } else {
                  setState(() => _totpVerificationCode = '');
                }
              },
              onEmail2FAToggle: () {
                if (!_emailOtpEnabled) {
                  _startEmail2FASetup();
                } else {
                  _disableEmail2FA();
                }
              },
              onTOTPVerificationCodeChanged: (v) {
                setState(() => _totpVerificationCode = v);
              },
              onEnableTOTP: _enableTOTP,
              onDisableTOTP: _disableTOTP,
              onEmail2FAOtpCodeChanged: (v) {
                setState(() => _email2FAOtpCode = v);
              },
              onEnableEmail2FA: _enableEmail2FA,
              onDisableEmail2FA: _disableEmail2FA,
              onResendEmail2FA: _startEmail2FASetup,
              onCancelTOTPSetup: () {
                setState(() {
                  _totpSettingUp = false;
                  _totpSecret = null;
                  _qrCodeBytes = null;
                  _totpVerificationCode = '';
                });
              },
              onCancelEmail2FASetup: () {
                setState(() {
                  _email2FASettingUp = false;
                  _email2FAOtpCode = '';
                });
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
