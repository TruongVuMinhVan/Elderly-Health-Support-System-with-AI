import '../models/medication.dart';
import 'api_client.dart';

class MedicationsService {
  MedicationsService(this._api);

  final ApiClient _api;

  Future<List<MedicationModel>> getMedications({bool activeOnly = true}) async {
    final data = await _api.get<List<dynamic>>('/medications', query: {
      'active_only': activeOnly,
    });
    return data
        .map((e) => MedicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MedicationModel> createMedication(Map<String, dynamic> medicationData) async {
    final data = await _api.post<Map<String, dynamic>>('/medications', body: medicationData);
    return MedicationModel.fromJson(data);
  }

  Future<MedicationModel> getMedication(int id) async {
    final data = await _api.get<Map<String, dynamic>>('/medications/$id');
    return MedicationModel.fromJson(data);
  }

  Future<MedicationModel> updateMedication(int id, Map<String, dynamic> partial) async {
    final data = await _api.put<Map<String, dynamic>>('/medications/$id', body: partial);
    return MedicationModel.fromJson(data);
  }

  Future<void> deleteMedication(int id) => _api.delete('/medications/$id');
}


