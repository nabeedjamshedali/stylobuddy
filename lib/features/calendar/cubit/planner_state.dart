import '../../../shared/models/planned_entry.dart';

class PlannerState {
  const PlannerState({
    this.planned = const {},
    this.year = 2026,
    this.month = 10,
    this.day = 15,
  });

  final Map<String, PlannedEntry> planned;
  final int year;

  /// 1-based month.
  final int month;
  final int day;

  PlannerState copyWith({
    Map<String, PlannedEntry>? planned,
    int? year,
    int? month,
    int? day,
  }) =>
      PlannerState(
        planned: planned ?? this.planned,
        year: year ?? this.year,
        month: month ?? this.month,
        day: day ?? this.day,
      );
}
