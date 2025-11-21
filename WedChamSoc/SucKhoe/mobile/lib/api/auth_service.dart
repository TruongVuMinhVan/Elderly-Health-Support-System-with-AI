import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

class LoginSuccess {
  final String accessToken;
  final UserModel user;
  LoginSuccess({required this.accessToken, required this.user});
}

class TwoFactorRequired {
  final String status; // '2fa_required'
  final String tempToken;
  final String? message;
  final String? method; // 'totp' | 'email'
  TwoFactorRequired({required this.status, required this.tempToken, this.message, this.method});
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<UserModel> me() async {
    final data = await _api.get<Map<String, dynamic>>('/auth/me');
    return UserModel.fromJson(data);
  }

  /// Login returning either LoginSuccess or TwoFactorRequired
  Future<Object> login(String email, String password) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/login', body: {
      'email': email,
      'password': password,
    });

    if (data['status'] == '2fa_required' && data['temp_token'] is String) {
      return TwoFactorRequired(
        status: data['status'] as String,
        tempToken: data['temp_token'] as String,
        message: data['message'] as String?,
        method: data['method'] as String?,
      );
    }

    final token = data['access_token'] as String?;
    if (token == null) {
      throw Exception('Invalid login response, missing access_token');
    }
    await _storeToken(token);

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return LoginSuccess(accessToken: token, user: user);
  }

  /// Verify email-based 2FA
  Future<LoginSuccess> verifyEmail2FA(String tempToken, String email, String otp) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/verify-email-2fa', body: {
      'temp_token': tempToken,
      'email': email,
      'otp': otp,
    });

    final token = data['access_token'] as String?;
    if (token == null) {
      throw Exception('Invalid 2FA verify response, missing access_token');
    }
    await _storeToken(token);

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return LoginSuccess(accessToken: token, user: user);
  }

  /// Register user, returns LoginSuccess like the web
  Future<LoginSuccess> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/register', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
    });

    final token = data['access_token'] as String?;
    if (token == null) {
      throw Exception('Invalid register response, missing access_token');
    }
    await _storeToken(token);

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return LoginSuccess(accessToken: token, user: user);
  }
}


