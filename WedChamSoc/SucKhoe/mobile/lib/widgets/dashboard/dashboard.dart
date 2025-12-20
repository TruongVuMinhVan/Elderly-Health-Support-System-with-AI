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
import '../../providers/app_settings_provider.dart';

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

  DateTime? _lastLoadTime;
  bool _isInitialLoad = true;
  static const _minRefreshInterval = Duration(seconds: 5); // Tăng interval để giảm reload
  
  // Cache API clients để tránh tạo mới mỗi lần
  late final ApiClient _apiClient = ApiClient();
  late final UserService _userService = UserService(_apiClient);
  late final HealthService _healthService = HealthService(_apiClient);
  late final MedicationsService _medicationsService = MedicationsService(_apiClient);
  late final SchedulesService _schedulesService = SchedulesService(_apiClient);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Skip auto-refresh on first load (initState already loads data)
    if (_isInitialLoad) {
      _isInitialLoad = false;
      return;
    }
    
    // Tắt auto-refresh trong didChangeDependencies để tránh reload không cần thiết
    // Chỉ refresh khi user pull to refresh hoặc sau khi thêm/xóa data
    // Auto-refresh gây ra quá nhiều rebuilds và API calls
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getCurrentUser();
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
    if (_isLoading) return; // Tránh load trùng lặp
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load data in parallel với limit nhỏ hơn để tăng tốc
      List<HealthRecordModel> healthRecords = [];
      List<MedicationModel> medications = [];
      List<ScheduleModel> allSchedules = [];
      List<ScheduleModel> todaySchedules = [];

      await Future.wait([
        _healthService.getRecords(limit: 20).then((value) => healthRecords = value).catchError((_) => healthRecords = []),
        _medicationsService.getMedications(activeOnly: true).then((value) => medications = value).catchError((_) => medications = []),
        _schedulesService.getSchedules(upcomingOnly: true, limit: 5).then((value) => allSchedules = value).catchError((_) => allSchedules = []),
        _schedulesService.getTodaySchedules().then((value) => todaySchedules = value).catchError((_) => todaySchedules = []),
      ]);

      // Calculate stats - tối ưu hóa bằng cách chỉ tính trên records đã load
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      int weeklyHealthRecords = 0;
      
      // Chỉ tính trên 20 records đầu tiên (đã giới hạn ở trên)
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
          _lastLoadTime = DateTime.now();
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
      SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService(ApiClient()).logout();
    // Clear user-specific settings when logging out and reset to defaults
    await AppSettingsProvider().clearUserSettings();
    if (!mounted) return;
    // Use named route to ensure StaticThemeWrapper is applied
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trang chủ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back button - handled by AuthenticatedLayoutWrapper
        actions: [
          IconButton(
            icon: Icon(
              Icons.camera_alt,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          // Loại bỏ boxShadow để không có bóng phía sau
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.person, 
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_email.isNotEmpty)
                                    Text(
                                      _email,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.settings,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              onPressed: _openSettings,
                              tooltip: 'Cài đặt',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.logout, 
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              onPressed: _logout,
                              tooltip: 'Đăng xuất',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Grid of square cards với center card ở giữa
                    // Sử dụng RepaintBoundary để tối ưu repaint
                    RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final screenWidth = constraints.maxWidth;
                          final spacing = 12.0; // Khoảng cách giữa các card xung quanh
                          final centerCardGap = 20.0; // Khoảng cách giữa card dự đoán và các card xung quanh
                          final cardSize = (screenWidth - spacing) / 2;
                          final centerCardSize = cardSize * 0.6; // Center card nhỏ hơn một chút
                          final colorScheme = Theme.of(context).colorScheme;
                          
                          // Tính toán vị trí center card với khoảng cách
                          // Container bao bọc có kích thước lớn hơn để tạo khoảng cách
                          final containerSize = centerCardSize + centerCardGap * 2;
                          final centerLeft = (screenWidth - containerSize) / 2;
                          final centerTop = (cardSize * 2 + spacing - containerSize) / 2;
                          
                          return Stack(
                            children: [
                              // 2x2 Grid với 4 cards
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: 1.0,
                                children: [
                                  _SquareCard(
                                    title: 'Kiểm tra sức khỏe',
                                    icon: Icons.favorite,
                                    color: const Color(0xFFDC2626), // Red - Health check
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const HealthScreen()),
                                    ),
                                  ),
                                  _SquareCard(
                                    title: 'Lịch hẹn',
                                    icon: Icons.calendar_today,
                                    color: const Color(0xFF0EA5E9), // Blue - Appointments
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SchedulesScreen()),
                                    ),
                                  ),
                                  _SquareCard(
                                    title: 'Quản lý thuốc',
                                    icon: Icons.medical_services,
                                    color: const Color(0xFF16A34A), // Green - Medications
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const MedicationsScreen()),
                                    ),
                                  ),
                                  _SquareCard(
                                    title: 'Tư vấn AI',
                                    icon: Icons.chat_bubble,
                                    color: const Color(0xFFF59E0B), // Amber/Orange - AI Chat
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                                    ),
                                  ),
                                ],
                              ),
                              // Center card - Chụp ảnh dự đoán (có khoảng cách với các card xung quanh)
                              Positioned(
                                left: centerLeft,
                                top: centerTop,
                                child: Container(
                                  width: containerSize,
                                  height: containerSize,
                                  padding: EdgeInsets.all(centerCardGap),
                                  child: _SquareCard(
                                    title: 'Dự đoán',
                                    icon: Icons.camera_alt,
                                    color: const Color(0xFF9333EA), // Purple - Prediction (nổi bật)
                                    onTap: _openCamera,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                    // Sử dụng RepaintBoundary để tối ưu repaint cho stats
                    RepaintBoundary(
                      child: GridView.count(
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
                          color: const Color(0xFFDC2626), // Red - Health
                        ),
                        _StatCard(
                          value: _activeMedicationsCount.toString(),
                          label: 'Thuốc sử dụng',
                          icon: Icons.medication,
                          color: const Color(0xFF0EA5E9), // Light blue - Medications
                        ),
                        _StatCard(
                          value: _upcomingSchedulesCount.toString(),
                          label: 'Lịch hẹn sắp tới',
                          icon: Icons.calendar_today,
                          color: const Color(0xFF3B82F6), // Blue - Appointments
                        ),
                        _StatCard(
                          value: _weeklyReportsCount.toString(),
                          label: 'Báo cáo tuần',
                          icon: Icons.bar_chart,
                          color: const Color(0xFF6B7280), // Gray - Reports
                        ),
                      ],
                      ),
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      // Sử dụng RepaintBoundary cho reminders list để tối ưu repaint
                      RepaintBoundary(
                        child: Column(
                          children: _todayReminders.map((reminder) => _ReminderCard(reminder: reminder)).toList(),
                        ),
                      ),
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
          // Loại bỏ boxShadow để không có bóng phía sau
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40, // Giảm từ 48 xuống 40
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(height: 8), // Giảm từ 12 xuống 8
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LShape {
  topLeft,      // ┌ (L lật ngửa)
  topRight,     // ┘ (L lật ngang)
  bottomLeft,   // └ (L thường)
  bottomRight,  // ┐ (L lật ngang ngược)
}

class _LCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final LShape shape;
  final VoidCallback onTap;

  const _LCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.shape,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          // Loại bỏ boxShadow để không có bóng phía sau
        ),
        child: ClipPath(
          clipper: _LShapeClipper(shape: shape),
          child: Container(
            color: color,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                // Icon and text positioned based on shape
                _buildContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (shape) {
      case LShape.topLeft: // ┌
        return Positioned(
          top: 12,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case LShape.topRight: // ┘
        return Positioned(
          top: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case LShape.bottomLeft: // └
        return Positioned(
          bottom: 12,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      case LShape.bottomRight: // ┐
        return Positioned(
          bottom: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _LShapeClipper extends CustomClipper<Path> {
  final LShape shape;

  _LShapeClipper({required this.shape});

  @override
  Path getClip(Size size) {
    final path = Path();
    final cornerRadius = 12.0; // Rounded corners
    
    // Tính toán kích thước cho từng shape - Tăng kích thước để to hơn và dài hơn
    double lWidth, lHeight;
    switch (shape) {
      case LShape.topLeft: // ┌ (L lật ngửa) - Dài xuống gần đụng bottom card
        lWidth = size.width * 1.0; // 100% để to hơn và dài hơn
        lHeight = size.height * 1.0; // 100% để dài xuống gần đụng bottom card
        break;
      case LShape.topRight: // ┘ (L lật ngang)
        lWidth = size.width * 1.0; // 100% để to hơn và dài hơn
        lHeight = size.height * 1.0; // 100% để dài xuống gần đụng bottom card
        break;
      case LShape.bottomLeft: // └ (L thường)
        lWidth = size.width * 1.0; // 100% để to hơn và dài hơn
        lHeight = size.height * 1.0; // 100% để dài lên gần đụng top card
        break;
      case LShape.bottomRight: // ┐ (L lật ngang ngược)
        lWidth = size.width * 1.0; // 100% để to hơn và dài hơn
        lHeight = size.height * 1.0; // 100% để dài lên gần đụng top card
        break;
    }
    
    switch (shape) {
      case LShape.topLeft: // ┌ (L lật ngửa)
        // Start from top-left corner
        path.moveTo(0, 0);
        // Top edge (horizontal part of L)
        path.lineTo(lWidth - cornerRadius, 0);
        path.quadraticBezierTo(lWidth, 0, lWidth, cornerRadius);
        // Down to corner
        path.lineTo(lWidth, lHeight - cornerRadius);
        path.quadraticBezierTo(lWidth, lHeight, lWidth - cornerRadius, lHeight);
        // Turn to vertical part
        path.lineTo(lHeight + cornerRadius, lHeight);
        path.quadraticBezierTo(lHeight, lHeight, lHeight, lHeight + cornerRadius);
        // Down vertical part
        path.lineTo(lHeight, size.height - cornerRadius);
        path.quadraticBezierTo(lHeight, size.height, lHeight - cornerRadius, size.height);
        // Bottom edge
        path.lineTo(0, size.height);
        path.close();
        break;
        
      case LShape.topRight: // ┘ (L lật ngang)
        // Start from top-right corner
        path.moveTo(size.width, 0);
        // Top edge (horizontal part of L)
        path.lineTo(size.width - lWidth + cornerRadius, 0);
        path.quadraticBezierTo(size.width - lWidth, 0, size.width - lWidth, cornerRadius);
        // Down to corner
        path.lineTo(size.width - lWidth, lHeight - cornerRadius);
        path.quadraticBezierTo(size.width - lWidth, lHeight, size.width - lWidth + cornerRadius, lHeight);
        // Turn to vertical part
        path.lineTo(size.width - lHeight - cornerRadius, lHeight);
        path.quadraticBezierTo(size.width - lHeight, lHeight, size.width - lHeight, lHeight + cornerRadius);
        // Down vertical part
        path.lineTo(size.width - lHeight, size.height - cornerRadius);
        path.quadraticBezierTo(size.width - lHeight, size.height, size.width - lHeight + cornerRadius, size.height);
        // Bottom edge
        path.lineTo(size.width, size.height);
        path.close();
        break;
        
      case LShape.bottomLeft: // └ (L thường)
        // Start from bottom-left corner
        path.moveTo(0, size.height);
        // Bottom edge (horizontal part of L)
        path.lineTo(lWidth - cornerRadius, size.height);
        path.quadraticBezierTo(lWidth, size.height, lWidth, size.height - cornerRadius);
        // Up to corner
        path.lineTo(lWidth, size.height - lHeight + cornerRadius);
        path.quadraticBezierTo(lWidth, size.height - lHeight, lWidth - cornerRadius, size.height - lHeight);
        // Turn to vertical part
        path.lineTo(lHeight + cornerRadius, size.height - lHeight);
        path.quadraticBezierTo(lHeight, size.height - lHeight, lHeight, size.height - lHeight - cornerRadius);
        // Up vertical part
        path.lineTo(lHeight, cornerRadius);
        path.quadraticBezierTo(lHeight, 0, lHeight - cornerRadius, 0);
        // Top edge
        path.lineTo(0, 0);
        path.close();
        break;
        
      case LShape.bottomRight: // ┐ (L lật ngang ngược)
        // Start from bottom-right corner
        path.moveTo(size.width, size.height);
        // Bottom edge (horizontal part of L)
        path.lineTo(size.width - lWidth + cornerRadius, size.height);
        path.quadraticBezierTo(size.width - lWidth, size.height, size.width - lWidth, size.height - cornerRadius);
        // Up to corner
        path.lineTo(size.width - lWidth, size.height - lHeight + cornerRadius);
        path.quadraticBezierTo(size.width - lWidth, size.height - lHeight, size.width - lWidth + cornerRadius, size.height - lHeight);
        // Turn to vertical part
        path.lineTo(size.width - lHeight - cornerRadius, size.height - lHeight);
        path.quadraticBezierTo(size.width - lHeight, size.height - lHeight, size.width - lHeight, size.height - lHeight - cornerRadius);
        // Up vertical part
        path.lineTo(size.width - lHeight, cornerRadius);
        path.quadraticBezierTo(size.width - lHeight, 0, size.width - lHeight + cornerRadius, 0);
        // Top edge
        path.lineTo(size.width, 0);
        path.close();
        break;
    }
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Color _getColor(BuildContext context) {
    switch (reminder.type) {
      case _ReminderType.medication:
        return Theme.of(context).colorScheme.tertiary;
      case _ReminderType.appointment:
        return Theme.of(context).colorScheme.primary;
      case _ReminderType.health:
        return Theme.of(context).colorScheme.error;
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
    final color = _getColor(context);
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.9),
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
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.time,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
