import '../models/schedule.dart';
import 'api_client.dart';

class SchedulesService {
  SchedulesService(this._api);

  final ApiClient _api;

  Future<List<ScheduleModel>> getSchedules({
    String? scheduleType,
    bool? upcomingOnly,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    final data = await _api.get<List<dynamic>>('/schedules', query: {
      if (scheduleType != null) 'schedule_type': scheduleType,
      if (upcomingOnly != null) 'upcoming_only': upcomingOnly,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    });
    return data
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    final data = await _api.post<Map<String, dynamic>>('/schedules', body: schedule.toJson());
    return ScheduleModel.fromJson(data);
  }

  Future<List<ScheduleModel>> getTodaySchedules() async {
    final data = await _api.get<List<dynamic>>('/schedules/today');
    return data
        .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleModel> getSchedule(int id) async {
    final data = await _api.get<Map<String, dynamic>>('/schedules/$id');
    return ScheduleModel.fromJson(data);
  }

  Future<ScheduleModel> updateSchedule(int id, Map<String, dynamic> partial) async {
    final data = await _api.put<Map<String, dynamic>>('/schedules/$id', body: partial);
    return ScheduleModel.fromJson(data);
  }

  Future<void> deleteSchedule(int id) => _api.delete('/schedules/$id');
}


