import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../utils/date_formatter.dart';
import '../../styles/theme.dart';

/// Widget for displaying a medication card
class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final Color statusColor;
  final String statusText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.statusColor,
    required this.statusText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medication.medicationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (medication.dosage != null)
              Row(
                children: [
                  Icon(
                    Icons.scale, 
                    size: 16, 
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Liều dùng: ${medication.dosage}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            if (medication.dosage != null && medication.frequency != null)
              const SizedBox(height: 4),
            if (medication.frequency != null)
              Row(
                children: [
                  Icon(
                    Icons.repeat, 
                    size: 16, 
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tần suất: ${medication.frequency}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            if (medication.startDate != null || medication.endDate != null)
              const SizedBox(height: 8),
            if (medication.startDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today, 
                    size: 16, 
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bắt đầu: ${DateFormatter.formatDate(medication.startDate)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            if (medication.startDate != null && medication.endDate != null)
              const SizedBox(height: 4),
            if (medication.endDate != null)
              Row(
                children: [
                  Icon(
                    Icons.event, 
                    size: 16, 
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kết thúc: ${DateFormatter.formatDate(medication.endDate)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            if (medication.instructions != null)
              const SizedBox(height: 8),
            if (medication.instructions != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark 
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info, 
                      size: 16, 
                      color: isDark 
                          ? AppColors.primary.withOpacity(0.9)
                          : Colors.blue[800],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        medication.instructions!,
                        style: TextStyle(
                          color: isDark 
                              ? AppColors.primary.withOpacity(0.9)
                              : Colors.blue[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, color: AppColors.primary),
                  tooltip: 'Chỉnh sửa',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete, color: AppColors.healthDanger),
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

