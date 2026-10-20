import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/models/clothing_item.dart';
import '../models/packing_item.dart';
import '../models/trip.dart';
import '../models/trip_draft.dart';
import '../repository/in_memory_packing_repository.dart';
import '../repository/packing_repository.dart';
import 'packing_state.dart';
import 'save_draft_result.dart';

/// State for the V16 packing assistant (`app.js:199-219`). `trips` (F20,
/// Task 7 of the backend-wiring plan) is now backed by the dual-mode
/// [PackingRepository] (architecture D2, D6): [InMemoryPackingRepository]
/// for guests (today's unchanged in-memory, resets-on-restart behavior),
/// [FirestorePackingRepository] for signed-in users (survives a process
/// restart). `selectedTripId`/`draft` stay pure, local
/// `emit(state.copyWith(...))` calls, unchanged (schema doc §7's named
/// transient exclusion — never a repository method).
class PackingCubit extends Cubit<PackingState> {
  // [repository] defaults to a fresh InMemoryPackingRepository() (guest
  // mode) so the pre-existing `PackingCubit()` call site in lib/app.dart
  // and every pre-existing test needs no edit (same no-churn precedent as
  // F16/F17/F18/F19's Cubit constructors). Resolved once in this
  // forwarding factory so the same resolved instance backs both this
  // Cubit's initial snapshot and its live watchTrips() subscription.
  factory PackingCubit({PackingRepository? repository}) =>
      PackingCubit._(repository ?? InMemoryPackingRepository());

  PackingCubit._(this._repository) : super(_initial(_repository)) {
    // Subscribes immediately so a Firestore reconciliation (or, for the
    // in-memory implementation, this repository's own write-driven
    // re-emit) reaches this Cubit's state — mirrors ShoppingCubit's/
    // ProfileCubit's own constructor-time subscription.
    _subscription = _repository.watchTrips().listen(
      (trips) => emit(state.copyWith(trips: trips)),
      // A snapshot error must not kill this subscription silently for the
      // rest of the Cubit's lifetime, nor propagate as an unhandled stream
      // error (F20-A18) — the last known state is kept.
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchTrips() stream error', error, stackTrace);
      },
    );
  }

  final PackingRepository _repository;
  late final StreamSubscription<List<Trip>> _subscription;

  /// Non-fatal logging for a background write/stream failure — never
  /// rethrown, never left as an unhandled async error (which `main.dart`
  /// would otherwise report to Crashlytics as `fatal: true`).
  static void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('PackingCubit: $context: $error\n$stackTrace');
    }
  }

  /// Mirrors ShoppingCubit's/OutfitsCubit's `_initial`: a guest's very
  /// first frame must already show the current trip list (today's
  /// synchronous behavior) rather than one empty frame before
  /// [PackingRepository.watchTrips]'s always-asynchronous first event. A
  /// signed-in (Firestore) instance has no such synchronous snapshot — it
  /// legitimately starts at `PackingState()`'s defaults (empty trips)
  /// until its first `watchTrips()` event arrives.
  static PackingState _initial(PackingRepository repository) {
    if (repository is InMemoryPackingRepository) {
      return PackingState(trips: repository.snapshot);
    }
    return const PackingState();
  }

  static const _baseCategories = {
    'Shirts',
    'Pants',
    'Dresses',
    'Skirts',
    'Shoes',
  };
  static const _extraCategories = {'Outerwear', 'Accessories'};

  Trip? _find(String id) {
    for (final trip in state.trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  void _replaceTrip(Trip updated) => emit(
    state.copyWith(
      trips: [for (final t in state.trips) t.id == updated.id ? updated : t],
    ),
  );

  /// Port of `pkSuggested`: base wardrobe pieces (Shirts/Pants/Dresses/
  /// Skirts/Shoes, Office-first when the trip type is Business) capped at
  /// `max(5, min(12, days*3))`, plus up to 2 extras from
  /// Outerwear/Accessories. Suggestions use only items that currently exist
  /// in [wardrobeItems]; an empty wardrobe yields an empty list.
  List<PackingItem> suggestions(Trip trip, List<ClothingItem> wardrobeItems) {
    var chosen = [
      for (final item in wardrobeItems)
        if (_baseCategories.contains(item.category)) item,
    ];
    final extra = [
      for (final item in wardrobeItems)
        if (_extraCategories.contains(item.category)) item,
    ];
    if (trip.type == 'Business') {
      final office = [for (final i in chosen) if (i.occasion == 'Office') i];
      final rest = [for (final i in chosen) if (i.occasion != 'Office') i];
      chosen = [...office, ...rest];
    }
    final baseLimit = (trip.days * 3).clamp(5, 12).toInt();
    return [
      for (final item in chosen.take(baseLimit))
        PackingItem(key: item.id, label: item.name, wardrobeId: item.id),
      for (final item in extra.take(2))
        PackingItem(key: item.id, label: item.name, wardrobeId: item.id),
    ];
  }

  /// Prototype `pkNew`: clears the draft and the current selection.
  void newTrip() =>
      emit(state.copyWith(draft: const TripDraft(), clearSelectedTripId: true));

  /// Prototype `pkEdit`: pre-fills the draft from an existing trip and
  /// selects it; a no-op for an unknown id.
  void editTrip(String id) {
    final trip = _find(id);
    if (trip == null) return;
    emit(state.copyWith(draft: TripDraft.fromTrip(trip), selectedTripId: id));
  }

  /// Opens an existing trip (tapping a trip card on `/packing`).
  void selectTrip(String id) => emit(state.copyWith(selectedTripId: id));

  /// Prototype `pkSaveDraft`. Validates, then either updates the trip
  /// currently selected (edit) or inserts a new one at the front (create).
  SaveDraftResult saveDraft({
    required String name,
    required String destination,
    required String start,
    required String end,
    required String type,
    required String notes,
  }) {
    final trimmedName = name.trim();
    final trimmedDestination = destination.trim();
    final trimmedNotes = notes.trim();
    if (trimmedName.isEmpty || start.isEmpty || end.isEmpty) {
      return const SaveDraftResult.failure('Add a trip name and both dates');
    }
    if (end.compareTo(start) < 0) {
      return const SaveDraftResult.failure(
        'End date must be after start date',
      );
    }
    final days = _daysBetween(start, end);
    final existing = state.selectedTripId == null
        ? null
        : _find(state.selectedTripId!);
    final isNew = existing == null;
    final id = existing?.id ?? 'trip-${DateTime.now().millisecondsSinceEpoch}';
    final trip = Trip(
      id: id,
      name: trimmedName,
      destination: trimmedDestination,
      start: start,
      end: end,
      type: type,
      notes: trimmedNotes,
      days: days,
      items: existing?.items ?? const [],
    );
    final trips = isNew
        ? [trip, ...state.trips]
        : [for (final t in state.trips) t.id == id ? trip : t];
    emit(state.copyWith(trips: trips, selectedTripId: id, clearDraft: true));
    unawaited(
      _repository.saveTrip(trip, isNew: isNew).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('saveTrip failed', error, stackTrace);
        if (!isClosed) {
          // Targeted revert, evaluated against the CURRENT trips at
          // failure time, never a captured-before-the-call snapshot: a
          // brand-new trip is removed; an edited trip is restored to its
          // pre-edit value (if still present) — never a whole-trips-list
          // restore, which would clobber a different, concurrently
          // succeeding change to a DIFFERENT trip (F20-A10).
          final current = state.trips;
          final reverted = isNew
              ? current.where((t) => t.id != id).toList()
              : [for (final t in current) t.id == id ? existing : t];
          emit(state.copyWith(trips: reverted));
        }
      }),
    );
    return SaveDraftResult.success(tripId: id, wasEditing: !isNew);
  }

  int _daysBetween(String start, String end) {
    final diff =
        DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  /// Prototype `pkGenerate`: fills the selected trip's checklist only when
  /// it has none; a no-op otherwise (never resets packed flags). The
  /// repository's own [PackingRepository.generateChecklist] re-checks this
  /// "only if empty" guard against a FRESH server read (F20-A07), so this
  /// Cubit-level guard is only this single client's optimistic fast path.
  void generateChecklist(List<ClothingItem> wardrobeItems) {
    final trip = state.selectedTrip;
    if (trip == null || trip.items.isNotEmpty) return;
    final tripId = trip.id;
    final suggested = suggestions(trip, wardrobeItems);
    _replaceTrip(trip.copyWith(items: suggested));
    unawaited(
      _repository.generateChecklist(tripId, suggested).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('generateChecklist failed', error, stackTrace);
        if (!isClosed) {
          final current = _find(tripId);
          // Targeted revert against the CURRENT trip at failure time: only
          // undo if this trip's items still equal exactly what was
          // optimistically applied (a concurrently-succeeding, unrelated
          // change to the same trip's items in the meantime is never
          // clobbered by this rollback).
          if (current != null && listEquals(current.items, suggested)) {
            _replaceTrip(current.copyWith(items: const []));
          }
        }
      }),
    );
  }

  /// Prototype `pkToggle`.
  void toggle(String key) {
    final trip = state.selectedTrip;
    if (trip == null) return;
    final tripId = trip.id;
    _replaceTrip(
      trip.copyWith(
        items: [
          for (final i in trip.items)
            i.key == key ? i.copyWith(packed: !i.packed) : i,
        ],
      ),
    );
    unawaited(
      _repository.toggle(tripId, key).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('toggle failed', error, stackTrace);
        if (!isClosed) {
          // Targeted revert: re-flip ONLY this item's packed flag against
          // the CURRENT trip at failure time, never a captured-whole-
          // trips-list-before-the-call restore (the Task 4/F17, Task 6/F19
          // lesson, baked in here from the start) — a concurrently-
          // succeeding, unrelated change to a DIFFERENT trip, or a
          // DIFFERENT item of the SAME trip, is never touched (F20-A09).
          final current = _find(tripId);
          if (current == null) return;
          _replaceTrip(
            current.copyWith(
              items: [
                for (final i in current.items)
                  i.key == key ? i.copyWith(packed: !i.packed) : i,
              ],
            ),
          );
        }
      }),
    );
  }

  /// Prototype `pkRemove`.
  void removeItem(String key) {
    final trip = state.selectedTrip;
    if (trip == null) return;
    final tripId = trip.id;
    final removed = trip.items.firstWhere((i) => i.key == key);
    _replaceTrip(
      trip.copyWith(items: trip.items.where((i) => i.key != key).toList()),
    );
    unawaited(
      _repository.removeItem(tripId, key).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('removeItem failed', error, stackTrace);
        if (!isClosed) {
          // Targeted revert: re-insert ONLY the removed item against the
          // CURRENT trip at failure time, never a whole-list restore.
          final current = _find(tripId);
          if (current == null) return;
          if (current.items.any((i) => i.key == key)) return;
          _replaceTrip(current.copyWith(items: [...current.items, removed]));
        }
      }),
    );
  }

  /// Prototype `pkAddWardrobe`: no-op if already added (deduped by
  /// `wardrobeId`). The repository's own [PackingRepository.addWardrobe]
  /// re-checks this dedupe against a FRESH server read (feature doc §12),
  /// so this Cubit-level guard is only this single client's optimistic
  /// fast path.
  void addWardrobe(ClothingItem item) {
    final trip = state.selectedTrip;
    if (trip == null) return;
    if (trip.items.any((i) => i.wardrobeId == item.id)) return;
    final tripId = trip.id;
    final newItem = PackingItem(
      key: item.id,
      label: item.name,
      wardrobeId: item.id,
    );
    _replaceTrip(trip.copyWith(items: [...trip.items, newItem]));
    unawaited(
      _repository.addWardrobe(tripId, newItem).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('addWardrobe failed', error, stackTrace);
        if (!isClosed) {
          // Targeted revert: drop ONLY the added item against the CURRENT
          // trip at failure time.
          final current = _find(tripId);
          if (current == null) return;
          _replaceTrip(
            current.copyWith(
              items: current.items.where((i) => i.key != newItem.key).toList(),
            ),
          );
        }
      }),
    );
  }

  /// Prototype `pkCustom`: a blank/whitespace-only label is ignored.
  void addCustom(String label) {
    final trip = state.selectedTrip;
    final trimmed = label.trim();
    if (trip == null || trimmed.isEmpty) return;
    final tripId = trip.id;
    final key = 'extra-${DateTime.now().millisecondsSinceEpoch}';
    final newItem = PackingItem(key: key, label: trimmed);
    _replaceTrip(trip.copyWith(items: [...trip.items, newItem]));
    unawaited(
      _repository.addCustom(tripId, newItem).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('addCustom failed', error, stackTrace);
        if (!isClosed) {
          // Targeted revert: drop ONLY the added item against the CURRENT
          // trip at failure time.
          final current = _find(tripId);
          if (current == null) return;
          _replaceTrip(
            current.copyWith(
              items: current.items.where((i) => i.key != key).toList(),
            ),
          );
        }
      }),
    );
  }

  /// Prototype `pkDelete`.
  void deleteSelectedTrip() {
    final id = state.selectedTripId;
    if (id == null) return;
    final removed = _find(id);
    emit(
      state.copyWith(
        trips: state.trips.where((t) => t.id != id).toList(),
        clearSelectedTripId: true,
      ),
    );
    unawaited(
      _repository.deleteTrip(id).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('deleteTrip failed', error, stackTrace);
        if (!isClosed && removed != null) {
          // Targeted revert: re-insert ONLY the deleted trip, against the
          // CURRENT trips at failure time, if it isn't already present
          // again (e.g. restored by a reconciling watchTrips() snapshot).
          if (state.trips.any((t) => t.id == id)) return;
          emit(state.copyWith(trips: [removed, ...state.trips]));
        }
      }),
    );
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
