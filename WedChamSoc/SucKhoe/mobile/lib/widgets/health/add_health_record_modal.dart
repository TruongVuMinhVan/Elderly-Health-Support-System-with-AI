import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/health_service.dart';

class AddHealthRecordModal extends StatefulWidget {
  final String? selectedType;
  final HealthService healthService;
  final Function() onSuccess;

  const AddHealthRecordModal({
    super.key,
    this.selectedType,
    required this.healthService,
    required this.onSuccess,
  });

  @override
  State<AddHealthRecordModal> createState() => _AddHealthRecordModalState();
}

class _AddHealthRecordModalState extends State<AddHealthRecordModal> {
  final _formKey = GlobalKey<FormState>();
  String _recordType = '';
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _bloodSugarCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heartRateCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  bool _isSubmitting = false;
  String? _error;

  final _healthTypes = const [
    {
      'type': 'blood_pressure',
      'name': 'Huyết áp',
      'unit': 'mmHg',
      'icon': '❤️',
    },
    {
      'type': 'blood_sugar',
      'name': 'Đường huyết',
      'unit': 'mg/dL',
      'icon': '🩸',
    },
    {
      'type': 'weight',
      'name': 'Cân nặng',
      'unit': 'kg',
      'icon': '⚖️',
    },
    {
      'type': 'heart_rate',
      'name': 'Nhịp tim',
      'unit': 'bpm',
      'icon': '💓',
    },
    {
      'type': 'temperature',
      'name': 'Nhiệt độ',
      'unit': '°C',
      'icon': '🌡️',
    },
  ];

  @override
  void initState() {
    super.initState();
    _recordType = widget.selectedType ?? '';
  }

  @override
  void dispose() {
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _bloodSugarCtrl.dispose();
    _weightCtrl.dispose();
    _heartRateCtrl.dispose();
    _temperatureCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null) return;

    setState(() {
      _recordedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_recordType.isEmpty) {
      setState(() => _error = 'Vui lòng chọn loại chỉ số');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> submitData = {
        'record_type': _recordType,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'recorded_at': _recordedAt.toIso8601String(),
      };

      if (_recordType == 'blood_pressure') {
        submitData['systolic_pressure'] = int.parse(_systolicCtrl.text.trim());
        submitData['diastolic_pressure'] = int.parse(_diastolicCtrl.text.trim());
      } else if (_recordType == 'blood_sugar') {
        submitData['blood_sugar'] = double.parse(_bloodSugarCtrl.text.trim());
      } else if (_recordType == 'weight') {
        submitData['weight'] = double.parse(_weightCtrl.text.trim());
      } else if (_recordType == 'heart_rate') {
        submitData['heart_rate'] = int.parse(_heartRateCtrl.text.trim());
      } else if (_recordType == 'temperature') {
        submitData['temperature'] = double.parse(_temperatureCtrl.text.trim());
      }

      await widget.healthService.createRecord(submitData);
      widget.onSuccess();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Có lỗi xảy ra: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  Widget _buildInputFields() {
    if (_recordType.isEmpty) return const SizedBox.shrink();

    if (_recordType == 'blood_pressure') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _systolicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tâm thu *',
                    hintText: '120',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tâm thu' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _diastolicCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tâm trương *',
                    hintText: '80',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tâm trương' : null,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final typeConfig = _healthTypes.firstWhere((t) => t['type'] == _recordType);
    final unit = typeConfig['unit'] as String;

    String? fieldLabel;
    TextEditingController? controller;
    String? hintText;
    bool isDecimal = false;

    switch (_recordType) {
      case 'blood_sugar':
        fieldLabel = 'Đường huyết * ($unit)';
        controller = _bloodSugarCtrl;
        hintText = '100';
        isDecimal = true;
        break;
      case 'weight':
        fieldLabel = 'Cân nặng * ($unit)';
        controller = _weightCtrl;
        hintText = '65.5';
        isDecimal = true;
        break;
      case 'heart_rate':
        fieldLabel = 'Nhịp tim * ($unit)';
        controller = _heartRateCtrl;
        hintText = '72';
        break;
      case 'temperature':
        fieldLabel = 'Nhiệt độ * ($unit)';
        controller = _temperatureCtrl;
        hintText = '36.5';
        isDecimal = true;
        break;
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: fieldLabel,
        hintText: hintText,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập giá trị' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ghi nhận sức khỏe mới',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 14),
                      ),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: _recordType.isEmpty ? null : _recordType,
                  decoration: const InputDecoration(
                    labelText: 'Loại chỉ số *',
                  ),
                  items: _healthTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['type'] as String,
                      child: Text('${type['icon']} ${type['name']} (${type['unit']})'),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _recordType = v ?? '';
                    });
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn loại chỉ số' : null,
                ),
                const SizedBox(height: 16),
                _buildInputFields(),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Thời gian ghi nhận',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(_recordedAt),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Ghi chú thêm (tùy chọn)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
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
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
