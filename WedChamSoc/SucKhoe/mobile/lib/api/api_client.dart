import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Exception thrown when token has expired (401 Unauthorized)
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  @override
  String toString() => message;
}

/// Exception thrown when resource is not found (404 Not Found)
class NotFoundException implements Exception {
  final String message;
  final int statusCode;
  NotFoundException(this.message, this.statusCode);
  @override
  String toString() => message;
}

/// Centralized API client mirroring the web frontend's axios setup.
/// - Adds Authorization header from stored token
/// - Provides typed request helpers
/// - Handles 401 by clearing token and throwing TokenExpiredException
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Configure API base URL similar to NEXT_PUBLIC_API_BASE_URL
  /// You can override this at runtime using --dart-define=API_BASE_URL=...
  static String get apiBaseUrl {
    // Allow override via --dart-define=API_BASE_URL=http://host:8000/api
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // On Android emulators, host machine is 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }

    // iOS simulator and web can use localhost
    return 'http://localhost:8000/api';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Clear stored auth token (used when 401 is received)
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<Map<String, String>> _headers({Map<String, String>? extra}) async {
    final token = await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  T _decodeJson<T>(String body) {
    final decoded = json.decode(body);
    return decoded as T;
  }

  Exception _makeHttpException(http.Response res) {
    if (res.statusCode == 404) {
      return NotFoundException(
        'Resource not found: ${res.request?.url}',
        res.statusCode,
      );
    }
    return Exception('HTTP ${res.statusCode} ${res.request?.method} ${res.request?.url}: ${res.body}');
  }

  /// Handle 401 Unauthorized: clear token and throw TokenExpiredException
  Future<void> _handleUnauthorized() async {
    await _clearToken();
    throw TokenExpiredException('Token has expired. Please login again.');
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    final response = await _client.get(_uri(path, query), headers: await _headers());
    if (response.statusCode == 401) {
      await _handleUnauthorized();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeJson<T>(response.body);
    }
    throw _makeHttpException(response);
  }

  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query}) async {
    final response = await _client.post(
      _uri(path, query),
      headers: await _headers(),
      body: body == null ? null : json.encode(body),
    );
    // Only treat 401 as token expired if we have a token (authenticated request)
    // For login/register endpoints, 401 means invalid credentials
    if (response.statusCode == 401) {
      final hasToken = await _getToken() != null;
      final isAuthEndpoint = path.contains('/auth/login') || path.contains('/auth/register');
      if (hasToken && !isAuthEndpoint) {
        await _handleUnauthorized();
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeJson<T>(response.body);
    }
    // Try to extract error message from response body
    try {
      final errorBody = _decodeJson<Map<String, dynamic>>(response.body);
      final detail = errorBody['detail'] as String?;
      if (detail != null) {
        throw Exception(detail);
      }
    } catch (_) {
      // If parsing fails, use default exception
    }
    throw _makeHttpException(response);
  }

  Future<T> put<T>(String path, {Object? body, Map<String, dynamic>? query}) async {
    final response = await _client.put(
      _uri(path, query),
      headers: await _headers(),
      body: body == null ? null : json.encode(body),
    );
    if (response.statusCode == 401) {
      await _handleUnauthorized();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decodeJson<T>(response.body);
    }
    throw _makeHttpException(response);
  }

  Future<void> delete(String path, {Map<String, dynamic>? query}) async {
    final response = await _client.delete(_uri(path, query), headers: await _headers());
    if (response.statusCode == 401) {
      await _handleUnauthorized();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw _makeHttpException(response);
  }

  /// Get raw response (for binary data like images)
  Future<http.Response> getRaw(String path, {Map<String, dynamic>? query}) async {
    final headers = await _headers();
    // Remove Content-Type for image requests
    headers.remove('Content-Type');
    final response = await _client.get(_uri(path, query), headers: headers);
    if (response.statusCode == 401) {
      await _handleUnauthorized();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw _makeHttpException(response);
  }
}


