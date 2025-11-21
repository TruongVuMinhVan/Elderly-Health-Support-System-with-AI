import 'api_client.dart' show ApiClient, NotFoundException;

class UserService {
  UserService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _api.get<Map<String, dynamic>>('/users/me');
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    return await _api.put<Map<String, dynamic>>('/users/me', body: userData);
  }

  Future<Map<String, dynamic>> getHealthProfile() async {
    return await _api.get<Map<String, dynamic>>('/users/me/health-profile');
  }

  /// Get health profile or return null if not found (404)
  Future<Map<String, dynamic>?> getHealthProfileOrNull() async {
    try {
      return await _api.get<Map<String, dynamic>>('/users/me/health-profile');
    } on NotFoundException {
      // Health profile doesn't exist yet, that's normal for new users
      return null;
    } catch (e) {
      // Re-throw other errors
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createHealthProfile(Map<String, dynamic> data) async {
    return await _api.post<Map<String, dynamic>>('/users/me/health-profile', body: data);
  }

  Future<Map<String, dynamic>> updateHealthProfile(Map<String, dynamic> data) async {
    return await _api.put<Map<String, dynamic>>('/users/me/health-profile', body: data);
  }

  Future<List<dynamic>> getSettings() async {
    return await _api.get<List<dynamic>>('/users/me/settings');
  }

  Future<Map<String, dynamic>> updateSetting(String key, String value) async {
    return await _api.post<Map<String, dynamic>>('/users/me/settings', body: {
      'setting_key': key,
      'setting_value': value,
    });
  }
}


