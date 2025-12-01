import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'settings_section_card.dart';
import '../../services/notification_service.dart';

/// Widget for reminder settings section
class RemindersSection extends StatelessWidget {
  final int advanceMinutes;
  final bool sound;
  final ValueChanged<int> onAdvanceMinutesChanged;
  final ValueChanged<bool> onSoundChanged;

  const RemindersSection({
    super.key,
    required this.advanceMinutes,
    required this.sound,
    required this.onAdvanceMinutesChanged,
    required this.onSoundChanged,
  });

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items,
            onChanged: onChanged,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[600],
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      title: 'Nhắc nhở',
      icon: Icons.settings,
      children: [
        _buildDropdownTile(
          title: 'Thời gian nhắc trước (phút)',
          value: advanceMinutes.toString(),
          items: const [
            DropdownMenuItem(value: '15', child: Text('15 phút')),
            DropdownMenuItem(value: '30', child: Text('30 phút')),
            DropdownMenuItem(value: '60', child: Text('1 giờ')),
            DropdownMenuItem(value: '120', child: Text('2 giờ')),
          ],
          onChanged: (v) {
            if (v != null) {
              final minutes = int.tryParse(v) ?? 30;
              onAdvanceMinutesChanged(minutes);
            }
          },
        ),
        _buildSwitchTile(
          context: context,
          title: 'Âm thanh nhắc nhở',
          subtitle: 'Phát âm thanh khi có nhắc nhở',
          value: sound,
          onChanged: onSoundChanged,
        ),
        
        // Exact alarm permission info (Android only)
        if (Platform.isAndroid) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quyền nhắc nhở chính xác',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Để nhắc nhở hoạt động chính xác, vui lòng bật quyền "Allow setting alarms and reminders" trong cài đặt hệ thống.',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final opened = await NotificationService().openExactAlarmSettings();
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể mở cài đặt. Vui lòng mở thủ công trong Settings > Apps > app_mobile > Alarms & reminders'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Mở cài đặt hệ thống'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

