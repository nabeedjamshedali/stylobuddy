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
}
