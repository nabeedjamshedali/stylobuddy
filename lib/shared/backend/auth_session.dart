import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Wraps [FirebaseAuth]'s auth-state stream into the single `uid` (or
/// `null`) signal every root Cubit's construction is keyed on (architecture
/// D3). `null` means guest/signed-out; a non-empty string is the signed-in
/// user's uid.
///
/// - De-duplicated via [Stream.distinct]: a repeated identical value (same
///   uid twice, or `null` twice) in a row is collapsed to one emission, so a
///   `StreamBuilder` keyed on this stream never rebuilds its subtree for a
///   duplicate (F14-A04).
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
