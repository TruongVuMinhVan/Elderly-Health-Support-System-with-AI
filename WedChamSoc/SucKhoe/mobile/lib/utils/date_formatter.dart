import 'package:intl/intl.dart';

/// Utility class for date formatting
class DateFormatter {
  /// Parse datetime string and convert to local time
  static DateTime? _parseToLocal(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final date = DateTime.parse(dateStr);
      // Convert to local time if it's in UTC or has timezone info
      // DateTime.parse() automatically handles timezone conversion
      // But we need to ensure it's in local timezone for display
      return date.isUtc ? date.toLocal() : date;
    } catch (_) {
      return null;
    }
  }

  static String formatDate(String? dateStr) {
    final date = _parseToLocal(dateStr);
    if (date == null) return dateStr ?? '';
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr ?? '';
    }
  }

  static String formatDateTime(String? dateStr) {
    final date = _parseToLocal(dateStr);
    if (date == null) return dateStr ?? '';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr ?? '';
    }
  }

  static String formatTime(String? dateStr) {
    final date = _parseToLocal(dateStr);
    if (date == null) return dateStr ?? '';
    try {
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return dateStr ?? '';
    }
  }
}

