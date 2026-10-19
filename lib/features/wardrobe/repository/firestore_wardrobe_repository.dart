import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/backend/firestore_service.dart';
import '../../../shared/models/clothing_item.dart';
import 'wardrobe_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes under
/// `users/{uid}/wardrobeItems/{itemId}` (schema doc §2) — `itemId` is
/// `ClothingItem.id` verbatim, never re-derived or re-hashed (F15-A02).
/// [watchItems] performs zero writes of its own on subscription (F15-A22);
/// the one-time bootstrap seed is a different caller's job entirely
/// (architecture D5).
class FirestoreWardrobeRepository implements WardrobeRepository {
  FirestoreWardrobeRepository(FirestoreService service, String uid)
    : _collection = service.subcollection<ClothingItem>(
        uid,
        'wardrobeItems',
        _fromFirestore,
        _toFirestore,
      );

  final CollectionReference<ClothingItem> _collection;

  static ClothingItem _fromFirestore(Map<String, dynamic> data, String id) =>
      ClothingItem(
        id: id,
        name: data['name'] as String? ?? '',
        category: data['category'] as String? ?? '',
        color: data['color'] as String? ?? '',
        occasion: data['occasion'] as String? ?? '',
        season: data['season'] as String? ?? 'All season',
        wears: (data['wears'] as num?)?.toInt() ?? 0,
        sourceId: data['sourceId'] as String?,
        // Missing field, explicit null, and '' are all normalized to null
        // here (F15-A15/A16) — only a non-empty string counts as "has a
        // photo".
        imageUrl: _normalizeImageUrl(data['imageUrl'] as String?),
      );

  static String? _normalizeImageUrl(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  static Map<String, dynamic> _toFirestore(ClothingItem item) => {
    // 'id' duplicated on the document per the schema doc's convention
    // (F15-A03), consistent with F14-A12's shared converter behavior.
    'id': item.id,
    'name': item.name,
    'category': item.category,
    'color': item.color,
    'occasion': item.occasion,
    'season': item.season,
    'wears': item.wears,
    'sourceId': item.sourceId,
    'imageUrl': item.imageUrl,
  };

  @override
  Stream<List<ClothingItem>> watchItems() => _collection.snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
  );

  @override
  Future<void> addItem(ClothingItem item) =>
      _collection.doc(item.id).set(item);

  @override
  Future<void> addItems(List<ClothingItem> items) async {
    final batch = _collection.firestore.batch();
    for (final item in items) {
      batch.set(_collection.doc(item.id), item);
    }
    await batch.commit();
  }

  @override
  Future<void> updateItem(ClothingItem item) =>
      // A full `.set()` (not `.update()`) replaces exactly the fields of
      // the matching document (F15-A04) — no other document is touched.
      _collection.doc(item.id).set(item);

  @override
  Future<void> removeItem(String id) => _collection.doc(id).delete();

  @override
  Future<void> adjustWears(List<String> ids, int delta) async {
    // Read-modify-write inside a single transaction: `OutfitsCubit`'s
    // log-wear/undo-wear can both call this unawaited and concurrently
    // (e.g. a rapid log-then-undo from the same user), and a plain
    // `get()` -> `batch.set()` pair (no isolation between the two) would
    // let the slower call's read overwrite the faster call's write,
    // silently losing a +1/-1 on the persisted `wears` count. Firestore's
    // transaction retries the whole closure on write-conflict, so by the
    // time this commits, every read inside it reflects the latest
    // committed value.
    await _collection.firestore.runTransaction((tx) async {
      // Firestore transactions require every read to happen before any
      // write within the same transaction (real Firestore enforces this
      // server-side; the fake double enforces it too) — so every `tx.get`
      // across all [ids] must finish before the first `tx.set`, not
      // interleaved per id as a naive loop would do.
      final docRefs = [for (final id in ids) _collection.doc(id)];
      final snapshots = [for (final docRef in docRefs) await tx.get(docRef)];
      for (var i = 0; i < docRefs.length; i++) {
        final current = snapshots[i].data();
        if (current == null) continue;
        // Never drives wears below 0 (F15-A06), mirroring WardrobeCubit's
        // existing clamp invariant, now also enforced at the write layer.
        final next = current.copyWith(
          wears: (current.wears + delta).clamp(0, 1 << 30),
        );
        tx.set(docRefs[i], next);
      }
    });
  }
}
