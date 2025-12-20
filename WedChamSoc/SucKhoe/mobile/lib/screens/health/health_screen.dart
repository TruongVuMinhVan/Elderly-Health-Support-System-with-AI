import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/health_service.dart';
import '../../models/health.dart' show HealthRecordModel;
import '../../styles/theme.dart';
import '../../widgets/health/add_health_record_modal.dart';
import '../../widgets/health/health_constants.dart';
import '../../widgets/health/health_stat_card.dart';
import '../../widgets/health/recent_records_list.dart';
import '../auth/login_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  // Cache API client and service to avoid recreating on every rebuild
  static ApiClient? _cachedApiClient;
  static HealthService? _cachedHealthService;
  
  late final HealthService _healthService = _cachedHealthService ??= 
    HealthService(_cachedApiClient ??= ApiClient());

  List<HealthRecordModel> _recentRecords = [];
  Map<String, Map<String, dynamic>> _stats = {};
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  static const int _recordsPerPage = 5;

  DateTime? _lastLoadTime;
  bool _isInitialLoad = true;
  static const _minRefreshInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _loadData(showLoading: true); // Chỉ hiển thị loading ở lần load đầu tiên
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Skip auto-refresh on first load (initState already loads data)
    if (_isInitialLoad) {
      _isInitialLoad = false;
      return;
    }
    
    // Không auto-refresh trong didChangeDependencies để tránh reload không cần thiết
    // Chỉ refresh khi user pull to refresh hoặc sau khi thêm/xóa record
  }

  Future<void> _loadData({bool showLoading = false}) async {
    // Chỉ hiển thị loading indicator nếu đây là lần load đầu tiên hoặc user yêu cầu
    if (showLoading || _recentRecords.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      // Nếu đã có data, chỉ clear error, không hiển thị loading
      setState(() {
        _error = null;
      });
    }

    try {
      // Load records and all stats in parallel (optimized: 1 stats call instead of 4)
      final recordsFuture = _healthService.getRecords(limit: 20);
      final allStatsFuture = _healthService.getAllStats();
      
      final results = await Future.wait([
        recordsFuture,
        allStatsFuture,
      ]);

      if (!mounted) return;
      setState(() {
        _recentRecords = results[0] as List<HealthRecordModel>;
        _stats = results[1] as Map<String, Map<String, dynamic>>;
        _isLoading = false;
        // Reset về trang đầu khi tải lại dữ liệu
        _currentPage = 0;
        _lastLoadTime = DateTime.now();
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu sức khỏe: ${e.toString()}';
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

  Future<void> _showAddModal({String? selectedType}) async {
    await showDialog(
      context: context,
      builder: (context) => AddHealthRecordModal(
        selectedType: selectedType,
        healthService: _healthService,
        onSuccess: () {
          // Force immediate refresh when dialog closes successfully
          if (mounted) {
            _lastLoadTime = null;
            _loadData();
          }
        },
      ),
    );
    
    // Also reload data after dialog closes (as backup, in case onSuccess wasn't called)
    if (mounted) {
      _lastLoadTime = null;
      _loadData();
    }
  }

  Future<void> _deleteRecord(int recordId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bản ghi này?'),
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
        _recentRecords.removeWhere((r) => r.id == recordId);
      });
      
      // Show success message immediately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bản ghi thành công')),
      );
      
      // Delete and reload in background
      _lastLoadTime = null;
      await _healthService.deleteRecord(recordId);
      if (!mounted) return;
      _loadData();
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa bản ghi: ${e.toString()}'),
          backgroundColor: AppColors.healthDanger,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi sức khỏe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(showLoading: false), // Không hiển thị loading khi pull to refresh
        child: _isLoading && _recentRecords.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text(
                    'Theo dõi sức khỏe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddModal(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ghi nhận mới'),
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

            // Type cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: HealthConstants.healthTypes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final type = HealthConstants.healthTypes[index];
                final typeStr = type['type'] as String;
                final stats = _stats[typeStr];
                
                return HealthStatCard(
                  typeConfig: type,
                  stats: stats,
                  onRecordTap: () => _showAddModal(selectedType: typeStr),
                );
              },
            ),

            const SizedBox(height: 16),

            // Recent records
            RecentRecordsList(
              records: _recentRecords,
              currentPage: _currentPage,
              recordsPerPage: _recordsPerPage,
              onPreviousPage: () {
                setState(() {
                  _currentPage--;
                });
              },
              onNextPage: () {
                setState(() {
                  _currentPage++;
                });
              },
              onDeleteRecord: _deleteRecord,
              onAddFirstRecord: () => _showAddModal(),
            ),
          ],
        ),
      ),
    );
  }
}