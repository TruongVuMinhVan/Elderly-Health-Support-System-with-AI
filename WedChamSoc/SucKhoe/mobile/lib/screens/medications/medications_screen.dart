import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/medications_service.dart';
import '../../models/medication.dart';
import '../../widgets/medications/add_medication_modal.dart';
import '../../widgets/medications/medication_card.dart';
import '../../services/reminder_service.dart';
import '../../styles/theme.dart';
import '../auth/login_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  // Cache API client and service to avoid recreating on every rebuild
  static ApiClient? _cachedApiClient;
  static MedicationsService? _cachedMedicationsService;
  
  late final MedicationsService _medicationsService = _cachedMedicationsService ??= 
    MedicationsService(_cachedApiClient ??= ApiClient());

  List<MedicationModel> _medications = [];
  bool _isLoading = true;
  String? _error;
  bool _showInactive = false;

  DateTime? _lastLoadTime;
  bool _isInitialLoad = true;
  bool _forceRefresh = false;
  static const _minRefreshInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Skip auto-refresh on first load (initState already loads data)
    if (_isInitialLoad) {
      _isInitialLoad = false;
      return;
    }
    
    // Auto-refresh when returning to this screen (e.g., from another screen)
    // Only refresh if enough time has passed since last load to avoid excessive reloading
    // Or if force refresh is requested
    if (_forceRefresh) {
      _forceRefresh = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadMedications();
        }
      });
    } else {
      final now = DateTime.now();
      if (_lastLoadTime == null || 
          now.difference(_lastLoadTime!) > _minRefreshInterval) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadMedications();
          }
        });
      }
    }
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final medications = await _medicationsService.getMedications(
        activeOnly: !_showInactive,
      );
      setState(() {
        _medications = medications;
        _lastLoadTime = DateTime.now();
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách thuốc. Vui lòng thử lại.';
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
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa thuốc này?'),
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

    if (confirmed != true) return;

    try {
      // Optimistic update: Remove from UI immediately
      setState(() {
        _medications.removeWhere((m) => m.id == id);
      });
      
      // Show success message immediately
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xóa thuốc thành công'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Delete and sync in background
      _lastLoadTime = null;
      await Future.wait([
        _medicationsService.deleteMedication(id),
        ReminderService().forceSync(),
      ]);
      if (!mounted) return;
      _loadMedications();
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể xóa thuốc'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAddModal({MedicationModel? medication}) async {
    await showDialog(
      context: context,
      builder: (context) => AddMedicationModal(
        medicationsService: _medicationsService,
        onSuccess: () {
          // Force immediate refresh when modal closes successfully
          if (mounted) {
            _lastLoadTime = null;
            _forceRefresh = true;
            ReminderService().forceSync().then((_) {
              if (mounted) {
                _loadMedications();
              }
            });
          }
        },
        editingMedication: medication,
      ),
    );
    
    // Also reload data after dialog closes (as backup, in case onSuccess wasn't called)
    if (mounted) {
      _lastLoadTime = null;
      _loadMedications();
    }
    
    // Reload data after dialog closes (regardless of result)
    // This ensures data is refreshed even if onSuccess wasn't called
    if (mounted) {
      // Reset last load time to force immediate refresh
      _lastLoadTime = null;
      await ReminderService().forceSync();
      _loadMedications();
    }
  }

  Color _getStatusColor(MedicationModel medication) {
    if (!medication.isActive) {
      return Colors.grey;
    }

    if (medication.endDate != null) {
      final endDate = DateTime.parse(medication.endDate!);
      final today = DateTime.now();
      final daysLeft = endDate.difference(today).inDays;

      if (daysLeft <= 0) {
        return Colors.red;
      } else if (daysLeft <= 7) {
        return Colors.orange;
      }
    }

    return Colors.green;
  }

  String _getStatusText(MedicationModel medication) {
    if (!medication.isActive) {
      return 'Đã ngừng';
    }

    if (medication.endDate != null) {
      final endDate = DateTime.parse(medication.endDate!);
      final today = DateTime.now();
      final daysLeft = endDate.difference(today).inDays;

      if (daysLeft <= 0) {
        return 'Hết hạn';
      } else if (daysLeft <= 7) {
        return 'Còn $daysLeft ngày';
      }
    }

    return 'Đang dùng';
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _medications.where((m) => m.isActive).length;
    final expiringCount = _medications.where((m) {
      if (!m.isActive || m.endDate == null) return false;
      final daysLeft = DateTime.parse(m.endDate!).difference(DateTime.now()).inDays;
      return daysLeft <= 7 && daysLeft > 0;
    }).length;
    final inactiveCount = _medications.where((m) => !m.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thuốc'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMedications,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quản lý thuốc',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openAddModal(),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thuốc mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[800], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red[800], fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadMedications,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),

                  // Medications List
                  if (_medications.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Text('💊', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          Text(
                            _showInactive
                                ? 'Không có thuốc đã ngừng'
                                : 'Chưa có thuốc nào',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showInactive
                                ? 'Bạn chưa có thuốc nào đã ngừng sử dụng'
                                : 'Hãy thêm thuốc đầu tiên để bắt đầu theo dõi',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (!_showInactive) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _openAddModal(),
                              child: const Text('Thêm thuốc đầu tiên'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ..._medications.map((medication) {
                      final statusColor = _getStatusColor(medication);
                      final statusText = _getStatusText(medication);

                      return MedicationCard(
                        medication: medication,
                        statusColor: statusColor,
                        statusText: statusText,
                        onEdit: () => _openAddModal(medication: medication),
                        onDelete: () => _handleDelete(medication.id),
                      );
                    }).toList(),

                  // Stats
                  if (_medications.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _StatCard(
                          value: activeCount.toString(),
                          label: 'Đang dùng',
                          color: Colors.green,
                        ),
                        _StatCard(
                          value: expiringCount.toString(),
                          label: 'Sắp hết hạn',
                          color: Colors.orange,
                        ),
                        _StatCard(
                          value: inactiveCount.toString(),
                          label: 'Đã ngừng',
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
