import 'package:flutter/material.dart';
import '../../models/health.dart' show HealthRecordModel, recordTypeToString;
import '../../utils/date_formatter.dart';
import 'health_constants.dart';

/// Widget for displaying recent health records with pagination
class RecentRecordsList extends StatelessWidget {
  final List<HealthRecordModel> records;
  final int currentPage;
  final int recordsPerPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onDeleteRecord;
  final VoidCallback onAddFirstRecord;

  const RecentRecordsList({
    super.key,
    required this.records,
    required this.currentPage,
    required this.recordsPerPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onDeleteRecord,
    required this.onAddFirstRecord,
  });

  int get totalPages => (records.length / recordsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final paginatedRecords = records
        .skip(currentPage * recordsPerPage)
        .take(recordsPerPage)
        .toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ghi nhận gần đây',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (records.length > recordsPerPage)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 0 ? onPreviousPage : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                      Text(
                        '${currentPage + 1}/$totalPages',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: currentPage < totalPages - 1 ? onNextPage : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'Chưa có ghi nhận nào',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: onAddFirstRecord,
                        child: const Text('Thêm ghi nhận đầu tiên'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...paginatedRecords.map((record) => _buildRecordItem(record)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(HealthRecordModel record) {
    final typeConfig = HealthConstants.getTypeConfig(
      recordTypeToString(record.recordType),
    );
    final color = typeConfig['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${typeConfig['icon']} ${typeConfig['name']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.displayValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                color: Colors.red,
                onPressed: () => onDeleteRecord(record.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatDate(record.recordedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
              Text(
                DateFormatter.formatTime(record.recordedAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: record.isNormal
                      ? Colors.green.shade100
                      : Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.isNormal ? 'Bình thường' : 'Cần chú ý',
                  style: TextStyle(
                    fontSize: 10,
                    color: record.isNormal
                        ? Colors.green.shade800
                        : Colors.yellow.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

