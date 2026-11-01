import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';

/// Dual-mode repository interface (architecture D2) for `Outfit`/`WearEvent`
/// persistence: [InMemoryOutfitsRepository] for guests,
/// [FirestoreOutfitsRepository] for signed-in users, both implementing this
/// one surface so [OutfitsCubit] never needs to know which it has.
///
/// `byId`/`wearEvents` stay Cubit-local, synchronous lookups over
/// already-streamed state (F16 feature doc §6) — they are deliberately not
/// part of this interface.
///
/// [saveOrFind]/[upsertManual] accept the Cubit's currently-held `outfits`
/// list (`current`) rather than re-reading it themselves: the
/// "reuse an identical outfit"/"edit in place" checks are matches against
/// already-streamed state, mirroring how `WardrobeCubit` already behaves
/// (F16 feature doc §6/§13 — a documented, not a silently-decided, gap
/// under true multi-device concurrency).
///
/// Implementation note (deviation from the feature doc's literal §6
/// pseudocode, recorded here per its own §13 precedent): [upsertManual]
/// takes the already-fully-built `candidate` `Outfit` (final `id` already
/// decided by the Cubit's own `_newId()`) rather than raw
/// name/items/occasion fields. Passing raw fields would let this
/// repository's own "create" branch independently invent a *different* id
/// than the one `OutfitsCubit` already optimistically emitted into its
/// local state, which would desync the Firestore document id from the
/// locally-held `Outfit.id` the moment `watchOutfits()`'s next snapshot
/// reconciles state (an id a user may already be mid-navigation on, e.g.
/// `/saved/{id}`). [saveOrFind] does not have this problem because its
/// `draft` parameter is already a full `Outfit` object carrying its final
/// id by the time it reaches this repository.
abstract class OutfitsRepository {
  /// Live collection stream (architecture D6). Never performs a write as a
  /// side effect of being listened to.
  Stream<List<Outfit>> watchOutfits();

  /// Live collection stream (architecture D6), ordered `timestamp`
  /// descending, tie-broken by `id` descending for equal timestamps
  /// (matching `OutfitsCubit.wearEvents()`'s existing sort).
  Stream<List<WearEvent>> watchWearEvents();

  /// Reuses an existing outfit from [current] with identical items
  /// (order-sensitive), or persists [draft] (whose `id` is already final)
  /// as a new outfit and returns it.
  Future<Outfit> saveOrFind(Outfit draft, {required List<Outfit> current});

  /// Persists [candidate] — either replacing the document matching
  /// [editingId] in place (name/items/occasion only; `worn` untouched), or
  /// creating a brand-new document when [editingId] is `null`/not found in
  /// [current]. See the class doc for why [candidate] (not raw fields) is
  /// the parameter.
  Future<Outfit> upsertManual({
    required Outfit candidate,
    int? editingId,
    required List<Outfit> current,
  });

  /// Removes the outfit document. Any `WearEvent`s referencing it are left
  /// untouched (history retained, per `03-domain-model.md`).
  Future<void> delete(int id);

  /// Read-modify-write: increments the target outfit's `worn` by exactly 1
  /// (off a fresh server-side read, not [outfit]) and writes a `WearEvent`
  /// document at [event]'s own `id` (already minted by the Cubit, for the
  /// same id-consistency reason [upsertManual]'s `candidate` is — see the
  /// class doc), with its `name`/`occasion`/`items` snapshotted from that
  /// same server-side read rather than from [outfit] or [event]. [outfit]
  /// and [event] are routing information only (which documents to touch,
  /// and which id to write the new event under), never the source of truth
  /// for the increment or the snapshot. A no-op, not a crash, if the outfit
  /// no longer exists.
  Future<void> logWear(
    int outfitId, {
    required Outfit outfit,
    required WearEvent event,
  });

  /// Read-modify-write: deletes the target `WearEvent` document and
  /// decrements its parent outfit's `worn` by exactly 1, clamped at 0, off
  /// a fresh server-side read. [event] is routing information only. A
  /// no-op, not a crash, if the event no longer exists.
  Future<void> removeWear(int eventId, {required WearEvent event});
}
