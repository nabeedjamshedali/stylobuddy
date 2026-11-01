import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../shared/backend/firestore_service.dart';
import 'shopping_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes of
/// **only** the `wishlist` key on `users/{uid}` (schema doc §1), the same
/// document `FirestoreProfileRepository` (F18) owns every other field of.
///
/// This is the sole post-bootstrap writer of `wishlist` (F19 doc §2/§4);
/// every write below is a targeted field update touching exactly one key,
/// never a whole-document `set()` and never a payload that includes any
/// `ProfileState`-owned key — the binding non-clobber requirement carried
/// from F18's own Important #5 lesson, applied here in the other direction
/// (F19 doc §6, §11 A05/A06/A07).
///
/// [setMembership] takes the add-or-remove decision as an explicit `bool`
/// already made by `ShoppingCubit` — it does **not** read the document
/// first to re-derive that decision itself. This replaced an earlier
/// `toggleWishlist(id)` design (fix round, Task 6 review) where this
/// repository re-read the document and independently re-decided
/// add-vs-remove; when the Cubit's own state and the document had
/// diverged (pre-first-snapshot, mid-rollback, or any ordinary race), the
/// two decisions could disagree, so the UI could toast "saved" while the
/// document actually ended up with the item removed. `FieldValue.
/// arrayUnion`/`arrayRemove` make the write unambiguous *and* avoid the
/// read-then-write window entirely — no `get()` before the `set()`, so
/// there is no race window left for a concurrent write to land in between.
class FirestoreShoppingRepository implements ShoppingRepository {
  FirestoreShoppingRepository(FirestoreService service, String uid)
    : _doc = service.userDoc(uid);

  /// Test-only constructor that accepts a [DocumentReference] directly,
  /// bypassing [FirestoreService] — used by F19-A07 to inject a
  /// key-recording wrapper around a real document and observe exactly the
  /// field-key set every write touches, rather than inferring it from
  /// before/after value comparisons alone.
  @visibleForTesting
  FirestoreShoppingRepository.withDocument(this._doc);

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
  Future<void> setMembership(String id, bool add) {
    // Targeted update touching only the 'wishlist' key — never a
    // whole-document set() and never a payload with any other key (F19
    // doc §6, the binding non-clobber constraint). arrayUnion/arrayRemove
    // are themselves idempotent (adding an already-present id, or removing
    // an already-absent one, is a no-op), so no prior read is needed to
    // decide what to write — the Cubit's `add` intent is carried out
    // verbatim.
    return _doc.set({
      'wishlist': add
          ? FieldValue.arrayUnion([id])
          : FieldValue.arrayRemove([id]),
    }, SetOptions(merge: true));
  }
}
