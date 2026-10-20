import '../models/packing_item.dart';
import '../models/trip.dart';

/// Dual-mode repository interface (architecture D2, D6) for `Trip`
/// persistence: [InMemoryPackingRepository] for guests,
/// [FirestorePackingRepository] for signed-in users, both implementing this
/// one surface so `PackingCubit` never needs to know which it has.
///
/// Interface shape per the Task 7 controller ruling (binding, resolves the
/// feature doc's §13 open questions — see `docs/features/F20-packing-backend.md`
/// §6/§13): ONE [saveTrip] write method matching `PackingCubit.saveDraft`'s
/// create-or-update shape (not a split `createTrip`/`updateTripDetails`),
/// and FIVE separately-named items-mutating methods ([toggle], [removeItem],
/// [addWardrobe], [addCustom], [generateChecklist]) mirroring
/// `PackingCubit`'s own real method names (not one generic
/// `mutateItems(tripId, transform)` method) — each implementation may share
/// a private transaction-based helper internally, but this public surface
/// exposes the five real names.
///
/// `PackingState.{selectedTripId,draft}` get no repository method, ever —
/// named transient exclusions (schema doc §7); `TripDraft` is never
/// persisted.
abstract class PackingRepository {
  /// Live collection stream (architecture D6). Never performs a write as a
  /// side effect of being listened to.
  Stream<List<Trip>> watchTrips();

  /// Create-or-update, matching `saveDraft`'s existing branching: when
  /// [isNew] is `true` this is a brand-new trip (the whole document,
  /// `items` always `[]` at creation); when `false` this is a **targeted**
  /// write touching every `Trip` field EXCEPT `items` (deliberately
  /// excluded so a concurrently in-flight items-mutating call on the same
  /// document is never clobbered — feature doc §6).
  Future<void> saveTrip(Trip trip, {required bool isNew});

  /// Flips the packed flag of the item keyed [key] on trip [tripId], off a
  /// fresh read of the trip's current `items` (never a cached argument). A
  /// no-op (not a crash) if [tripId] no longer exists.
  Future<void> toggle(String tripId, String key);

  /// Removes the item keyed [key] from trip [tripId]'s `items`, off a
  /// fresh read. A no-op if [tripId] no longer exists.
  Future<void> removeItem(String tripId, String key);

  /// Appends [item] to trip [tripId]'s `items` unless an item with the same
  /// `wardrobeId` is already present in a FRESH read of the trip's current
  /// `items` (never the caller's cached copy) — a strictly stronger dedupe
  /// guarantee than a single client's own in-memory check. A no-op if
  /// [tripId] no longer exists.
  Future<void> addWardrobe(String tripId, PackingItem item);

  /// Appends the already-validated custom [item] to trip [tripId]'s
  /// `items`. A no-op if [tripId] no longer exists.
  Future<void> addCustom(String tripId, PackingItem item);

  /// Fills trip [tripId]'s `items` with [suggested] only when a FRESH read
  /// of the trip's current `items` is empty (never re-fills or resets
  /// packed flags on a non-empty read). A no-op if [tripId] no longer
  /// exists.
  Future<void> generateChecklist(String tripId, List<PackingItem> suggested);

  /// Removes the trip document entirely.
  Future<void> deleteTrip(String tripId);
}
