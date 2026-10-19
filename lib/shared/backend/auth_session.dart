import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Synchronously reads the currently signed-in uid (or `null` for
/// guest/signed-out) directly from `FirebaseAuth.instance.currentUser`, with
/// no stream involved.
///
/// This exists specifically to be passed as a `StreamBuilder`'s
/// `initialData` (see `lib/app.dart`): [uidChanges]'s own first emission is
/// always delivered asynchronously (`StreamController.add` never delivers
/// synchronously, even when seeded from this same value), so a
/// `StreamBuilder` listening to [uidChanges] alone still sees
/// `snapshot.data == null` on its very first build regardless of the real
/// signed-in state — a signed-in cold start would flash the guest subtree
/// for one frame before the stream's first event arrives. Supplying
/// [currentUid] as `initialData` makes the first build already correct, so
/// that flash cannot happen.
///
/// Never throws: if resolving `FirebaseAuth.instance` itself throws
/// synchronously (e.g. a widget test that pumps `StyloBuddyApp` without ever
/// calling `Firebase.initializeApp()`), this returns `null` (signed-out)
/// instead of propagating the exception into `build()` — the same guard
/// [uidChanges] applies for the same reason (F14-A14).
String? currentUid() {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null || uid.isEmpty ? null : uid;
  } catch (error) {
    if (kDebugMode) {
      debugPrint(
        'currentUid(): FirebaseAuth.instance unavailable ($error); falling back to signed-out.',
      );
    }
    return null;
  }
}

/// Wraps [FirebaseAuth]'s auth-state stream into the single `uid` (or
/// `null`) signal every root Cubit's construction is keyed on (architecture
/// D3). `null` means guest/signed-out; a non-empty string is the signed-in
/// user's uid.
///
/// - De-duplicated via [Stream.distinct]: a repeated identical value (same
///   uid twice, or `null` twice) in a row is collapsed to one emission, so a
///   `StreamBuilder` keyed on this stream never rebuilds its subtree for a
///   duplicate emission (F14-A04).
/// - An empty-string uid (not expected from the real SDK, defended against
///   per the feature doc's edge cases) is treated the same as `null`.
/// - Never throws into its listener: if the underlying [authStateChanges]
///   stream errors (e.g. a plugin failure), that is treated as a
///   signed-out transition (`null`) rather than propagated, so `app.dart`'s
///   `StreamBuilder` falls back to guest mode instead of a crashed tree.
///   The same applies if resolving `FirebaseAuth.instance` itself throws
///   synchronously (e.g. a widget test that pumps `StyloBuddyApp` without
///   ever calling `Firebase.initializeApp()`) — a signed-out-only stream is
///   returned instead of letting the exception propagate into `build()`.
///
/// Important: this stream's own first emission is always asynchronous, even
/// on the real `FirebaseAuth.instance` path — a `StreamBuilder` subscribed
/// to only this stream will still see `snapshot.data == null` on its very
/// first build regardless of the actual signed-in state. Pair this stream
/// with [currentUid] as the `StreamBuilder`'s `initialData` (see
/// `lib/app.dart`) to avoid a one-frame guest flash on a signed-in cold
/// start; this function alone does not prevent that.
///
/// [authStateChanges] is an injection point for tests (a fake stream of
/// [User]/`null` events); it defaults to the real
/// `FirebaseAuth.instance.authStateChanges()`.
Stream<String?> uidChanges({Stream<User?>? authStateChanges}) {
  Stream<User?> source;
  if (authStateChanges != null) {
    source = authStateChanges;
  } else {
    try {
      source = FirebaseAuth.instance.authStateChanges();
    } catch (error) {
      // Expected in a widget test that never calls Firebase.initializeApp
      // (F14-A14) — `FirebaseAuth.instance` throws synchronously in that
      // case. Any *other* synchronous failure here would be unexpected, so
      // surface it in debug builds rather than silently falling back to
      // guest mode with no trace of why.
      if (kDebugMode) {
        debugPrint(
          'uidChanges(): FirebaseAuth.instance unavailable ($error); falling back to signed-out.',
        );
      }
      return Stream<String?>.value(null);
    }
  }

  final controller = StreamController<String?>();
  late final StreamSubscription<User?> subscription;

  void addUid(User? user) {
    final uid = user?.uid;
    controller.add(uid == null || uid.isEmpty ? null : uid);
  }

  subscription = source.listen(
    addUid,
    onError: (Object _, StackTrace _) => controller.add(null),
    onDone: controller.close,
  );
  controller.onCancel = subscription.cancel;

  return controller.stream.distinct();
}
