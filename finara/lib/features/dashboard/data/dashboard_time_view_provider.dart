import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_time_view_provider.g.dart';

enum DashboardTimeView { daily, weekly, monthly, yearly }

extension DashboardTimeViewRange on DashboardTimeView {
  (DateTime, DateTime) getDateRange() {
    final now = DateTime.now();
    switch (this) {
      case DashboardTimeView.daily:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case DashboardTimeView.weekly:
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
      case DashboardTimeView.monthly:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case DashboardTimeView.yearly:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }
}

@riverpod
class DashboardTimeViewNotifier extends _$DashboardTimeViewNotifier {
  @override
  DashboardTimeView build() => DashboardTimeView.monthly;

  void setView(DashboardTimeView view) {
    state = view;
  }
}
