import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../shared/data/seed_data.dart';
import '../../../shared/models/planned_entry.dart';
import 'planner_state.dart';

class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit() : super(PlannerState(planned: SeedData.planned));

  static String keyFor(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  String get selectedKey => keyFor(state.year, state.month, state.day);

  void select(int day) => emit(state.copyWith(day: day));

  /// Jumps the calendar to an arbitrary date, e.g. from the calendar-date
  /// screen's date field (`app.js` date `onchange`).
  void selectDate(DateTime date) =>
      emit(state.copyWith(year: date.year, month: date.month, day: date.day));

  /// Moves [offset] months, clamping the selected day to the new month length.
  void navigate(int offset) {
    final target = DateTime(state.year, state.month + offset, 1);
    final length = DateTime(target.year, target.month + 1, 0).day;
    emit(
      state.copyWith(
        year: target.year,
        month: target.month,
        day: state.day > length ? length : state.day,
      ),
    );
  }

  void plan(String key, PlannedEntry entry) =>
      emit(state.copyWith(planned: {...state.planned, key: entry}));

  void remove(String key) =>
      emit(state.copyWith(planned: {...state.planned}..remove(key)));

  /// `2026-10-15` -> `October 15, 2026`.
  String label(String key) =>
      DateFormat('MMMM d, y').format(DateTime.parse(key));

  /// Prototype `plannerScheduleFromOutfit`/picking an outfit on
  /// `calendar-choose`: records the draft outfit + occasion being scheduled.
  /// Provided at the app root so F03/Stylist and F08/Saved can start
  /// scheduling without depending on the calendar feature's UI.
  void startScheduling(int outfitId, String occasion) => emit(
    PlannerState(
      planned: state.planned,
      year: state.year,
      month: state.month,
      day: state.day,
      editingOutfitId: outfitId,
      editingOccasion: occasion,
    ),
  );

  /// Clears the scheduling draft, e.g. after a successful confirm or a
  /// cancelled flow.
  void clearEditing() => emit(
    PlannerState(
      planned: state.planned,
      year: state.year,
      month: state.month,
      day: state.day,
    ),
  );
}
