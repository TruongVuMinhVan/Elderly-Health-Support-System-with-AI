import 'api_client.dart' show ApiClient;
import 'dart:typed_data';

class TwoFactorService {
  TwoFactorService(this._api);
  final ApiClient _api;

  /// Get 2FA status
  Future<Map<String, dynamic>> getStatus() async {
    return await _api.get<Map<String, dynamic>>('/auth/2fa/status');
  }

  /// Start 2FA setup - returns secret and otpauth_uri
  Future<Map<String, dynamic>> startSetup() async {
    return await _api.post<Map<String, dynamic>>('/auth/2fa/setup-start', body: {});
  }

  /// Get QR code image as bytes
  Future<Uint8List> getQrCodeBytes() async {
    final response = await _api.getRaw('/auth/2fa/qr');
    return response.bodyBytes;
  }

  /// Get QR code image URL (for web display)
  /// Returns the full URL to the QR code endpoint
  String getQrCodeUrl() {
    final baseUrl = ApiClient.apiBaseUrl;
    return '$baseUrl/auth/2fa/qr';
  }

  /// Enable 2FA with verification code
  Future<Map<String, dynamic>> enable(String code) async {
    return await _api.post<Map<String, dynamic>>('/auth/2fa/enable', body: {
      'code': code,
    });
  }

  /// Disable 2FA with verification code
  Future<Map<String, dynamic>> disable(String code) async {
    return await _api.post<Map<String, dynamic>>('/auth/2fa/disable', body: {
      'code': code,
    });
  }

  /// Update preferred 2FA method
  Future<Map<String, dynamic>> updatePreferredMethod(String method) async {
    // Use user settings endpoint
    return await _api.post<Map<String, dynamic>>('/users/me/settings', body: {
      'setting_key': 'preferred_2fa_method',
      'setting_value': method,
    });
  }
}

