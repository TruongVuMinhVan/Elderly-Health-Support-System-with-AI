import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../screens/health/health_screen.dart';
import '../../screens/medications/medications_screen.dart';
import '../../screens/schedules/schedules_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../styles/theme.dart';
import '../../api/api_client.dart';
import '../../api/user_service.dart';
import '../../api/auth_service.dart';
import '../../api/health_service.dart';
import '../../api/medications_service.dart';
import '../../api/schedules_service.dart';
import '../../models/health.dart';
import '../../models/schedule.dart';
import '../../models/medication.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/skin_disease/skin_disease_predict_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String _name = 'NGƯỜI DÙNG';
  String _email = '';

  // Dashboard stats
  int _healthRecordsCount = 0;
  int _activeMedicationsCount = 0;
  int _upcomingSchedulesCount = 0;
  int _weeklyReportsCount = 0;

  // Today's reminders
  List<_TodayReminder> _todayReminders = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDashboardData();
  }

  Future<void> _loadUser() async {
    try {
      final user = await UserService(ApiClient()).getCurrentUser();
      if (!mounted) return;
      setState(() {
        _name = (user['full_name'] ?? 'NGƯỜI DÙNG').toString().toUpperCase();
        _email = (user['email'] ?? '').toString();
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (_) {
      // Other errors silently ignored
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient();
      final healthService = HealthService(apiClient);
      final medicationsService = MedicationsService(apiClient);
      final schedulesService = SchedulesService(apiClient);

      // Load data in parallel
      List<HealthRecordModel> healthRecords = [];
      List<MedicationModel> medications = [];
      List<ScheduleModel> allSchedules = [];
      List<ScheduleModel> todaySchedules = [];

      await Future.wait([
        healthService.getRecords(limit: 100).then((value) => healthRecords = value).catchError((_) => healthRecords = []),
        medicationsService.getMedications(activeOnly: true).then((value) => medications = value).catchError((_) => medications = []),
        schedulesService.getSchedules(upcomingOnly: true, limit: 10).then((value) => allSchedules = value).catchError((_) => allSchedules = []),
        schedulesService.getTodaySchedules().then((value) => todaySchedules = value).catchError((_) => todaySchedules = []),
      ]);

      // Calculate stats
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      int weeklyHealthRecords = 0;
      
      for (var record in healthRecords) {
        try {
          final recordedAt = DateTime.parse(record.recordedAt);
          if (recordedAt.isAfter(weekAgo)) {
            weeklyHealthRecords++;
          }
        } catch (_) {
          // Skip invalid records
        }
      }

      // Build today's reminders
      final reminders = <_TodayReminder>[];
      
      // Add today's schedules
      for (var schedule in todaySchedules) {
        try {
          final scheduledAt = DateTime.parse(schedule.scheduledDatetime);
          reminders.add(_TodayReminder(
            id: 'schedule-${schedule.id}',
            title: schedule.title,
            time: DateFormat('HH:mm').format(scheduledAt),
            date: scheduledAt,
            type: _ReminderType.appointment,
          ));
        } catch (_) {
          // Skip invalid schedules
        }
      }

      // Add medication reminders (simplified)
      for (var i = 0; i < medications.length && i < 2; i++) {
        final med = medications[i];
        reminders.add(_TodayReminder(
          id: 'med-${med.id}',
          title: 'Uống ${med.medicationName}',
          time: i == 0 ? '08:00' : '20:00',
          date: DateTime.now(),
          type: _ReminderType.medication,
        ));
      }

      if (!mounted) return;
      setState(() {
        _healthRecordsCount = healthRecords.length;
        _activeMedicationsCount = medications.length;
        _upcomingSchedulesCount = allSchedules.length;
        _weeklyReportsCount = weeklyHealthRecords;
        _todayReminders = reminders.take(3).toList();
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu dashboard';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService(ApiClient()).logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SkinDiseasePredictScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _openCamera,
            tooltip: 'Chụp ảnh dự đoán bệnh da',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading && _healthRecordsCount == 0
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header user info
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.elderlyBorder,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_email.isNotEmpty)
                                    Text(
                                      _email,
                                      style: const TextStyle(color: Colors.black54),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.grey),
                              onPressed: _openSettings,
                              tooltip: 'Cài đặt',
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.grey),
                              onPressed: _logout,
                              tooltip: 'Đăng xuất',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Grid of square cards
                    GridView.count(
                      crossAxisCount: isLandscape ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isLandscape ? 1.2 : 1.0,
                      children: [
                        _SquareCard(
                          title: 'Kiểm tra sức khỏe',
                          icon: Icons.favorite,
                          color: Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HealthScreen()),
                          ),
                        ),
                        _SquareCard(
                          title: 'Lịch hẹn & nhắc nhở',
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SchedulesScreen()),
                          ),
                        ),
                        _SquareCard(
                          title: 'Quản lý thuốc',
                          icon: Icons.medical_services,
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicationsScreen()),
                          ),
                        ),
                        _SquareCard(
                          title: 'Tư vấn AI',
                          icon: Icons.chat_bubble,
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stats section
                    Text(
                      'Chỉ số sức khỏe',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: isLandscape ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isLandscape ? 1.5 : 1.3,
                      children: [
                        _StatCard(
                          value: _healthRecordsCount.toString(),
                          label: 'Chỉ số sức khỏe',
                          icon: Icons.favorite,
                          color: Colors.red,
                        ),
                        _StatCard(
                          value: _activeMedicationsCount.toString(),
                          label: 'Thuốc đang dùng',
                          icon: Icons.medication,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          value: _upcomingSchedulesCount.toString(),
                          label: 'Lịch hẹn sắp tới',
                          icon: Icons.calendar_today,
                          color: Colors.green,
                        ),
                        _StatCard(
                          value: _weeklyReportsCount.toString(),
                          label: 'Báo cáo tuần này',
                          icon: Icons.bar_chart,
                          color: Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Today's reminders
                    Text(
                      'Nhắc nhở hôm nay',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_todayReminders.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Không có nhắc nhở nào hôm nay',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._todayReminders.map((reminder) => _ReminderCard(reminder: reminder)),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SquareCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SquareCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReminderType { medication, appointment, health }

class _TodayReminder {
  final String id;
  final String title;
  final String time;
  final DateTime date;
  final _ReminderType type;

  _TodayReminder({
    required this.id,
    required this.title,
    required this.time,
    required this.date,
    required this.type,
  });
}

class _ReminderCard extends StatelessWidget {
  final _TodayReminder reminder;

  const _ReminderCard({required this.reminder});

  Color _getColor() {
    switch (reminder.type) {
      case _ReminderType.medication:
        return Colors.orange;
      case _ReminderType.appointment:
        return Colors.blue;
      case _ReminderType.health:
        return Colors.red;
    }
  }

  IconData _getIcon() {
    switch (reminder.type) {
      case _ReminderType.medication:
        return Icons.medication;
      case _ReminderType.appointment:
        return Icons.calendar_today;
      case _ReminderType.health:
        return Icons.favorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIcon(), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
