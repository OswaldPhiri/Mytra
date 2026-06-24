import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

extension DateTimeExtensions on DateTime {
  String get formattedDate => DateFormat('dd MMM yyyy').format(this);
  String get formattedDateTime => DateFormat('dd MMM yyyy, HH:mm').format(this);
  String get formattedTime => DateFormat('HH:mm').format(this);
  String get formattedMonth => DateFormat('MMMM yyyy').format(this);
  String get dayOfWeek => DateFormat('EEEE').format(this);
  String get shortDate => DateFormat('dd MMM').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
  DateTime get startOfWeek {
    final diff = weekday - DateTime.monday;
    return subtract(Duration(days: diff)).startOfDay;
  }

  DateTime get startOfYear => DateTime(year, 1, 1);

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formattedDate;
  }
}

extension NumExtensions on num {
  String get formattedCurrency {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '${AppConstants.currencySymbol} ${formatter.format(this)}';
  }

  String get compactCurrency {
    if (this >= 1000000) {
      return '${AppConstants.currencySymbol} ${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${AppConstants.currencySymbol} ${(this / 1000).toStringAsFixed(1)}K';
    }
    return formattedCurrency;
  }

  String get formattedAmount {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(this);
  }

  String get percentage => '${toStringAsFixed(1)}%';
}

extension StringExtensions on String {
  String get capitalizeFirst =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get titleCase => split(' ').map((w) => w.capitalizeFirst).join(' ');

  bool get isNumeric => double.tryParse(this) != null;

  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}...' : this;
}
