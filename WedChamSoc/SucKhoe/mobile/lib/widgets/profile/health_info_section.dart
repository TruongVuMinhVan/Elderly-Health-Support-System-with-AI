import 'package:flutter/material.dart';
import '../../styles/theme.dart';

/// Widget for health information section in profile
class HealthInfoSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController heightCtrl;
  final String bloodType;
  final TextEditingController chronicCtrl;
  final TextEditingController allergiesCtrl;
  final TextEditingController currentMedsCtrl;
  final TextEditingController notesCtrl;
  final ValueChanged<String> onBloodTypeChanged;
  final bool showSuccess;
  final bool isLoading;
  final VoidCallback onSave;

  const HealthInfoSection({
    super.key,
    required this.formKey,
    required this.heightCtrl,
    required this.bloodType,
    required this.chronicCtrl,
    required this.allergiesCtrl,
    required this.currentMedsCtrl,
    required this.notesCtrl,
    required this.onBloodTypeChanged,
    this.showSuccess = false,
    this.isLoading = false,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: AppColors.healthDanger),
                  const SizedBox(width: 8),
                  const Text(
                    'Thông tin sức khỏe',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (showSuccess) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle, color: AppColors.healthNormal, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: heightCtrl,
                decoration: const InputDecoration(
                  labelText: 'Chiều cao (cm)',
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: bloodType.isEmpty ? null : bloodType,
                decoration: const InputDecoration(
                  labelText: 'Nhóm máu',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                ],
                onChanged: (v) => onBloodTypeChanged(v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: chronicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bệnh mãn tính (phân cách bằng dấu phẩy)',
                  prefixIcon: Icon(Icons.medical_services),
                  helperText: 'Ví dụ: Tiểu đường, Cao huyết áp',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dị ứng (phân cách bằng dấu phẩy)',
                  prefixIcon: Icon(Icons.warning),
                  helperText: 'Ví dụ: Đậu phộng, Hải sản',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: currentMedsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Thuốc đang dùng (phân cách bằng dấu phẩy)',
                  prefixIcon: Icon(Icons.medication),
                  helperText: 'Ví dụ: Aspirin, Metformin',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú y tế',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.healthDanger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu thông tin sức khỏe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

