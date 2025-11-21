import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/health_service.dart';
import '../../models/health.dart' show HealthRecordModel;
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
  final _healthService = HealthService(ApiClient());

  List<HealthRecordModel> _recentRecords = [];
  Map<String, Map<String, dynamic>> _stats = {};
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  static const int _recordsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load recent records
      final records = await _healthService.getRecords(limit: 20);
      
      // Load stats for each type
      final statsMap = <String, Map<String, dynamic>>{};
      for (final type in HealthConstants.healthTypes) {
        try {
          final stats = await _healthService.getStats(type['type'] as String);
          statsMap[type['type'] as String] = stats;
        } catch (_) {
          // If no stats, use default
          statsMap[type['type'] as String] = {
            'total_records': 0,
            'latest_value': null,
            'latest_date': null,
            'average_last_7_days': null,
            'trend': 'stable',
          };
        }
      }

      if (!mounted) return;
      setState(() {
        _recentRecords = records;
        _stats = statsMap;
        _isLoading = false;
        // Reset về trang đầu khi tải lại dữ liệu
        _currentPage = 0;
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
        onSuccess: _loadData,
      ),
    );
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _healthService.deleteRecord(recordId);
      if (!mounted) return;
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bản ghi thành công')),
      );
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa bản ghi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Theo dõi sức khỏe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Theo dõi sức khỏe')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Theo dõi sức khỏe',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
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