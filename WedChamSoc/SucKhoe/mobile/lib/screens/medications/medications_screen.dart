import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/medications_service.dart';
import '../../models/medication.dart';
import '../../widgets/medications/add_medication_modal.dart';
import '../../widgets/medications/medication_card.dart';
import '../../services/reminder_service.dart';
import '../auth/login_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _medicationsService = MedicationsService(ApiClient());

  List<MedicationModel> _medications = [];
  bool _isLoading = true;
  String? _error;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadMedications();
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
      await _medicationsService.deleteMedication(id);
      // Sync reminders sau khi xóa medication
      await ReminderService().forceSync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xóa thuốc thành công'),
          backgroundColor: Colors.green,
        ),
      );
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

  void _openAddModal({MedicationModel? medication}) {
    showDialog(
      context: context,
      builder: (context) => AddMedicationModal(
        medicationsService: _medicationsService,
        onSuccess: () async {
          // Sync reminders sau khi thêm/sửa medication
          await ReminderService().forceSync();
          _loadMedications();
        },
        editingMedication: medication,
      ),
    );
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
                    color: Colors.grey[700],
                    fontSize: 11,
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
