import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_client.dart';
import '../../api/medications_service.dart';
import '../../models/medication.dart';
import '../../screens/auth/login_screen.dart';

class AddMedicationModal extends StatefulWidget {
  final MedicationsService medicationsService;
  final Function() onSuccess;
  final MedicationModel? editingMedication;

  const AddMedicationModal({
    super.key,
    required this.medicationsService,
    required this.onSuccess,
    this.editingMedication,
  });

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  String _frequency = '';
  String? _startDate;
  String? _endDate;
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _error;

  final List<String> _frequencyOptions = [
    '1 lần/ngày',
    '2 lần/ngày',
    '3 lần/ngày',
    '4 lần/ngày',
    'Khi cần thiết',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingMedication != null) {
      _loadEditingData();
    }
  }

  void _loadEditingData() {
    final med = widget.editingMedication!;
    _nameCtrl.text = med.medicationName;
    _dosageCtrl.text = med.dosage ?? '';
    _frequency = med.frequency ?? '';
    _instructionsCtrl.text = med.instructions ?? '';
    _startDate = med.startDate;
    _endDate = med.endDate;
    _isActive = med.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final data = <String, dynamic>{
        'medication_name': _nameCtrl.text.trim(),
        if (_dosageCtrl.text.trim().isNotEmpty) 'dosage': _dosageCtrl.text.trim(),
        if (_frequency.isNotEmpty) 'frequency': _frequency,
        if (_instructionsCtrl.text.trim().isNotEmpty) 'instructions': _instructionsCtrl.text.trim(),
        if (_startDate != null) 'start_date': _startDate,
        if (_endDate != null) 'end_date': _endDate,
        if (widget.editingMedication != null) 'is_active': _isActive,
      };

      if (widget.editingMedication != null) {
        await widget.medicationsService.updateMedication(
          widget.editingMedication!.id,
          data,
        );
      } else {
        await widget.medicationsService.createMedication(data);
      }

      if (!mounted) return;
      // Close modal first, then call onSuccess to ensure screen rebuilds
      Navigator.pop(context);
      // Use post-frame callback to ensure modal is fully closed before reloading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSuccess();
      });
    } on TokenExpiredException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      setState(() {
        _error = 'Không thể lưu thuốc. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingMedication != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    isEditing ? 'Chỉnh sửa thuốc' : 'Thêm thuốc mới',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red[800], fontSize: 12),
                          ),
                        ),

                      // Medication Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên thuốc *',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên thuốc' : null,
                      ),
                      const SizedBox(height: 16),

                      // Dosage
                      TextFormField(
                        controller: _dosageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Liều lượng',
                          prefixIcon: Icon(Icons.scale),
                          hintText: 'Ví dụ: 500mg',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Frequency
                      DropdownButtonFormField<String>(
                        value: _frequency.isEmpty ? null : _frequency,
                        decoration: const InputDecoration(
                          labelText: 'Tần suất sử dụng',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: _frequencyOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _frequency = v ?? ''),
                      ),
                      const SizedBox(height: 16),

                      // Instructions
                      TextFormField(
                        controller: _instructionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Hướng dẫn sử dụng',
                          prefixIcon: Icon(Icons.info),
                          hintText: 'Ví dụ: Uống sau bữa ăn',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Ngày bắt đầu',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: _startDate != null
                                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_startDate!))
                                    : '',
                              ),
                              onTap: () => _selectDate(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Ngày kết thúc',
                                prefixIcon: Icon(Icons.event),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: _endDate != null
                                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_endDate!))
                                    : '',
                              ),
                              onTap: () => _selectDate(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Active Status (only when editing)
                      if (isEditing)
                        CheckboxListTile(
                          title: const Text('Đang sử dụng'),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v ?? true),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Cập nhật' : 'Thêm'),
                    ),
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

