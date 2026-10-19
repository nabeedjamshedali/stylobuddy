import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/backend/firestore_service.dart';
import '../../../shared/models/planned_entry.dart';
import 'planner_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes under
/// `users/{uid}/plannedEntries/{dateKey}` (schema doc §5) — the Firestore
/// document ID **is** the `'yyyy-MM-dd'` key string itself, verbatim; there
/// is no separate `date` field and no duplicated `id` field on the document
/// (this collection is the one exception to the "duplicate id on doc"
/// convention used elsewhere — F17-A03, F17 doc §13).
///
/// `plan`/`remove` are plain `set()`/`delete()` calls, **not**
/// `runTransaction` (F17-A06) — unlike F16's `logWear`/`removeWear`, neither
/// operation reads a prior value to compute a new one: `plan` fully
/// overwrites a date's entry with the caller-supplied [PlannedEntry];
/// `remove` deletes unconditionally.
class FirestorePlannerRepository implements PlannerRepository {
  FirestorePlannerRepository(FirestoreService service, String uid)
    : _collection = service.subcollection<PlannedEntry>(
        uid,
        'plannedEntries',
        _fromFirestore,
        _toFirestore,
      );

  final CollectionReference<PlannedEntry> _collection;

  static PlannedEntry _fromFirestore(Map<String, dynamic> data, String id) =>
      PlannedEntry(
        outfitId: (data['outfitId'] as num?)?.toInt() ?? 0,
        occasion: data['occasion'] as String? ?? '',
      );

  // No 'id'/'date' field written here — the key string itself is the
  // document ID (F17-A03). Only outfitId/occasion are ever written.
  static Map<String, dynamic> _toFirestore(PlannedEntry entry) => {
    'outfitId': entry.outfitId,
    'occasion': entry.occasion,
  };

  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() =>
      _collection.snapshots().map(
        (snapshot) => {
          for (final doc in snapshot.docs) doc.id: doc.data(),
        },
      );

  @override
  Future<void> plan(String key, PlannedEntry entry) =>
      _collection.doc(key).set(entry);

  @override
  Future<void> remove(String key) => _collection.doc(key).delete();
}
