import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skin_disease.dart';
import 'api_client.dart';

class SkinDiseaseService {
  SkinDiseaseService(this._api);

  final ApiClient _api;

  Future<List<SkinDiseaseModel>> getAllDiseases() async {
    final data = await _api.get<List<dynamic>>('/skin-disease/diseases');
    return data
        .map((e) => SkinDiseaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SkinDiseaseModel> getDisease(int id) async {
    final data = await _api.get<Map<String, dynamic>>('/skin-disease/diseases/$id');
    return SkinDiseaseModel.fromJson(data);
  }

  /// Upload image and get prediction (using test endpoint that doesn't require auth)
  /// Returns PredictionResultModel with full prediction data including top predictions
  Future<PredictionResultModel> predictDisease(File imageFile, {bool useTestEndpoint = true}) async {
    final baseUrl = ApiClient.apiBaseUrl;
    // Use test endpoint by default (no auth required)
    final endpoint = useTestEndpoint ? '/skin-disease/predict/test' : '/skin-disease/predict';
    final url = Uri.parse('$baseUrl$endpoint');

    final request = http.MultipartRequest('POST', url);
    
    // Add authorization header only if not using test endpoint
    if (!useTestEndpoint) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // Add image file
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return PredictionResultModel.fromJson(jsonData);
    } else {
      // Try to extract error message
      try {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final detail = errorBody['detail'] as String?;
        throw Exception(detail ?? 'Lỗi dự đoán: ${response.statusCode}');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Lỗi dự đoán: ${response.statusCode}');
      }
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}

