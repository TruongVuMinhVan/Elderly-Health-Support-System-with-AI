import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/schedules_service.dart';
import '../api/medications_service.dart';
import '../models/schedule.dart';
import '../models/medication.dart';
import 'notification_service.dart';
import '../api/api_client.dart' show TokenExpiredException;

/// Service để sync reminders từ API và schedule local notifications
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final NotificationService _notificationService = NotificationService();
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Khởi tạo reminder service
  Future<void> initialize() async {
    await _notificationService.initialize();
    await syncReminders();
    
    // Sync reminders mỗi 15 phút
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      syncReminders();
    });
  }

  /// Sync reminders từ API và schedule local notifications
  Future<void> syncReminders() async {
    if (_isSyncing) return;
    
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications.enabled') ?? true;
    
    if (!notificationsEnabled) {
      return;
    }

    _isSyncing = true;

    try {
      // Check if user is logged in
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        return;
      }

      final apiClient = ApiClient();
      final schedulesService = SchedulesService(apiClient);
      final medicationsService = MedicationsService(apiClient);

      // Get upcoming schedules
      final schedules = await schedulesService.getSchedules(
        upcomingOnly: true,
        limit: 50,
      );

      // Get active medications
      final medications = await medicationsService.getMedications();

      // Get advance minutes setting (từ user settings hoặc default)
      final advanceMinutesStr = prefs.getString('reminders.advanceMinutes');
      final advanceMinutes = advanceMinutesStr != null 
          ? int.tryParse(advanceMinutesStr) ?? 30
          : 30;

      // Cancel old notifications
      await _notificationService.cancelAllScheduleReminders();
      await _notificationService.cancelAllMedicationReminders();

      // Schedule notifications cho schedules
      for (final schedule in schedules) {
        try {
          final scheduledTime = DateTime.parse(schedule.scheduledDatetime);
          
          // Chỉ schedule nếu chưa completed và trong tương lai
          if (!schedule.isCompleted && scheduledTime.isAfter(DateTime.now())) {
            await _notificationService.scheduleAppointmentReminder(
              scheduleId: schedule.id,
              title: schedule.title,
              scheduledTime: scheduledTime,
              location: schedule.location,
              doctorName: schedule.doctorName,
              advanceMinutes: advanceMinutes,
            );
          }
        } catch (e) {
          // Skip invalid schedules
        }
      }

      // Schedule notifications cho medications
      for (final medication in medications) {
        if (medication.isActive) {
          try {
            // Tạo reminders cho medication dựa trên frequency
            // Đây là logic đơn giản, có thể cải thiện
            final now = DateTime.now();
            final startDate = medication.startDate != null
                ? DateTime.parse(medication.startDate!)
                : now;
            
            if (medication.endDate != null) {
              final endDate = DateTime.parse(medication.endDate!);
              if (endDate.isBefore(now)) {
                continue; // Medication đã hết hạn
              }
            }

            // Parse frequency để tạo reminders
            // Ví dụ: "2 times daily" -> 2 lần/ngày
            final frequency = medication.frequency?.toLowerCase() ?? '';
            int timesPerDay = 2; // Default
            
            if (frequency.contains('once') || frequency.contains('1')) {
              timesPerDay = 1;
            } else if (frequency.contains('twice') || frequency.contains('2')) {
              timesPerDay = 2;
            } else if (frequency.contains('three') || frequency.contains('3')) {
              timesPerDay = 3;
            }

            // Tạo reminders cho hôm nay và 7 ngày tiếp theo
            for (int day = 0; day < 7; day++) {
              final targetDate = now.add(Duration(days: day));
              
              if (targetDate.isBefore(startDate)) continue;
              if (medication.endDate != null &&
                  targetDate.isAfter(DateTime.parse(medication.endDate!))) {
                break;
              }

              // Schedule cho mỗi lần uống trong ngày
              for (int time = 0; time < timesPerDay; time++) {
                final hour = 8 + (time * 6); // 8h, 14h, 20h
                final scheduledTime = DateTime(
                  targetDate.year,
                  targetDate.month,
                  targetDate.day,
                  hour,
                  0,
                );

                if (scheduledTime.isAfter(now)) {
                  await _notificationService.scheduleMedicationReminder(
                    medicationId: medication.id,
                    medicationName: medication.medicationName,
                    dosage: medication.dosage ?? '',
                    scheduledTime: scheduledTime,
                    advanceMinutes: advanceMinutes,
                  );
                }
              }
            }
          } catch (e) {
            // Skip invalid medications
          }
        }
      }
    } on TokenExpiredException {
      // Token expired, không sync
      _isSyncing = false;
      return;
    } catch (e) {
      // Error syncing, sẽ retry ở lần sau
      // Có thể log error ở đây nếu cần
    } finally {
      _isSyncing = false;
    }
  }

  /// Stop reminder service
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Force sync reminders ngay lập tức
  Future<void> forceSync() async {
    await syncReminders();
  }
}

