import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// Service để quản lý local notifications trên mobile
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Khởi tạo notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh')); // GMT+7

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
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission() ??
        false) {
      // Permission granted
    }

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

    // Chỉ schedule nếu thời gian trong tương lai
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
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
  }) async {
    final reminderTime = scheduledTime.subtract(Duration(minutes: advanceMinutes));
    
    String body = 'Bạn có lịch hẹn: $title';
    if (location != null) body += '\nĐịa điểm: $location';
    if (doctorName != null) body += '\nBác sĩ: $doctorName';
    
    await scheduleNotification(
      id: 2000 + scheduleId, // Unique ID cho schedule reminders
      title: 'Nhắc nhở lịch hẹn',
      body: body,
      scheduledDate: reminderTime,
      payload: 'schedule:$scheduleId',
    );
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
      'health_reminders',
      'Nhắc nhở sức khỏe',
      channelDescription: 'Thông báo nhắc nhở về lịch hẹn, thuốc men và sức khỏe',
      importance: Importance.high,
      priority: Priority.high,
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

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}

