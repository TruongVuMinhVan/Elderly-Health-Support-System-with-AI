import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class QuickScanService {
  QuickScanService(this._api);

  final ApiClient _api;

  /// Quick Scan - không cần đăng nhập
  /// Upload image và nhận kết quả ngay lập tức (không lưu vào database)
  Future<QuickScanResult> quickScan(File imageFile) async {
    final baseUrl = ApiClient.apiBaseUrl;
    final url = Uri.parse('$baseUrl/skin-disease/quick-scan');

    final request = http.MultipartRequest('POST', url);
    
    // Không cần authorization header (public endpoint)
    
    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return QuickScanResult.fromJson(jsonData);
    } else {
      // Try to extract error message
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final detail = errorBody['detail'] as String?;
        throw Exception(detail ?? 'Lỗi quét nhanh: ${response.statusCode}');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Lỗi quét nhanh: ${response.statusCode}');
      }
    }
  }
}

class QuickScanResult {
  final int? id;
  final int? userId;
  final String? imagePath;
  final Map<String, dynamic>? predictedDisease;
  final String? predictedDiseaseName;
  final double? confidence;
  final String? createdAt;
  final List<Map<String, dynamic>>? topPredictions;
  final String? severity;
  final bool requiresLogin;

  QuickScanResult({
    this.id,
    this.userId,
    this.imagePath,
    this.predictedDisease,
    this.predictedDiseaseName,
    this.confidence,
    this.createdAt,
    this.topPredictions,
    this.severity,
    this.requiresLogin = false,
  });

  factory QuickScanResult.fromJson(Map<String, dynamic> json) {
    return QuickScanResult(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      imagePath: json['image_path'] as String?,
      predictedDisease: json['predicted_disease'] as Map<String, dynamic>?,
      predictedDiseaseName: json['predicted_disease_name'] as String?,
      confidence: json['confidence'] != null 
          ? (json['confidence'] as num).toDouble() 
          : null,
      createdAt: json['created_at'] as String?,
      topPredictions: json['top_predictions'] != null
          ? (json['top_predictions'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : null,
      severity: json['severity'] as String?,
      requiresLogin: json['requires_login'] as bool? ?? false,
    );
  }
}

