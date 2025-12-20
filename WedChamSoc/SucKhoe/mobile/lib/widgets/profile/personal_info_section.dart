import 'package:flutter/material.dart';
import '../../styles/theme.dart';

/// Widget for personal information section in profile
class PersonalInfoSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController dobCtrl;
  final String gender;
  final TextEditingController addressCtrl;
  final TextEditingController emgNameCtrl;
  final TextEditingController emgPhoneCtrl;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onDateTap;
  final bool showSuccess;
  final bool isLoading;
  final VoidCallback onSave;

  const PersonalInfoSection({
    super.key,
    required this.formKey,
    required this.fullNameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.dobCtrl,
    required this.gender,
    required this.addressCtrl,
    required this.emgNameCtrl,
    required this.emgPhoneCtrl,
    required this.onGenderChanged,
    required this.onDateTap,
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
                  Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Thông tin cá nhân',
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
                controller: fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                enabled: false,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dobCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ngày sinh',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: onDateTap,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: gender.isEmpty ? null : gender,
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (v) => onGenderChanged(v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.emergency, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text(
                    'Liên hệ khẩn cấp',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emgNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên người liên hệ',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emgPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại liên hệ',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Lưu thông tin cá nhân'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

