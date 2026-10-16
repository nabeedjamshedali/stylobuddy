import '../../../shared/models/planned_entry.dart';

class PlannerState {
  const PlannerState({
    this.planned = const {},
    this.year = 2026,
    this.month = 10,
    this.day = 15,
    this.editingOutfitId,
    this.editingOccasion,
  });

  final Map<String, PlannedEntry> planned;
  final int year;

  /// 1-based month.
  final int month;
  final int day;

  /// Outfit being scheduled on `/calendar-choose` / `/calendar-date`; `null`
  /// when nothing is being scheduled (distinct from any real outfit id).
  final int? editingOutfitId;

  /// Draft occasion for the outfit being scheduled; `null` when there is no
  /// draft.
  final String? editingOccasion;

  PlannerState copyWith({
    Map<String, PlannedEntry>? planned,
    int? year,
    int? month,
    int? day,
    int? editingOutfitId,
    String? editingOccasion,
  }) => PlannerState(
    planned: planned ?? this.planned,
    year: year ?? this.year,
    month: month ?? this.month,
    day: day ?? this.day,
    editingOutfitId: editingOutfitId ?? this.editingOutfitId,
    editingOccasion: editingOccasion ?? this.editingOccasion,
  );
}
