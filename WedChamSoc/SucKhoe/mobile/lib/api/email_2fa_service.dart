import 'api_client.dart' show ApiClient;

class Email2FAService {
  Email2FAService(this._api);
  final ApiClient _api;

  /// Send OTP to email
  Future<Map<String, dynamic>> sendOtp(String email) async {
    return await _api.post<Map<String, dynamic>>('/auth/2fa/email/send-otp', body: {
      'email': email,
    });
  }

  /// Enable Email 2FA with OTP code
  Future<Map<String, dynamic>> enable(String otp) async {
    return await _api.post<Map<String, dynamic>>('/auth/2fa/email/enable', body: {
      'otp': otp,
    });
  }

  /// Disable Email 2FA
  Future<Map<String, dynamic>> disable() async {
    return await _api.post<Map<String, dynamic>>('/auth/2fa/email/disable', body: {});
  }

  /// Get Email 2FA status
  Future<Map<String, dynamic>> getStatus() async {
    return await _api.get<Map<String, dynamic>>('/auth/2fa/email/status');
  }
}

