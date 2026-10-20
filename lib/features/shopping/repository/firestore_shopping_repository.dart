import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/backend/firestore_service.dart';
import 'shopping_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes of
/// **only** the `wishlist` key on `users/{uid}` (schema doc §1), the same
/// document `FirestoreProfileRepository` (F18) owns every other field of.
///
/// This is the sole post-bootstrap writer of `wishlist` (F19 doc §2/§4);
/// every write below is a targeted merge-set touching exactly one key,
/// never a whole-document `set()` and never a payload that includes any
/// `ProfileState`-owned key — the binding non-clobber requirement carried
/// from F18's own Important #5 lesson, applied here in the other direction
/// (F19 doc §6, §11 A05/A06/A07).
///
/// [toggleWishlist] reads the current array off a single `get()` (not a
/// cached `watchWishlist()` value) and writes back the add-or-remove
/// result in one targeted call — a plain read-then-write, deliberately
/// without `runTransaction` (F19 doc §13's settled decision: a double-tap
/// race is an accepted, pre-existing-class risk, not a correctness
/// requirement this feature must close).
class FirestoreShoppingRepository implements ShoppingRepository {
  FirestoreShoppingRepository(FirestoreService service, String uid)
    : _doc = service.userDoc(uid);

  final DocumentReference<Map<String, dynamic>> _doc;

  /// Missing key -> `[]` (F19-A17); explicitly-present (even if empty) ->
  /// read back verbatim, never coerced back to the default — same
  /// missing-vs-empty convention as `FirestoreProfileRepository._listField`
  /// (F18), applied here to the one field this repository owns.
  static List<String> _wishlistField(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('wishlist') || data['wishlist'] == null) {
      return const [];
    }
    return List<String>.from(data['wishlist'] as List);
  }

  @override
  Stream<List<String>> watchWishlist() =>
      _doc.snapshots().map((snapshot) => _wishlistField(snapshot.data()));

  @override
  Future<bool> toggleWishlist(String id) async {
    final snapshot = await _doc.get();
    final current = _wishlistField(snapshot.data());
    final added = !current.contains(id);
    final next = added
        ? [...current, id]
        : current.where((x) => x != id).toList();
    // Targeted merge-set touching only the 'wishlist' key — never a
    // whole-document set() and never a payload with any other key (F19
    // doc §6, the binding non-clobber constraint).
    await _doc.set({'wishlist': next}, SetOptions(merge: true));
    return added;
  }
}
