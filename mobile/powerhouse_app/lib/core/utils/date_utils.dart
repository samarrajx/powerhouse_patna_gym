import 'package:intl/intl.dart';

class GymDateUtils {
  /// Get current time in Indian Standard Time (IST)
  static DateTime getNowIST() {
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  /// Get today's date in IST at midnight
  static DateTime getTodayIST() {
    final now = getNowIST();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get today's date string in YYYY-MM-DD (IST)
  static String getTodayISTStr() {
    return DateFormat('yyyy-MM-dd').format(getNowIST());
  }

  /// Convert a UTC string or DateTime to IST
  static DateTime toIST(dynamic date) {
    if (date == null) return getNowIST();
    DateTime dt;
    if (date is String) {
      dt = DateTime.parse(date);
    } else if (date is DateTime) {
      dt = date;
    } else {
      return getNowIST();
    }
    
    // If it's already UTC or has no timezone, we treat it as UTC and convert to IST
    return dt.toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  /// Format a date for display in IST
  static String formatIST(dynamic date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(toIST(date));
  }
}
