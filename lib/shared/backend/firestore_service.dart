import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin path/converter helpers shared by every feature repository
/// (architecture D1, D4; schema doc root). Every path this builds is
/// scoped under `users/{uid}/...` — no helper here ever constructs an
/// unscoped/top-level collection reference.
///
/// This class builds the mechanism only (paths, converters, the bootstrap
/// transaction). No feature-specific repository is built here — a
/// feature's own `repository/` file calls into this, never a `view`/
/// `widgets` file (architecture boundary rule).
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Serializes [runBootstrapIfNeeded] calls per uid so a racing pair of
  /// callers still only runs `seedWriter` once. Real Firestore's own
  /// transaction retry already guarantees this server-side in production;
  /// this app-level lock makes the same guarantee hold in tests that use a
  /// non-atomic fake/in-memory Firestore double (architecture D5).
  static final Map<String, Future<void>> _bootstrapLocks = {};

  CollectionReference<Map<String, dynamic>> usersCollection() =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      usersCollection().doc(uid);

  /// A `users/{uid}/{name}` collection, converted to/from [T]. Always
  /// prefixed under the given [uid]'s document — never a top-level/
  /// unscoped collection path (F14-A11).
  ///
  /// Per the schema doc's "duplicate id on document" convention: the
  /// [fromFirestore] callback is handed the *real* Firestore document ID
  /// (the source of truth, F14-A13) alongside the stored field map, so a
  /// caller never has to trust a possibly-stale `id` field inside the
  /// data. [toFirestore] is expected to still write that `id` field back
  /// onto the map for query/export convenience (F14-A12) — this helper
  /// does not add it automatically, since the field's name/shape is
  /// feature-specific (`int` vs `String` ids per architecture D4); each
  /// feature's own converter is responsible for including it.
  CollectionReference<T> subcollection<T>(
    String uid,
    String name,
    T Function(Map<String, dynamic> data, String id) fromFirestore,
    Map<String, dynamic> Function(T value) toFirestore,
  ) {
    return userDoc(uid).collection(name).withConverter<T>(
      fromFirestore: (snapshot, _) => fromFirestore(
        snapshot.data() ?? const <String, dynamic>{},
        snapshot.id,
      ),
      toFirestore: (value, _) => toFirestore(value),
    );
  }

  /// Runs [seedWriter] exactly once per [uid] (architecture D5), guarded by
  /// `users/{uid}.seeded`. A missing field and an explicit `false` are
  /// treated identically (F14-A15/A16); `true` never invokes [seedWriter]
  /// again (F14-A17). If [seedWriter] throws, the transaction aborts and
  /// `seeded` is left unset, so a later call gets a clean retry rather than
  /// a permanently half-seeded user (F14-A19).
  Future<void> runBootstrapIfNeeded(
    String uid,
    Future<void> Function(
      Transaction tx,
      DocumentReference<Map<String, dynamic>> userDoc,
    )
    seedWriter,
  ) {
    final previous = _bootstrapLocks[uid] ?? Future<void>.value();
    final gate = previous
        .catchError((_) {})
        .then((_) => _runBootstrap(uid, seedWriter));
    _bootstrapLocks[uid] = gate.catchError((_) {});
    return gate;
  }

  Future<void> _runBootstrap(
    String uid,
    Future<void> Function(
      Transaction tx,
      DocumentReference<Map<String, dynamic>> userDoc,
    )
    seedWriter,
  ) {
    final doc = userDoc(uid);
    return _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(doc);
      final seeded = (snapshot.data()?['seeded'] as bool?) ?? false;
      if (seeded) return;
      await seedWriter(tx, doc);
      tx.set(doc, {'seeded': true}, SetOptions(merge: true));
    });
  }
}
