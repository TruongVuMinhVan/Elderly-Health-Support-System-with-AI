import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/schedules_service.dart';
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
  final _schedulesService = SchedulesService(ApiClient());

  List<ScheduleModel> _todaySchedules = [];
  List<ScheduleModel> _upcomingSchedules = [];
  List<ScheduleModel> _allSchedules = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedFilter = 'all';
  int _currentPage = 0;
  static const int _recordsPerPage = 5;

  final List<Map<String, dynamic>> _filters = const [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'appointment', 'label': 'Lịch hẹn'},
    {'value': 'medication', 'label': 'Nhắc uống thuốc'},
    {'value': 'checkup', 'label': 'Khám bệnh'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load today's schedules
      final today = await _schedulesService.getTodaySchedules();

      // Load upcoming schedules
      final upcoming = await _schedulesService.getSchedules(
        upcomingOnly: true,
        limit: 10,
      );

      // Load all schedules with filter
      final all = await _schedulesService.getSchedules(
        scheduleType: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (!mounted) return;
      setState(() {
        _todaySchedules = today;
        _upcomingSchedules = upcoming;
        _allSchedules = all;
        _isLoading = false;
        _currentPage = 0; // Reset to first page when loading new data
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
          onSuccess: () async {
            // Sync reminders sau khi thêm/sửa schedule
            await ReminderService().forceSync();
            _loadData();
          },
          editingSchedule: editingSchedule,
        );
      },
    );
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _schedulesService.deleteSchedule(scheduleId);
      // Sync reminders sau khi xóa schedule
      await ReminderService().forceSync();
      if (!mounted) return;
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa lịch hẹn thành công')),
      );
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa lịch hẹn: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return Colors.blue;
      case ScheduleType.medication:
        return Colors.green;
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
        appBar: AppBar(title: const Text('Lịch hẹn & Nhắc nhở')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn & Nhắc nhở')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch hẹn & Nhắc nhở',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddModal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lịch hẹn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade800),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Không có lịch hẹn nào hôm nay',
                            style: TextStyle(color: Colors.black54),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Không có lịch hẹn sắp tới',
                            style: TextStyle(color: Colors.black54),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Chưa có lịch hẹn nào',
                            style: TextStyle(color: Colors.black54),
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
