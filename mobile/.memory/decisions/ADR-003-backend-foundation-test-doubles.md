# ADR-003 — Firestore/Auth test doubles and the non-initialized-Firebase guard

**Date:** 2026-10-19 · **Status:** Accepted · **Affects:** F14, all later backend-wiring tasks (F15+)

## Context

F14 needed to unit-test `FirestoreService.runBootstrapIfNeeded` (a Firestore transaction) and
`uidChanges()` (wraps `FirebaseAuth.authStateChanges()`) without a real Firebase project, per the
plan's "use a fake/in-memory Firestore double, not the real emulator" instruction. Separately,
wiring `lib/app.dart`'s `StreamBuilder` to default to the real `uidChanges()` broke the entire
existing widget-test suite: every pre-existing test that pumps `StyloBuddyApp` (the smoke test and
the 14 files using `test/features/support/f02_harness.dart`'s `pumpApp`) never calls
`Firebase.initializeApp()`, and `FirebaseAuth.instance` throws synchronously
(`[core/no-app] No Firebase App '[DEFAULT]' has been created`) when accessed without it.

## Decision

1. Added `fake_cloud_firestore` and `mocktail` as dev dependencies. `fake_cloud_firestore`'s
   `runTransaction` does **not** simulate real optimistic-concurrency retry (it just invokes the
   handler once against a dummy `Transaction` that delegates straight to the fake store) — so
   `FirestoreService.runBootstrapIfNeeded` adds its own app-level per-uid lock
   (`Map<String, Future<void>>`) to guarantee "exactly one `seedWriter` call under a race" even
   against a non-atomic fake. Real Firestore's server-side transaction retry already provides this
   guarantee in production; the lock makes the same guarantee hold in tests. `mocktail` builds a
   `MockUser` for `User.uid` without needing to fake the rest of `firebase_auth`'s `User` surface.
2. `uidChanges()` catches a **synchronous** exception from resolving `FirebaseAuth.instance`
   (not just async errors from the stream itself) and falls back to a signed-out-only
   (`Stream.value(null)`) stream. This is a structural fix, not a workaround: it's exactly what
   F14's own degradation spec already demanded ("never throws into its listener"), and it makes
   `lib/app.dart`'s new default (`uidStream ?? uidChanges()`) safe for every existing widget test
   that never initializes Firebase — those tests continue to render guest/SeedData state exactly
   as before, with zero assertion changes (verified: full `flutter test`, 413/413 pass unchanged).

## Alternatives rejected

| Option | Why not |
|--------|---------|
| Only catch async stream errors, not the synchronous `FirebaseAuth.instance` access | Would have left every pre-existing `pumpApp`-based widget test broken — violates the plan's hard "guest-mode non-regression" gate |
| Use the real Firestore emulator for F14's unit tests | Plan brief explicitly reserves emulator-backed tests for Task 9; F14 is unit-level only |
| Hand-roll a `class _FakeUser implements User` with manual `noSuchMethod` instead of `mocktail` | Works, but `mocktail` is the standard low-ceremony choice and avoids re-deriving Mockito-style forwarding by hand |

## Consequences

- Every later task (2-8) that tests its own Firestore repository can reuse the same
  `fake_cloud_firestore`/`mocktail` pattern already proven here.
- `FirestoreService.runBootstrapIfNeeded`'s per-uid lock is process-local (a static `Map`), not
  cross-process — fine for this app (single Flutter process) but worth remembering if this class
  is ever used from a background isolate.
- Any future code that calls `FirebaseAuth.instance` directly (bypassing `auth_session.dart`)
  will **not** get this same synchronous-failure protection; `lib/app.dart` and any new shared
  auth-reading code should go through `uidChanges()`.
