import 'package:flutter/material.dart';
import 'health_constants.dart';

/// Widget for displaying a health stat card
class HealthStatCard extends StatelessWidget {
  final Map<String, dynamic> typeConfig;
  final Map<String, dynamic>? stats;
  final VoidCallback onRecordTap;

  const HealthStatCard({
    super.key,
    required this.typeConfig,
    this.stats,
    required this.onRecordTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = stats != null && stats!['latest_value'] != null;
    final latestValue = stats?['latest_value'];
    final latestDate = stats?['latest_date'];
    final totalRecords = stats?['total_records'] ?? 0;
    final color = typeConfig['color'] as Color;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        typeConfig['icon'] as String,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          typeConfig['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.show_chart, color: Colors.grey, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          latestValue.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (latestDate != null)
                          Text(
                            _formatDate(latestDate.toString()),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        Text(
                          'Tổng: $totalRecords lần',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRecordTap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  'Ghi nhận',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

