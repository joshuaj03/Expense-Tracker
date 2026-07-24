/// Currency and date formatting utilities.
library;

import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String symbol = '₹';

  static NumberFormat get _formatter =>
      NumberFormat.currency(locale: 'en_IN', symbol: symbol, decimalDigits: 2);

  static NumberFormat get _formatterNoDecimal =>
      NumberFormat.currency(locale: 'en_IN', symbol: symbol, decimalDigits: 0);

  /// Format amount as \u20B91,23,456.78
  static String format(double amount) {
    if (amount == amount.truncateToDouble()) {
      return _formatterNoDecimal.format(amount);
    }
    return _formatter.format(amount);
  }

  /// Format amount as compact: \u20B91.2L, \u20B945K, etc.
  static String compact(double amount) {
    if (amount.abs() >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount.abs() >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}

class DateFormatter {
  DateFormatter._();

  static final _fullDate = DateFormat('dd MMM yyyy');
  static final _shortDate = DateFormat('dd MMM');
  static final _dayMonth = DateFormat('d MMMM');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _time = DateFormat('hh:mm a');
  static final _weekday = DateFormat('EEEE');

  static String full(DateTime date) => _fullDate.format(date);
  static String short(DateTime date) => _shortDate.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String time(DateTime date) => _time.format(date);
  static String weekday(DateTime date) => _weekday.format(date);

  /// Returns "Today", "Yesterday", or the formatted date.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    if (date.year == now.year) return short(date);
    return full(date);
  }

  /// Month name abbreviation.
  static String monthAbbr(int month) {
    return DateFormat('MMM').format(DateTime(2024, month));
  }
}
