import '../../../shared/models/planned_entry.dart';

/// Dual-mode repository interface (architecture D2): [InMemoryPlannerRepository]
/// for guests, [FirestorePlannerRepository] for signed-in users, both
/// implementing this one surface so [PlannerCubit] never needs to know which
/// it has.
///
/// `PlannerCubit`'s other public methods (`select`, `selectDate`, `navigate`,
/// `startScheduling`, `clearEditing`, `label`, `keyFor`) are pure
/// transformations of transient, non-persisted state (schema doc §7) and are
/// deliberately **not** part of this interface — see F17 doc §6/§13.
abstract class PlannerRepository {
  /// Live collection stream (architecture D6) — Firestore's `snapshots()`
  /// for the signed-in implementation, a seeded in-memory stream for the
  /// guest implementation, keyed by each entry's `'yyyy-MM-dd'` date key.
  Stream<Map<String, PlannedEntry>> watchPlanned();

  /// Fully overwrites (never merges) the entry at [key] — matches
  /// `PlannerCubit.plan`'s existing `{...state.planned, key: entry}`
  /// overwrite semantics exactly (F17-A02).
  Future<void> plan(String key, PlannedEntry entry);

  /// Deletes the entry at [key]; a no-op (never a thrown error) when [key]
  /// has no existing entry (F17-A05).
  Future<void> remove(String key);
}
