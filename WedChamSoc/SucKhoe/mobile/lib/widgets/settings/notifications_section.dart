import 'package:flutter/material.dart';
import 'settings_section_card.dart';

/// Widget for notification settings section
class NotificationsSection extends StatelessWidget {
  final bool email;
  final bool push;
  final bool sms;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onSmsChanged;

  const NotificationsSection({
    super.key,
    required this.email,
    required this.push,
    required this.sms,
    required this.onEmailChanged,
    required this.onPushChanged,
    required this.onSmsChanged,
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
      title: 'Thông báo',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          context: context,
          title: 'Thông báo email',
          subtitle: 'Nhận thông báo qua email',
          value: email,
          onChanged: onEmailChanged,
        ),
        _buildSwitchTile(
          context: context,
          title: 'Thông báo push',
          subtitle: 'Nhận thông báo trên trình duyệt',
          value: push,
          onChanged: onPushChanged,
        ),
        _buildSwitchTile(
          context: context,
          title: 'Thông báo SMS',
          subtitle: 'Nhận thông báo qua tin nhắn',
          value: sms,
          onChanged: onSmsChanged,
        ),
      ],
    );
  }
}

