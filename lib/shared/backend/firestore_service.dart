import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

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

  /// Serializes [runBootstrapIfNeeded] calls per `FirebaseFirestore`
  /// instance/uid so a racing pair of callers against the same backing
  /// store still only *commits* `seeded: true` once. Real Firestore's own
  /// transaction retry already guarantees the commit is at most once
  /// server-side in production — but it does this by retrying the whole
  /// transaction handler (including [seedWriter]) on contention, not by
  /// running [seedWriter] itself exactly once; see [runBootstrapIfNeeded]'s
  /// docstring. This app-level lock makes the *at-most-one-commit*
  /// guarantee hold in tests that use a non-atomic fake/in-memory Firestore
  /// double (architecture D5), which has no retry-on-contention behavior of
  /// its own to rely on.
  ///
  /// Keyed by `'${identityHashCode(_firestore)}/$uid'` rather than uid
  /// alone, since two [FirestoreService] instances backed by different
  /// [FirebaseFirestore] instances/doubles (e.g. in different tests) must
  /// not share a lock. (`FirebaseFirestore.app`/`.databaseId` aren't used
  /// for this because the fake double this app's tests inject doesn't
  /// implement `.app`.) Each entry is removed once that attempt completes,
  /// so this map never grows unbounded.
  static final Map<String, Future<void>> _bootstrapLocks = {};

  /// Test-only visibility into [_bootstrapLocks]'s size, so a test can
  /// assert a settled attempt's entry was actually pruned rather than
  /// inferring it indirectly.
  @visibleForTesting
  static int get bootstrapLockCount => _bootstrapLocks.length;

  String _lockKey(String uid) => '${identityHashCode(_firestore)}/$uid';

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
    return userDoc(uid)
        .collection(name)
        .withConverter<T>(
          fromFirestore: (snapshot, _) => fromFirestore(
            snapshot.data() ?? const <String, dynamic>{},
            snapshot.id,
          ),
          toFirestore: (value, _) => toFirestore(value),
        );
  }

  /// Commits `seeded: true` at most once per [uid] (architecture D5),
  /// guarded by `users/{uid}.seeded`. A missing field and an explicit
  /// `false` are treated identically (F14-A15/A16); `true` never invokes
  /// [seedWriter] again (F14-A17). If [seedWriter] throws, the transaction
  /// aborts and `seeded` is left unset, so a later call gets a clean retry
  /// rather than a permanently half-seeded user (F14-A19).
  ///
  /// IMPORTANT — this guarantees the **commit** happens at most once; it
  /// does NOT guarantee [seedWriter] itself is only ever *invoked* once.
  /// Real Firestore retries the whole transaction handler (re-running
  /// [seedWriter]) when it loses a commit race on contention, so
  /// [seedWriter] must perform all of its writes through the given [tx]
  /// with no side effects outside the transaction (no network calls, no
  /// writes via a different client/service) — it must be safe to run more
  /// than once and simply discard its effects if the transaction is
  /// retried or ultimately aborted.
  ///
  /// A transaction fails outright while the device is offline (no local
  /// cache fallback for writes); callers (Task 5+) must handle that
  /// failure path themselves — this method does not retry or swallow it.
  Future<void> runBootstrapIfNeeded(
    String uid,
    Future<void> Function(
      Transaction tx,
      DocumentReference<Map<String, dynamic>> userDoc,
    )
    seedWriter,
  ) {
    final key = _lockKey(uid);
    final previous = _bootstrapLocks[key] ?? Future<void>.value();
    final gate = previous
        .catchError((_) {})
        .then((_) => _runBootstrap(uid, seedWriter));
    final stored = gate.catchError((_) {});
    _bootstrapLocks[key] = stored;
    // Prune once this attempt settles (success or failure) so a uid that
    // will never be retried doesn't leave a permanent entry behind. Only
    // remove the entry if it's still *this* attempt's future — a
    // genuinely-concurrent racing call may already have chained its own
    // future in behind `stored` (replacing the map entry) before this
    // runs, and that newer entry must not be clobbered.
    unawaited(
      stored.whenComplete(() {
        if (identical(_bootstrapLocks[key], stored)) {
          _bootstrapLocks.remove(key);
        }
      }),
    );
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
