import '../models/trip.dart';
import '../models/trip_draft.dart';

class PackingState {
  const PackingState({
    this.trips = const [],
    this.selectedTripId,
    this.draft,
  });

  final List<Trip> trips;

  /// Prototype `S.tripEditing`: both "trip open on packing-preview/
  /// packing-list/packing-add" and "trip being edited on new-trip"; `null`
  /// means no trip selected, or the new-trip form is creating a trip.
  final String? selectedTripId;

  /// Prototype `S.tripDraft`: pre-fill values for the new-trip form; `null`
  /// when the form has not been opened.
  final TripDraft? draft;

  Trip? get selectedTrip {
    for (final trip in trips) {
      if (trip.id == selectedTripId) return trip;
    }
    return null;
  }

  PackingState copyWith({
    List<Trip>? trips,
    String? selectedTripId,
    bool clearSelectedTripId = false,
    TripDraft? draft,
    bool clearDraft = false,
  }) => PackingState(
    trips: trips ?? this.trips,
    selectedTripId: clearSelectedTripId
        ? null
        : (selectedTripId ?? this.selectedTripId),
    draft: clearDraft ? null : (draft ?? this.draft),
  );
}
