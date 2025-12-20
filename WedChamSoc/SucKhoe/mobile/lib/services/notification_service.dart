import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Service để quản lý local notifications trên mobile
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool? _hasExactAlarmPermission; // Cache permission status

  /// Khởi tạo notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh')); // GMT+7

    // Create notification channel for Android 8.0+ (required for notifications to show)
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'health_reminders', // channel id - must match the one used in AndroidNotificationDetails
        'Nhắc nhở sức khỏe', // channel name
        description: 'Thông báo nhắc nhở về lịch hẹn, thuốc men và sức khỏe',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Create the channel
        await androidPlugin.createNotificationChannel(androidChannel);
        print('✅ Created notification channel: health_reminders');
      }
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (Android 13+)
    await _requestPermissions();

    _initialized = true;
    print('✅ NotificationService initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request notification permission (Android 13+)
    if (await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission() ??
        false) {
      // Permission granted
    }

    // Request exact alarm permission (Android 12+)
    if (Platform.isAndroid) {
      await _requestExactAlarmPermission();
    }

    // Request iOS permissions
    if (await _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false) {
      // Permission granted
    }
  }

  /// Request exact alarm permission for Android 12+ (API 31+)
  Future<bool> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        _hasExactAlarmPermission = false;
        return false;
      }
      
      // Try to check if exact alarms are allowed (Android 12+)
      // This method may not exist in all versions, so we catch and handle gracefully
      try {
        final canScheduleExactAlarms = await androidPlugin.canScheduleExactNotifications();
        if (canScheduleExactAlarms == true) {
          _hasExactAlarmPermission = true;
          return true;
        }
      } catch (e) {
        // Method may not exist, assume false
        print('⚠️ canScheduleExactNotifications not available: $e');
      }
      
      // If not allowed, try to request permission
      // Note: On Android 12+, user must grant this in system settings
      try {
        final requested = await androidPlugin.requestExactAlarmsPermission();
        if (requested == true) {
          _hasExactAlarmPermission = true;
          return true;
        }
      } catch (e) {
        // Method may not exist, that's okay
        print('⚠️ requestExactAlarmsPermission not available: $e');
      }
      
      // Default to false - will use inexact mode
      _hasExactAlarmPermission = false;
      return false;
    } catch (e) {
      print('⚠️ Error checking exact alarm permission: $e');
      _hasExactAlarmPermission = false;
      return false;
    }
  }

  /// Open Android Settings screen for exact alarm permission
  /// This will open the system settings where user can enable "Allow setting alarms and reminders"
  Future<bool> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        print('⚠️ Android plugin not available');
        return false;
      }
      
      // This method opens the system settings screen for exact alarm permission
      final opened = await androidPlugin.requestExactAlarmsPermission();
      
      if (opened == true) {
        print('✅ Opened exact alarm settings screen');
        // Reset permission cache so we can check again after user returns
        _hasExactAlarmPermission = null;
        return true;
      } else {
        print('⚠️ Could not open exact alarm settings');
        return false;
      }
    } catch (e) {
      print('❌ Error opening exact alarm settings: $e');
      return false;
    }
  }

  /// Check if exact alarms are permitted
  Future<bool> canScheduleExactAlarms() async {
    // If we already know the permission status, return it
    if (_hasExactAlarmPermission != null) {
      return _hasExactAlarmPermission!;
    }
    
    if (!Platform.isAndroid) return true;
    
    // Default to false (inexact mode) for safety
    _hasExactAlarmPermission = false;
    
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin == null) {
        return false;
      }
      
      // Try to check permission, but handle gracefully if method doesn't exist
      try {
        // Check if the method exists by trying to call it
        final canSchedule = await androidPlugin.canScheduleExactNotifications();
        _hasExactAlarmPermission = canSchedule == true;
        if (_hasExactAlarmPermission == true) {
          print('✅ Exact alarms are permitted');
        } else {
          print('⚠️ Exact alarms are not permitted, will use inexact mode');
        }
        return _hasExactAlarmPermission ?? false;
      } catch (e) {
        // Method may not exist or permission denied, default to false (use inexact mode)
        print('⚠️ Cannot check exact alarm permission (method may not exist), defaulting to inexact mode: $e');
        _hasExactAlarmPermission = false;
        return false;
      }
    } catch (e) {
      print('⚠️ Error checking exact alarm permission: $e');
      _hasExactAlarmPermission = false;
      return false;
    }
  }

  /// Handler khi user tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    // Có thể navigate đến screen tương ứng dựa trên payload
    // Ví dụ: nếu là medication reminder -> navigate to medications screen
    // if (response.payload != null) {
    //   // Handle navigation
    // }
  }

  /// Schedule một notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Chỉ schedule nếu thời gian trong tương lai
    if (scheduledTime.isBefore(now)) {
      print('⚠️ Cannot schedule notification: time is in the past. Scheduled: $scheduledTime, Now: $now');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'health_reminders',
      'Nhắc nhở sức khỏe',
      channelDescription: 'Thông báo nhắc nhở về lịch hẹn, thuốc men và sức khỏe',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Always use inexact mode by default for maximum compatibility
    // Exact mode requires special permission that users must grant in system settings
    // Inexact mode works reliably on all Android versions without special permissions
    bool useExactMode = false;
    
    // Only try exact mode if we're certain we have permission (cached from previous successful check)
    if (Platform.isAndroid && _hasExactAlarmPermission == true) {
      useExactMode = true;
    }
    
    // Try scheduling with the selected mode
    AndroidScheduleMode scheduleMode = useExactMode 
        ? AndroidScheduleMode.exactAllowWhileIdle 
        : AndroidScheduleMode.inexactAllowWhileIdle;
    
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      print('✅ Notification scheduled: ID=$id, Time=$scheduledTime, Title="$title", Mode=${useExactMode ? "exact" : "inexact"}');
      return; // Success, exit early
    } on PlatformException catch (e) {
      // Handle exact alarm permission error specifically
      final isExactAlarmError = e.code == 'exact_alarms_not_permitted' || 
                                e.code == 'exact_alarm_not_permitted' ||
                                (e.message != null && (
                                  e.message!.toLowerCase().contains('exact') ||
                                  e.message!.toLowerCase().contains('alarm')
                                ));
      
      if (isExactAlarmError) {
        // We got exact alarm error, retry with inexact mode
        print('⚠️ Exact alarms not permitted (${e.code}), retrying with inexact mode...');
        _hasExactAlarmPermission = false; // Cache the failure
        
        // Retry with inexact mode
        try {
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            scheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
          print('✅ Notification scheduled (inexact mode after retry): ID=$id, Time=$scheduledTime, Title="$title"');
          return; // Success after retry
        } catch (retryError) {
          print('❌ Error scheduling notification (inexact mode retry): $retryError');
          // Don't rethrow - just log the error
        }
      } else {
        // Other error
        print('❌ Error scheduling notification: ${e.code} - ${e.message}');
        // Don't rethrow - allow app to continue even if notification fails
      }
    } catch (e) {
      // Catch any other errors
      print('❌ Error scheduling notification (unexpected): $e');
      // Don't rethrow - allow app to continue even if notification fails
    }
  }

  /// Schedule notification cho medication
  Future<void> scheduleMedicationReminder({
    required int medicationId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledTime,
    int advanceMinutes = 30,
  }) async {
    final reminderTime = scheduledTime.subtract(Duration(minutes: advanceMinutes));
    
    await scheduleNotification(
      id: 1000 + medicationId, // Unique ID cho medication reminders
      title: 'Nhắc nhở uống thuốc',
      body: 'Đã đến giờ uống $medicationName ($dosage)',
      scheduledDate: reminderTime,
      payload: 'medication:$medicationId',
    );
  }

  /// Schedule notification cho appointment/schedule
  Future<void> scheduleAppointmentReminder({
    required int scheduleId,
    required String title,
    required DateTime scheduledTime,
    String? location,
    String? doctorName,
    int advanceMinutes = 30,
    bool allowImmediateNotification = true, // Cho phép tạo thông báo ngay lập tức
  }) async {
    try {
      final now = DateTime.now();
      final reminderTime = scheduledTime.subtract(Duration(minutes: advanceMinutes));
      
      // Debug log
      print('🔍 Processing schedule $scheduleId:');
      print('   - Title: $title');
      print('   - Scheduled time: $scheduledTime');
      print('   - Reminder time: $reminderTime (${advanceMinutes} min before)');
      print('   - Current time: $now');
      
      // Kiểm tra xem lịch hẹn đã qua chưa
      if (scheduledTime.isBefore(now)) {
        print('⏭️ Skipping reminder for schedule $scheduleId: scheduled time ($scheduledTime) is already past');
        return;
      }
      
      // Nếu reminder time đã qua nhưng lịch hẹn chưa đến -> tạo thông báo ngay lập tức
      DateTime finalReminderTime = reminderTime;
      if (reminderTime.isBefore(now)) {
        if (allowImmediateNotification) {
          // Tạo thông báo ngay lập tức (sau 10 giây để tránh spam)
          finalReminderTime = now.add(const Duration(seconds: 10));
          print('⚠️ Reminder time for schedule $scheduleId is in the past, scheduling immediate notification at $finalReminderTime');
        } else {
          print('⏭️ Skipping reminder for schedule $scheduleId: reminder time ($reminderTime) is in the past and immediate notification is disabled');
          return;
        }
      }
      
      String body = 'Bạn có lịch hẹn: $title';
      if (location != null && location.isNotEmpty) body += '\nĐịa điểm: $location';
      if (doctorName != null && doctorName.isNotEmpty) body += '\nBác sĩ: $doctorName';
      body += '\nThời gian: ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
      
      // Thêm thông tin về thời gian còn lại
      final timeUntilAppointment = scheduledTime.difference(now);
      if (timeUntilAppointment.inMinutes > 0) {
        if (timeUntilAppointment.inHours > 0) {
          body += '\nCòn ${timeUntilAppointment.inHours} giờ ${timeUntilAppointment.inMinutes % 60} phút';
        } else {
          body += '\nCòn ${timeUntilAppointment.inMinutes} phút';
        }
      }
      
      // scheduleNotification handles errors internally and retries with inexact mode
      await scheduleNotification(
        id: 2000 + scheduleId, // Unique ID cho schedule reminders
        title: 'Nhắc nhở lịch hẹn',
        body: body,
        scheduledDate: finalReminderTime, // Sử dụng finalReminderTime thay vì reminderTime
        payload: 'schedule:$scheduleId',
      );
      
      // Log để debug
      print('📅 ✅ Successfully scheduled reminder for schedule $scheduleId: $title at ${finalReminderTime.toString()} (original: ${reminderTime.toString()}, ${advanceMinutes} min before)');
    } catch (e) {
      // This should rarely be hit since scheduleNotification handles errors internally
      print('❌ Error in scheduleAppointmentReminder for schedule $scheduleId: $e');
      // Don't rethrow - let the caller continue
    }
  }

  /// Cancel một notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel tất cả notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel tất cả medication reminders
  Future<void> cancelAllMedicationReminders() async {
    // Cancel notifications với ID từ 1000-1999
    for (int i = 1000; i < 2000; i++) {
      await cancelNotification(i);
    }
  }

  /// Cancel tất cả schedule reminders
  Future<void> cancelAllScheduleReminders() async {
    // Cancel notifications với ID từ 2000-2999
    for (int i = 2000; i < 3000; i++) {
      await cancelNotification(i);
    }
  }

  /// Get tất cả pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check xem notification có được enable không
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications.enabled') ?? true;
  }

  /// Set notification enabled/disabled
  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications.enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Show immediate notification (for testing)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'health_reminders', // Must match channel id
      'Nhắc nhở sức khỏe',
      channelDescription: 'Thông báo nhắc nhở về lịch hẹn, thuốc men và sức khỏe',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      print('✅ Test notification shown: ID=$id, Title="$title"');
    } catch (e) {
      print('❌ Error showing test notification: $e');
    }
  }

  /// Test notification immediately (for debugging)
  Future<void> testNotification() async {
    await showNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'Nếu bạn thấy thông báo này, hệ thống notifications đang hoạt động!',
    );
  }

  /// Test scheduled notification (5 seconds from now)
  Future<void> testScheduledNotification() async {
    final testTime = DateTime.now().add(const Duration(seconds: 5));
    await scheduleNotification(
      id: 9998,
      title: 'Test Scheduled Notification',
      body: 'Thông báo test được lên lịch 5 giây trước!',
      scheduledDate: testTime,
    );
    print('📅 Test notification scheduled for: $testTime');
  }

  /// Test appointment reminder with past reminder time but future appointment
  Future<void> testAppointmentReminder() async {
    final now = DateTime.now();
    final appointmentTime = now.add(const Duration(minutes: 15)); // 15 phút nữa
    
    await scheduleAppointmentReminder(
      scheduleId: 9997,
      title: 'Test Appointment',
      scheduledTime: appointmentTime,
      location: 'Test Location',
      doctorName: 'Dr. Test',
      advanceMinutes: 30, // Sẽ trigger immediate notification vì 30 min ago đã qua
    );
    
    print('📅 Test appointment reminder scheduled: appointment at $appointmentTime');
  }

  /// Get notification permission status and debug info
  Future<Map<String, dynamic>> getNotificationStatus() async {
    final status = <String, dynamic>{};
    
    status['initialized'] = _initialized;
    status['platform'] = Platform.operatingSystem;
    
    if (Platform.isAndroid) {
      status['hasExactAlarmPermission'] = await canScheduleExactAlarms();
      
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        try {
          status['notificationPermission'] = await androidPlugin.areNotificationsEnabled();
        } catch (e) {
          status['notificationPermissionError'] = e.toString();
        }
      }
    }
    
    final pendingNotifications = await getPendingNotifications();
    status['pendingNotificationsCount'] = pendingNotifications.length;
    status['pendingNotifications'] = pendingNotifications.map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'payload': n.payload,
    }).toList();
    
    return status;
  }
}

