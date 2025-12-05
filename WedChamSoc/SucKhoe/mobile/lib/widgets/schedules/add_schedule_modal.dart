import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/schedules_service.dart';
import '../../api/api_client.dart';
import '../../models/schedule.dart' show ScheduleModel, ScheduleType, scheduleTypeToString;
import '../../screens/auth/login_screen.dart';

class AddScheduleModal extends StatefulWidget {
  final SchedulesService schedulesService;
  final Function() onSuccess;
  final ScheduleModel? editingSchedule;

  const AddScheduleModal({
    super.key,
    required this.schedulesService,
    required this.onSuccess,
    this.editingSchedule,
  });

  @override
  State<AddScheduleModal> createState() => _AddScheduleModalState();
}

class _AddScheduleModalState extends State<AddScheduleModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();

  ScheduleType _scheduleType = ScheduleType.appointment;
  DateTime _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isRecurring = false;
  String? _recurrencePattern;

  bool _isSubmitting = false;
  String? _error;

  final List<Map<String, dynamic>> _scheduleTypes = [
    {'type': ScheduleType.appointment, 'label': 'Lịch hẹn'},
    {'type': ScheduleType.medication, 'label': 'Nhắc uống thuốc'},
    {'type': ScheduleType.checkup, 'label': 'Khám bệnh'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingSchedule != null) {
      final schedule = widget.editingSchedule!;
      _titleCtrl.text = schedule.title;
      _descriptionCtrl.text = schedule.description ?? '';
      _locationCtrl.text = schedule.location ?? '';
      _doctorNameCtrl.text = schedule.doctorName ?? '';
      _scheduleType = schedule.scheduleType;
      // Parse datetime and convert to local time if needed
      final parsedDate = DateTime.parse(schedule.scheduledDatetime);
      _scheduledDateTime = parsedDate.isUtc ? parsedDate.toLocal() : parsedDate;
      _isRecurring = schedule.isRecurring;
      _recurrencePattern = schedule.recurrencePattern;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _doctorNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final scheduleData = {
        'schedule_type': scheduleTypeToString(_scheduleType),
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        'scheduled_datetime': _scheduledDateTime.toIso8601String(),
        'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'doctor_name': _doctorNameCtrl.text.trim().isEmpty ? null : _doctorNameCtrl.text.trim(),
        'is_recurring': _isRecurring,
        if (_isRecurring) 'recurrence_pattern': (_recurrencePattern ?? 'daily'),
      };

      if (widget.editingSchedule != null) {
        await widget.schedulesService.updateSchedule(
          widget.editingSchedule!.id,
          scheduleData,
        );
      } else {
        // Note: createSchedule uses scheduleData which already has UTC datetime
        // This ScheduleModel is just for type checking, actual data comes from scheduleData
        await widget.schedulesService.createSchedule(
          ScheduleModel(
            id: 0,
            userId: 0,
            scheduleType: _scheduleType,
            title: _titleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
            scheduledDatetime: _scheduledDateTime.toIso8601String(),
            location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
            doctorName: _doctorNameCtrl.text.trim().isEmpty ? null : _doctorNameCtrl.text.trim(),
            medicationId: null,
            isCompleted: false,
            isRecurring: _isRecurring,
            recurrencePattern: _isRecurring ? (_recurrencePattern ?? 'daily') : null,
            createdAt: '',
            updatedAt: '',
            isUpcoming: false,
            isOverdue: false,
          ),
        );
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
      Navigator.pop(context);
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Có lỗi xảy ra: ${e.toString()}';
        _isSubmitting = false;
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.editingSchedule != null ? 'Chỉnh sửa lịch hẹn' : 'Thêm lịch hẹn mới',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề *',
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: Khám tim mạch',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tiêu đề';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ScheduleType>(
                  value: _scheduleType,
                  decoration: const InputDecoration(
                    labelText: 'Loại lịch hẹn',
                    border: OutlineInputBorder(),
                  ),
                  items: _scheduleTypes.map((type) {
                    return DropdownMenuItem<ScheduleType>(
                      value: type['type'] as ScheduleType,
                      child: Text(type['label'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _scheduleType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(_scheduledDateTime)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _scheduledDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _scheduledDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                _scheduledDateTime.hour,
                                _scheduledDateTime.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('Giờ: ${DateFormat('HH:mm').format(_scheduledDateTime)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          try {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_scheduledDateTime),
                              helpText: 'Chọn thời gian',
                              cancelText: 'Hủy',
                              confirmText: 'OK',
                              hourLabelText: 'Giờ',
                              minuteLabelText: 'Phút',
                              builder: (BuildContext context, Widget? child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    alwaysUse24HourFormat: true, // Force 24-hour format
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).colorScheme.primary,
                                        onPrimary: Colors.white,
                                        surface: Theme.of(context).cardColor,
                                        onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                      ),
                                      dialogBackgroundColor: Theme.of(context).cardColor,
                                    ),
                                    child: child!,
                                  ),
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _scheduledDateTime = DateTime(
                                  _scheduledDateTime.year,
                                  _scheduledDateTime.month,
                                  _scheduledDateTime.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          } catch (e) {
                            // Handle any errors with time picker
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi chọn thời gian: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _doctorNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên bác sĩ',
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: BS. Nguyễn Văn A',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Địa điểm',
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: Bệnh viện Bạch Mai',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                    hintText: 'Ghi chú thêm về cuộc hẹn',
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(widget.editingSchedule != null ? 'Cập nhật' : 'Thêm lịch hẹn'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

