import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';

part 'records_time_view_provider.g.dart';

enum RecordsTimeView { daily, weekly, monthly, yearly }

class RecordsTimeState {
  final RecordsTimeView view;
  final DateTime currentDate;
  final int monthSpan;

  const RecordsTimeState({
    required this.view,
    required this.currentDate,
    this.monthSpan = 1,
  });

  RecordsTimeState copyWith({
    RecordsTimeView? view,
    DateTime? currentDate,
    int? monthSpan,
  }) {
    return RecordsTimeState(
      view: view ?? this.view,
      currentDate: currentDate ?? this.currentDate,
      monthSpan: monthSpan ?? this.monthSpan,
    );
  }

  (DateTime, DateTime) getDateRange() {
    final now = currentDate;
    switch (view) {
      case RecordsTimeView.daily:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case RecordsTimeView.weekly:
        // Assuming week starts on Monday
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        return (
          start,
          start.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          ),
        );
      case RecordsTimeView.monthly:
        final start = DateTime(now.year, now.month, 1);
        final endMonth = now.month + monthSpan;
        // The day before the 1st of endMonth is the last day of the (endMonth-1) month
        final end = DateTime(now.year, endMonth, 0, 23, 59, 59);
        return (start, end);
      case RecordsTimeView.yearly:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  String getFormattedDateRange() {
    final range = getDateRange();
    final start = range.$1;
    final end = range.$2;

    switch (view) {
      case RecordsTimeView.daily:
        // e.g. Jul 04, 2026
        return DateFormat('MMM dd, yyyy').format(start);
      case RecordsTimeView.weekly:
        // e.g. Jun 28 - Jul 04, 2026
        if (start.month == end.month) {
          return '${DateFormat('MMM dd').format(start)} - ${DateFormat('dd, yyyy').format(end)}';
        }
        return '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yyyy').format(end)}';
      case RecordsTimeView.monthly:
        if (monthSpan == 1) {
          return DateFormat('MMMM yyyy').format(start);
        } else {
          // e.g. Jun - Aug 2026
          return '${DateFormat('MMM').format(start)} - ${DateFormat('MMM yyyy').format(end)}';
        }
      case RecordsTimeView.yearly:
        return DateFormat('yyyy').format(start);
    }
  }
}

@riverpod
class RecordsTimeViewNotifier extends _$RecordsTimeViewNotifier {
  @override
  RecordsTimeState build() => RecordsTimeState(
    view: RecordsTimeView.monthly,
    currentDate: DateTime.now(),
    monthSpan: 1,
  );

  void setView(RecordsTimeView view) {
    state = state.copyWith(view: view);
  }

  void setMonthSpan(int span) {
    state = state.copyWith(monthSpan: span);
  }

  void next() {
    final now = state.currentDate;
    DateTime nextDate;
    switch (state.view) {
      case RecordsTimeView.daily:
        nextDate = now.add(const Duration(days: 1));
        break;
      case RecordsTimeView.weekly:
        nextDate = now.add(const Duration(days: 7));
        break;
      case RecordsTimeView.monthly:
        nextDate = DateTime(now.year, now.month + state.monthSpan, now.day);
        break;
      case RecordsTimeView.yearly:
        nextDate = DateTime(now.year + 1, now.month, now.day);
        break;
    }
    state = state.copyWith(currentDate: nextDate);
  }

  void previous() {
    final now = state.currentDate;
    DateTime prevDate;
    switch (state.view) {
      case RecordsTimeView.daily:
        prevDate = now.subtract(const Duration(days: 1));
        break;
      case RecordsTimeView.weekly:
        prevDate = now.subtract(const Duration(days: 7));
        break;
      case RecordsTimeView.monthly:
        prevDate = DateTime(now.year, now.month - state.monthSpan, now.day);
        break;
      case RecordsTimeView.yearly:
        prevDate = DateTime(now.year - 1, now.month, now.day);
        break;
    }
    state = state.copyWith(currentDate: prevDate);
  }

  void resetToToday() {
    state = state.copyWith(currentDate: DateTime.now());
  }
}
