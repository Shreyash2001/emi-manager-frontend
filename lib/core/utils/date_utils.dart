import 'package:intl/intl.dart';
import 'package:mobile_emi_manager/core/constants/app_constants.dart';

/// Centralized date formatting utilities.
/// Use these everywhere — never format dates inline in widgets.
class AppDateUtils {
  AppDateUtils._();

  /// Format for API requests: yyyy-MM-dd (e.g. 2024-01-15)
  static String toApiDate(DateTime date) {
    return DateFormat(AppConstants.apiDateFormat).format(date);
  }

  /// Format for display: dd MMM yyyy (e.g. 15 Jan 2024)
  static String toDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }

  /// Format for display with time: dd MMM yyyy, hh:mm a (e.g. 15 Jan 2024, 02:30 PM)
  static String toDisplayDateTime(DateTime date) {
    return DateFormat(AppConstants.displayDateTimeFormat).format(date);
  }

  /// Format for month display: MMM yyyy (e.g. Jan 2024)
  static String toDisplayMonth(DateTime date) {
    return DateFormat(AppConstants.displayMonthFormat).format(date);
  }

  /// Relative date display (e.g. "Today", "Yesterday", "3 days ago")
  static String toRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(targetDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return toDisplayDate(date);
  }

  /// EMI due date display — shows "Overdue" if past.
  static String toEmiDueDate(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return 'Overdue (${toDisplayDate(dueDate)})';
    }
    return toDisplayDate(dueDate);
  }

  /// Parse a date string from the API (ISO 8601 format).
  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Check if a date is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if a date is in the past.
  static bool isPast(DateTime date) => date.isBefore(DateTime.now());

  /// Get the start of the current month.
  static DateTime get startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Get the end of the current month.
  static DateTime get endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }
}
