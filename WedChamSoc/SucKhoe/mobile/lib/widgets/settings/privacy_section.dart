import 'package:flutter/material.dart';
import 'settings_section_card.dart';

/// Widget for privacy settings section
class PrivacySection extends StatelessWidget {
  final bool shareData;
  final bool analytics;
  final ValueChanged<bool> onShareDataChanged;
  final ValueChanged<bool> onAnalyticsChanged;

  const PrivacySection({
    super.key,
    required this.shareData,
    required this.analytics,
    required this.onShareDataChanged,
    required this.onAnalyticsChanged,
  });

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
      title: 'Quyền riêng tư',
      icon: Icons.shield,
      children: [
        _buildSwitchTile(
          context: context,
          title: 'Chia sẻ dữ liệu',
          subtitle: 'Cho phép chia sẻ dữ liệu để cải thiện dịch vụ',
          value: shareData,
          onChanged: onShareDataChanged,
        ),
        _buildSwitchTile(
          context: context,
          title: 'Phân tích sử dụng',
          subtitle: 'Cho phép thu thập dữ liệu phân tích',
          value: analytics,
          onChanged: onAnalyticsChanged,
        ),
      ],
    );
  }
}

