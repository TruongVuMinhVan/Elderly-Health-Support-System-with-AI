import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/schedules_service.dart';
import '../api/medications_service.dart';
import '../api/user_service.dart';
import '../models/schedule.dart';
import '../models/medication.dart';
import 'notification_service.dart';
import '../api/api_client.dart' show TokenExpiredException;

// Helper để chạy async function mà không cần await
void unawaited(Future<void> future) {
  // Ignore errors - they will be handled in the future
}

/// Service để sync reminders từ API và schedule local notifications
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final NotificationService _notificationService = NotificationService();
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  // Cache API clients để tránh tạo mới mỗi lần
  ApiClient? _cachedApiClient;
  SchedulesService? _cachedSchedulesService;
  MedicationsService? _cachedMedicationsService;
  UserService? _cachedUserService;

  /// Khởi tạo reminder service
  Future<void> initialize() async {
    await _notificationService.initialize();
    // Chạy sync ban đầu trong background (không block UI)
    syncReminders();
    
    // Sync reminders mỗi 30 phút (tăng từ 15 lên 30 để giảm tải)
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      syncReminders();
    });
  }

  /// Sync reminders từ API và schedule local notifications
  /// Chạy async trong background để không block main thread
  Future<void> syncReminders() async {
    if (_isSyncing) return;
    
    // Chạy trong background để không block UI
    unawaited(_syncRemindersInternal());
  }
  
  Future<void> _syncRemindersInternal() async {
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
        _isSyncing = false;
        return;
      }

      // Sử dụng cached API clients
      _cachedApiClient ??= ApiClient();
      _cachedSchedulesService ??= SchedulesService(_cachedApiClient!);
      _cachedMedicationsService ??= MedicationsService(_cachedApiClient!);
      
      final schedulesService = _cachedSchedulesService!;
      final medicationsService = _cachedMedicationsService!;

      // Get upcoming schedules
      final schedules = await schedulesService.getSchedules(
        upcomingOnly: true,
        limit: 50,
      );

      // Get active medications
      final medications = await medicationsService.getMedications();

      // Get advance minutes setting (từ SharedPreferences, backend, hoặc default)
      int advanceMinutes = 30; // Default
      final advanceMinutesStr = prefs.getString('reminders.advanceMinutes');
      
      if (advanceMinutesStr != null) {
        advanceMinutes = int.tryParse(advanceMinutesStr) ?? 30;
      } else {
        // Nếu không có trong SharedPreferences, thử load từ backend (chỉ một lần)
        try {
          _cachedUserService ??= UserService(_cachedApiClient!);
          final settings = await _cachedUserService!.getSettings();
          
          for (final setting in settings) {
            if (setting is Map<String, dynamic>) {
              final key = setting['setting_key'] as String?;
              final value = setting['setting_value'] as String?;
              if (key == 'reminders.advanceMinutes' && value != null) {
                advanceMinutes = int.tryParse(value) ?? 30;
                // Lưu vào SharedPreferences để lần sau không cần query backend
                await prefs.setString('reminders.advanceMinutes', value);
                break;
              }
            }
          }
        } catch (e) {
          // Nếu không load được từ backend, dùng default
        }
      }

      // Cancel old notifications
      await _notificationService.cancelAllScheduleReminders();
      await _notificationService.cancelAllMedicationReminders();

      // Schedule notifications cho schedules
      // Loại bỏ print statements để giảm I/O overhead
      int scheduledCount = 0;
      
      for (final schedule in schedules) {
        try {
          final scheduledTime = DateTime.parse(schedule.scheduledDatetime);
          
          // Chỉ schedule nếu chưa completed và trong tương lai
          if (!schedule.isCompleted && scheduledTime.isAfter(DateTime.now())) {
            // scheduleAppointmentReminder will handle errors internally and retry with inexact mode
            await _notificationService.scheduleAppointmentReminder(
              scheduleId: schedule.id,
              title: schedule.title,
              scheduledTime: scheduledTime,
              location: schedule.location,
              doctorName: schedule.doctorName,
              advanceMinutes: advanceMinutes,
            );
            scheduledCount++;
          }
        } catch (e) {
          // Continue with next schedule - errors are handled internally
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
      // Silently handle errors để không block UI
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

