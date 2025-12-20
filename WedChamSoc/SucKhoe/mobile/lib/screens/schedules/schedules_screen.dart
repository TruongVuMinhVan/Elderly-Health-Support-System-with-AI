import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/schedules_service.dart';
import '../../styles/theme.dart';
import '../../models/schedule.dart' show ScheduleModel, ScheduleType;
import '../../utils/date_formatter.dart';
import '../../widgets/schedules/add_schedule_modal.dart';
import '../../widgets/schedules/schedule_filter_chips.dart';
import '../../widgets/schedules/schedule_card.dart';
import '../../services/reminder_service.dart';
import '../auth/login_screen.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  // Cache API client and service to avoid recreating on every rebuild
  static ApiClient? _cachedApiClient;
  static SchedulesService? _cachedSchedulesService;
  
  late final SchedulesService _schedulesService = _cachedSchedulesService ??= 
    SchedulesService(_cachedApiClient ??= ApiClient());

  List<ScheduleModel> _todaySchedules = [];
  List<ScheduleModel> _upcomingSchedules = [];
  List<ScheduleModel> _allSchedules = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedFilter = 'all';
  int _currentPage = 0;
  static const int _recordsPerPage = 5;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  final List<Map<String, dynamic>> _filters = const [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'appointment', 'label': 'Lịch hẹn'},
    {'value': 'medication', 'label': 'Nhắc uống thuốc'},
    {'value': 'checkup', 'label': 'Khám bệnh'},
  ];

  DateTime? _lastLoadTime;
  bool _isInitialLoad = true;
  static const _minRefreshInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _loadData();
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
    // Chỉ refresh khi user pull to refresh hoặc sau khi thêm/xóa schedule
    // Auto-refresh gây ra quá nhiều rebuilds và API calls
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all data in parallel for faster loading
      final results = await Future.wait([
        _schedulesService.getTodaySchedules(),
        _schedulesService.getSchedules(upcomingOnly: true, limit: 10),
        _schedulesService.getSchedules(
          scheduleType: _selectedFilter == 'all' ? null : _selectedFilter,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _todaySchedules = results[0] as List<ScheduleModel>;
        _upcomingSchedules = results[1] as List<ScheduleModel>;
        _allSchedules = results[2] as List<ScheduleModel>;
        _isLoading = false;
        _currentPage = 0; // Reset to first page when loading new data
        _lastLoadTime = DateTime.now();
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu lịch hẹn: ${e.toString()}';
        _isLoading = false;
      });
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

  Future<void> _showAddModal({ScheduleModel? editingSchedule}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddScheduleModal(
          schedulesService: _schedulesService,
          onSuccess: () {
            // Force immediate refresh when modal closes successfully
            if (mounted) {
              _lastLoadTime = null;
              ReminderService().forceSync().then((_) {
                if (mounted) {
                  _loadData();
                }
              });
            }
          },
          editingSchedule: editingSchedule,
        );
      },
    );
    
    // Also reload data after modal closes (as backup, in case onSuccess wasn't called)
    if (mounted) {
      _lastLoadTime = null;
      _loadData();
    }
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa lịch hẹn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.healthDanger,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Optimistic update: Remove from UI immediately
      setState(() {
        _todaySchedules.removeWhere((s) => s.id == scheduleId);
        _upcomingSchedules.removeWhere((s) => s.id == scheduleId);
        _allSchedules.removeWhere((s) => s.id == scheduleId);
      });
      
      // Show success message immediately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa lịch hẹn thành công')),
      );
      
      // Delete and sync in background
      await _schedulesService.deleteSchedule(scheduleId);
      // Sync reminders in parallel with reload
      _lastLoadTime = null;
      await Future.wait([
        ReminderService().forceSync(),
        _loadData(),
      ]);
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa lịch hẹn: ${e.toString()}'),
          backgroundColor: AppColors.healthDanger,
        ),
      );
    }
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return AppColors.primary;
      case ScheduleType.medication:
        return AppColors.healthNormal;
      case ScheduleType.checkup:
        return Colors.orange;
    }
  }


  void _handleFilterChange(String? value) {
    if (value != null && value != _selectedFilter) {
      setState(() {
        _selectedFilter = value;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch hẹn & Nhắc nhở'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to dashboard
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hẹn & Nhắc nhở'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: const Text(
                    'Lịch hẹn & Nhắc nhở',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddModal(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.healthDanger.withOpacity(0.2)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark 
                        ? AppColors.healthDanger.withOpacity(0.5)
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: isDark 
                            ? AppColors.healthDanger.withOpacity(0.9)
                            : Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),

            // Filter chips
            ScheduleFilterChips(
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterChanged: _handleFilterChange,
            ),

            const SizedBox(height: 16),

            // Today's schedule
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Lịch hôm nay',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_todaySchedules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Không có lịch hẹn nào hôm nay',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _todaySchedules.map((schedule) {
                          final typeColor = _getTypeColor(schedule.scheduleType);
                          return ScheduleCard(
                            schedule: schedule,
                            typeColor: typeColor,
                            isToday: true,
                            isOverdue: schedule.isOverdue,
                            onEdit: () => _showAddModal(editingSchedule: schedule),
                            onDelete: () => _deleteSchedule(schedule.id),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Upcoming
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Nhắc nhở sắp tới',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_upcomingSchedules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Không có lịch hẹn sắp tới',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _upcomingSchedules.take(5).map((schedule) {
                          final typeColor = _getTypeColor(schedule.scheduleType);
                          return ScheduleCard(
                            schedule: schedule,
                            typeColor: typeColor,
                            isToday: false,
                            isOverdue: schedule.isOverdue,
                            onEdit: () => _showAddModal(editingSchedule: schedule),
                            onDelete: () => _deleteSchedule(schedule.id),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // All schedules with pagination
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tất cả lịch hẹn',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (_allSchedules.length > _recordsPerPage)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 24,
                              ),
                              Text(
                                '${_currentPage + 1}/${(_allSchedules.length / _recordsPerPage).ceil()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < (_allSchedules.length / _recordsPerPage).ceil() - 1
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                      }
                                    : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 24,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_allSchedules.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Chưa có lịch hẹn nào',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._allSchedules
                          .skip(_currentPage * _recordsPerPage)
                          .take(_recordsPerPage)
                          .map((schedule) {
                        final isToday = DateFormatter.formatDate(schedule.scheduledDatetime) ==
                            DateFormatter.formatDate(DateTime.now().toIso8601String());
                        final isOverdue = schedule.isOverdue;
                        final typeColor = _getTypeColor(schedule.scheduleType);

                        return ScheduleCard(
                          schedule: schedule,
                          typeColor: typeColor,
                          isToday: isToday,
                          isOverdue: isOverdue,
                          onEdit: () => _showAddModal(editingSchedule: schedule),
                          onDelete: () => _deleteSchedule(schedule.id),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
