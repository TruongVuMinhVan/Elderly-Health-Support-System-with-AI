import '../models/health.dart';
import 'api_client.dart';

class HealthService {
  HealthService(this._api);

  final ApiClient _api;

  Future<List<HealthRecordModel>> getRecords({
    String? recordType,
    int? limit,
    int? offset,
    String? startDate,
    String? endDate,
  }) async {
    final data = await _api.get<List<dynamic>>('/health/records', query: {
      if (recordType != null) 'record_type': recordType,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
    return data
        .map((e) => HealthRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HealthRecordModel> createRecord(Map<String, dynamic> recordData) async {
    final data = await _api.post<Map<String, dynamic>>('/health/records', body: recordData);
    return HealthRecordModel.fromJson(data);
  }

  Future<HealthRecordModel> getRecord(int id) async {
    final data = await _api.get<Map<String, dynamic>>('/health/records/$id');
    return HealthRecordModel.fromJson(data);
  }

  Future<void> deleteRecord(int id) => _api.delete('/health/records/$id');

  Future<Map<String, dynamic>> getStats(String recordType) async {
    final data = await _api.get<Map<String, dynamic>>('/health/stats/$recordType');
    return data;
  }

  /// Get all health stats in a single API call (optimized)
  Future<Map<String, Map<String, dynamic>>> getAllStats() async {
    final data = await _api.get<Map<String, dynamic>>('/health/stats/all');
    return Map<String, Map<String, dynamic>>.from(
      data.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value))),
    );
  }
}


