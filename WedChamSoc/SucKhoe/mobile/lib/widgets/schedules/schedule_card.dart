import 'package:flutter/material.dart';
import '../../models/schedule.dart' show ScheduleModel, ScheduleType;
import '../../utils/date_formatter.dart';

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

  Color _getBackgroundColor() {
    if (isOverdue) return Colors.red.shade50;
    if (isToday) return typeColor.withOpacity(0.1);
    return Colors.white;
  }

  Color _getBorderColor() {
    if (isOverdue) return Colors.red.shade200;
    if (isToday) return typeColor.withOpacity(0.3);
    return const Color(0xFFE5E7EB);
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
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
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Quá hạn',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Chỉnh sửa',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatDate(schedule.scheduledDatetime),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                DateFormatter.formatTime(schedule.scheduledDatetime),
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
          if (schedule.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    schedule.location!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  schedule.doctorName!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

