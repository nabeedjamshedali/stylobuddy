import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/planned_entry.dart';
import '../repository/in_memory_planner_repository.dart';
import '../repository/planner_repository.dart';
import 'planner_state.dart';

class PlannerCubit extends Cubit<PlannerState> {
  // [repository] defaults to a fresh InMemoryPlannerRepository() (guest
  // mode) so the pre-existing `PlannerCubit()` call site in lib/app.dart and
  // every pre-existing test needs no edit (same no-churn precedent as
  // F16's OutfitsCubit constructor). The default is resolved once in this
  // forwarding factory (never twice) so the same resolved instance backs
  // both this Cubit's initial snapshot and its live watchPlanned()
  // subscription.
  factory PlannerCubit({PlannerRepository? repository}) =>
      PlannerCubit._(repository ?? InMemoryPlannerRepository());

  PlannerCubit._(this._repository)
    : super(PlannerState(planned: _initialPlanned(_repository))) {
    // Subscribes immediately so a Firestore reconciliation (or, for the
    // in-memory implementation, this repository's own write-driven
    // re-emit) reaches this Cubit's state — mirrors WardrobeCubit's/
    // OutfitsCubit's own constructor-time subscription (F15/F16), torn
    // down in [close].
    _subscription = _repository.watchPlanned().listen(
      (planned) => emit(state.copyWith(planned: planned)),
      // A snapshot error must not kill this subscription silently for the
      // rest of the Cubit's lifetime, nor propagate as an unhandled stream
      // error (F17-A16) — the last known state is kept.
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchPlanned() stream error', error, stackTrace);
      },
    );
  }

  final PlannerRepository _repository;
  late final StreamSubscription<Map<String, PlannedEntry>> _subscription;

  /// Non-fatal logging for a background write/stream failure — never
  /// rethrown, never left as an unhandled async error (which `main.dart`
  /// would otherwise report to Crashlytics as `fatal: true`).
  static void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('PlannerCubit: $context: $error\n$stackTrace');
    }
  }

  /// Mirrors WardrobeCubit's/OutfitsCubit's `_initialItems`/
  /// `_initialOutfits`: a guest's very first frame must already show the
  /// seed plan map (today's synchronous behavior, F17-A08) rather than one
  /// empty frame before [PlannerRepository.watchPlanned]'s
  /// always-asynchronous first event. A signed-in (Firestore) instance has
  /// no such synchronous snapshot — it legitimately starts empty until its
  /// first `watchPlanned()` event arrives.
  static Map<String, PlannedEntry> _initialPlanned(
    PlannerRepository repository,
  ) {
    if (repository is InMemoryPlannerRepository) return repository.snapshot;
    return const {};
  }

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

  /// Optimistically updates `state.planned` synchronously (matching today's
  /// instant-feeling UX and keeping the existing F09/F17-A08 guest-mode
  /// test suite's synchronous assertions unaffected), then fires the
  /// repository's own persistence call in the background. If that call
  /// fails, reverts just [key] back to its pre-call value rather than
  /// leaving the optimistic entry in place (D6 "reconcile on failure",
  /// F17-A13) — the revert is a targeted single-key change applied against
  /// the *current* `state.planned` at failure time, not a full-map restore
  /// of the pre-call snapshot, so a concurrent `plan`/`remove` call (or a
  /// remote Firestore snapshot) that already landed in the meantime is
  /// never clobbered (same ruling as `OutfitsCubit.removeWear`, F16).
  void plan(String key, PlannedEntry entry) {
    final previousEntry = state.planned[key];
    emit(state.copyWith(planned: {...state.planned, key: entry}));
    unawaited(() async {
      try {
        await _repository.plan(key, entry);
      } catch (error, stackTrace) {
        _logError('plan failed', error, stackTrace);
        if (isClosed) return;
        final reverted = {...state.planned};
        if (previousEntry == null) {
          reverted.remove(key);
        } else {
          reverted[key] = previousEntry;
        }
        emit(state.copyWith(planned: reverted));
      }
    }());
  }

  /// Same optimistic-then-reconcile shape as [plan] (F17-A14): removes
  /// [key] synchronously, then on a repository failure restores just that
  /// key's pre-call value into the *current* map — but only if the key is
  /// still absent, so a newer write for the same key (landed after this
  /// optimistic removal) is never clobbered by a stale restore.
  void remove(String key) {
    final previousEntry = state.planned[key];
    emit(state.copyWith(planned: {...state.planned}..remove(key)));
    unawaited(() async {
      try {
        await _repository.remove(key);
      } catch (error, stackTrace) {
        _logError('remove failed', error, stackTrace);
        if (isClosed) return;
        if (previousEntry != null && !state.planned.containsKey(key)) {
          emit(
            state.copyWith(planned: {...state.planned, key: previousEntry}),
          );
        }
      }
    }());
  }

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

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
