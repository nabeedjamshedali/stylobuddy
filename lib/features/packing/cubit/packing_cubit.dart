import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/models/clothing_item.dart';
import '../models/packing_item.dart';
import '../models/trip.dart';
import '../models/trip_draft.dart';
import 'packing_state.dart';
import 'save_draft_result.dart';

/// Feature-local state for the V16 packing assistant (`app.js:199-219`).
/// Trips live in memory only (no persistence yet, see F10 §3).
class PackingCubit extends Cubit<PackingState> {
  PackingCubit() : super(const PackingState());

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
    final trips = existing != null
        ? [for (final t in state.trips) t.id == id ? trip : t]
        : [trip, ...state.trips];
    emit(
      state.copyWith(trips: trips, selectedTripId: id, clearDraft: true),
    );
    return SaveDraftResult.success(tripId: id, wasEditing: existing != null);
  }

  int _daysBetween(String start, String end) {
    final diff =
        DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  /// Prototype `pkGenerate`: fills the selected trip's checklist only when
  /// it has none; a no-op otherwise (never resets packed flags).
  void generateChecklist(List<ClothingItem> wardrobeItems) {
    final trip = state.selectedTrip;
    if (trip == null || trip.items.isNotEmpty) return;
    _replaceTrip(trip.copyWith(items: suggestions(trip, wardrobeItems)));
  }

  /// Prototype `pkToggle`.
  void toggle(String key) {
    final trip = state.selectedTrip;
    if (trip == null) return;
    _replaceTrip(
      trip.copyWith(
        items: [
          for (final i in trip.items)
            i.key == key ? i.copyWith(packed: !i.packed) : i,
        ],
      ),
    );
  }

  /// Prototype `pkRemove`.
  void removeItem(String key) {
    final trip = state.selectedTrip;
    if (trip == null) return;
    _replaceTrip(
      trip.copyWith(items: trip.items.where((i) => i.key != key).toList()),
    );
  }

  /// Prototype `pkAddWardrobe`: no-op if already added (deduped by
  /// `wardrobeId`).
  void addWardrobe(ClothingItem item) {
    final trip = state.selectedTrip;
    if (trip == null) return;
    if (trip.items.any((i) => i.wardrobeId == item.id)) return;
    _replaceTrip(
      trip.copyWith(
        items: [
          ...trip.items,
          PackingItem(key: item.id, label: item.name, wardrobeId: item.id),
        ],
      ),
    );
  }

  /// Prototype `pkCustom`: a blank/whitespace-only label is ignored.
  void addCustom(String label) {
    final trip = state.selectedTrip;
    final trimmed = label.trim();
    if (trip == null || trimmed.isEmpty) return;
    final key = 'extra-${DateTime.now().millisecondsSinceEpoch}';
    _replaceTrip(
      trip.copyWith(items: [...trip.items, PackingItem(key: key, label: trimmed)]),
    );
  }

  /// Prototype `pkDelete`.
  void deleteSelectedTrip() {
    final id = state.selectedTripId;
    if (id == null) return;
    emit(
      state.copyWith(
        trips: state.trips.where((t) => t.id != id).toList(),
        clearSelectedTripId: true,
      ),
    );
  }
}
