import 'package:flutter/material.dart';
import '../../models/schedule.dart' show ScheduleModel, ScheduleType;
import '../../utils/date_formatter.dart';
import '../../styles/theme.dart';

/// Widget for displaying a schedule card
class ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final Color typeColor;
  final bool isToday;
  final bool isOverdue;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.typeColor,
    this.isToday = false,
    this.isOverdue = false,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isOverdue) {
      return isDark 
          ? AppColors.healthDanger.withOpacity(0.2)
          : Colors.red.shade50;
    }
    if (isToday) return typeColor.withOpacity(0.1);
    return Theme.of(context).colorScheme.surface;
  }

  Color _getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isOverdue) {
      return isDark 
          ? AppColors.healthDanger.withOpacity(0.5)
          : Colors.red.shade200;
    }
    if (isToday) return typeColor.withOpacity(0.3);
    return isDark 
        ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
        : const Color(0xFFE5E7EB);
  }

  String _getTypeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return 'Lịch hẹn';
      case ScheduleType.medication:
        return 'Nhắc uống thuốc';
      case ScheduleType.checkup:
        return 'Khám bệnh';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getTypeLabel(schedule.scheduleType),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.healthDanger.withOpacity(0.3)
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Quá hạn',
                    style: TextStyle(
                      color: isDark 
                          ? AppColors.healthDanger.withOpacity(0.9)
                          : Colors.red.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit, size: 18, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Chỉnh sửa',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete, size: 18, color: AppColors.healthDanger),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Xóa',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            schedule.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (schedule.description != null && schedule.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              schedule.description!,
              style: TextStyle(
                fontSize: 13, 
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today, 
                size: 14, 
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatDate(schedule.scheduledDatetime),
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time, 
                size: 14, 
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatTime(schedule.scheduledDatetime),
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          if (schedule.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on, 
                  size: 14, 
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    schedule.location!,
                    style: TextStyle(
                      fontSize: 12, 
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (schedule.doctorName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person, 
                  size: 14, 
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 4),
                Text(
                  schedule.doctorName!,
                  style: TextStyle(
                    fontSize: 12, 
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

