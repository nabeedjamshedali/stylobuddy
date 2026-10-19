# F14 — Backend Foundation

> The shared infrastructure every later backend-wiring feature (F15+, per Tasks 2-10 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`) builds on: the `uidChanges()` auth
> stream, `firestore_service.dart`'s path/converter helpers, the auth-gated Cubit
> reconstruction in `lib/app.dart`, and the idempotent bootstrap-seeding transaction. No
> feature-specific repository is built here. Depends on foundation 01, 02, 03, 07 and on
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D1-D6, D9) and
> `docs/superpowers/specs/2026-10-19-firestore-schema.md` §1.

**Status:** IMPLEMENTED (gate 4 pending live-verification) · **Milestone:** 2 · **Depends on:** F01, F02

---

## 1. Goal

Give every later feature task one place to get a `uid` (or `null`) from Firebase Auth, one
place to build a Firestore path/converter, and one guarantee from `lib/app.dart`: the right
set of root Cubits — in-memory for a guest, Firestore-backed for a signed-in user — exist at
all times, fully rebuilt (never patched) on every sign-in and sign-out. Nothing here persists
feature data; it's the plumbing other tasks plug into.

## 2. MVP scope

- `lib/shared/backend/auth_session.dart`: `Stream<String?> uidChanges()` wrapping
  `FirebaseAuth.instance.authStateChanges()`, de-duplicated (`.distinct()`) and mapping a
  `User?` to its `.uid` or `null`.
- `lib/shared/backend/firestore_service.dart`: `usersCollection()`, `userDoc(uid)`,
  `subcollection<T>(uid, name, fromFirestore, toFirestore)` generic helpers that always scope
  paths under `users/{uid}/...` (architecture D1, schema doc root) and follow the
  "duplicate id on document" convention (schema doc §2-6: the doc's own ID is also written as
  a plain field); and `runBootstrapIfNeeded(uid, seedWriter)` — the one reusable idempotent
  transaction mechanism behind architecture D5, guarded by `users/{uid}.seeded: bool`
  (schema doc §1). This task builds the mechanism only; no caller passes it real data yet.
  Task 5 (Profile repository) is the first real caller, writing actual `SeedData`-derived
  documents through it.
- `lib/app.dart`: `MultiBlocProvider` wrapped in a `StreamBuilder<String?>` on `uidChanges()`,
  keyed by the emitted uid (architecture D3). On every key change the whole provider subtree
  is torn down and rebuilt — every root Cubit listed in `app.dart` is a new instance, not a
  Cubit that gets re-fed data.
- Foundation doc updates: `02-architecture.md`, `07-security.md`, `01-tech-stack.md` stop
  saying "no backend"/"later" for Google Auth (already real) and Firestore (now being wired);
  `03-domain-model.md` gets a note that `seeded` is an infra-only field on the profile
  document, not a `ProfileState` field.

## 3. Later scope

- Firestore/Supabase-backed repository implementations for each feature (Tasks 2-7).
- Supabase Storage photo upload (Task 2).
- Firestore security rules hardening and emulator tests (Task 9) — this task does not touch
  `firestore.rules`.
- Edge Function scaffold (Task 10).
- Real email/password auth (Task 8) — `auth_session.dart` only reads auth state; it does not
  add sign-in methods.

## 4. Roles and permissions

Reuses the roles in `foundation/07-security.md` (guest, authenticated user). This task makes
the role switch structural: `uid == null` → guest subtree (in-memory repositories only,
D2); `uid != null` → authenticated subtree. No new role is introduced and no permission
check is added here — per-collection authorization is Task 9's `firestore.rules`.

## 5. Main flows

```text
Cold start, no Firebase user:
  app launch -> uidChanges() first event is null -> StreamBuilder key=null
  -> MultiBlocProvider built with every root Cubit's in-memory repository
  -> guest sees SeedData-backed state, identical to the current flutter test suite

Sign-in (from the existing auth flow, F02):
  user completes Google/email sign-in -> FirebaseAuth emits a User
  -> uidChanges() emits the new uid -> StreamBuilder key changes
  -> old provider subtree disposed (every root Cubit .close()s)
  -> new subtree built, repositories chosen in-memory vs Firestore per Cubit
     (today: only WardrobeRepository has a dual-mode split per D2; other
     Cubits keep their single existing repository until their own task
     lands — see §13)
  -> runBootstrapIfNeeded(uid, seedWriter) is available for a caller to run;
     Task 5 is the first real caller

Sign-out (deliberate settings action, F13):
  user signs out -> FirebaseAuth emits null -> uidChanges() emits null
  -> StreamBuilder key changes back to null -> signed-in subtree disposed
  -> fresh in-memory subtree built -> guest sees SeedData again, not a stale
     cached Firestore snapshot from the just-ended session

Bootstrap transaction, in isolation (mechanism only, no real seed writer yet):
  caller invokes runBootstrapIfNeeded(uid, writer)
  -> transaction reads users/{uid}.seeded
  -> absent or false: writer() runs inside the same transaction, seeded set true
  -> true: writer() never runs
  -> two callers racing the same uid: the commit happens at most once;
     seedWriter may be invoked more than once on contention (real Firestore
     retries the whole transaction handler, not just the commit, when it
     loses a race) and must perform all its writes through the transaction
     with no side effects outside it (no network calls, no writes via a
     different client)
  -> the device is offline: the transaction fails outright (no local-cache
     write fallback); the caller (Task 5+) must handle that failure path
```

## 6. Interface surface

```text
Stream<String?> uidChanges()                                              auth_session.dart, read by app.dart only
CollectionReference<Map<String,dynamic>> FirestoreService.usersCollection()
DocumentReference<Map<String,dynamic>> FirestoreService.userDoc(String uid)
CollectionReference<T> FirestoreService.subcollection<T>(String uid, String name,
    T Function(Map<String,dynamic>, String id) fromFirestore,
    Map<String,dynamic> Function(T) toFirestore)
Future<void> FirestoreService.runBootstrapIfNeeded(String uid,
    Future<void> Function(Transaction tx, DocumentReference<Map<String,dynamic>> userDoc) seedWriter)
```

All four are shared infra (`lib/shared/backend/`), called from feature `repository/` files and
from `lib/app.dart`. No feature `view/`/`widgets/` file imports any of them (architecture
boundary rule, `02-architecture.md` §4).

## 7. Domain model usage

No `03-domain-model.md` entity gains or loses a field from this task. `seeded` (schema doc §1)
is explicitly **not** added to `ProfileState` — it's read/written only through
`FirestoreService.runBootstrapIfNeeded` and the raw `users/{uid}` document, never surfaced to
a Cubit. `ProfileRepository.watchProfile()` (built in Task 5) is responsible for excluding it
from the `ProfileState` it emits; this task only guarantees the field exists at the
`FirestoreService` layer.

## 8. Data changes

Adds one infra-only field to the already-specified `users/{uid}` document: `seeded: bool`
(schema doc §1). No collection is created or written with real data by this task — the
mechanism exists, but Task 5 is the first task that calls it with an actual `SeedData`-derived
writer. No `firestore.rules` change (Task 9 owns that file).

## 9. Background work and events

`runBootstrapIfNeeded` is the only "background work" this task introduces: a single Firestore
transaction whose **commit** happens at most once per uid, guarded by the `seeded` flag read
inside that same transaction. The Firestore SDK's own transaction-retry logic may re-run the
whole transaction handler — including `seedWriter` — more than once if it loses a commit race
(no custom retry loop is written here); only the commit is exactly-once, not the `seedWriter`
invocation. No Cloud Function, no scheduled job, no event emission. Idempotency is structural
(the `seeded` flag inside the transaction), not best-effort. A transaction fails outright while
the device is offline, so a caller (Task 5+) must handle that failure path rather than assume
`runBootstrapIfNeeded` always resolves.

## 10. Degradation and failure

- `uidChanges()` never throws into its listener: if `FirebaseAuth.instance` isn't initialized
  (e.g. a widget test that never calls `Firebase.initializeApp`), nothing touches
  `auth_session.dart` unless that test explicitly builds `StyloBuddyApp` — existing Cubit
  tests, which construct Cubits directly, never import it and are unaffected (F14-A14).
- If `authStateChanges()` itself errors (plugin failure), `uidChanges()` treats that as a
  signed-out transition (`null`) rather than propagating an exception into `StreamBuilder`,
  so the app falls back to guest mode instead of showing a crashed widget tree.
- A sign-in/out transition always fully disposes the previous subtree before building the
  next one — never a partial rebuild that could leave one stale Cubit instance mixed with new
  ones (architecture D3's whole point).
- `runBootstrapIfNeeded`: if `seedWriter` throws inside the transaction, the transaction
  aborts and `seeded` is **not** set — a later retry (e.g. next app launch) gets a clean
  attempt, never a half-seeded user permanently marked as seeded.
- Guest mode makes zero Firestore calls, ever — not "falls back silently after a failed call"
  but structurally: the in-memory repository branch never constructs a `FirestoreService`
  call site in the first place.

## 11. Validation assertions

```
F14-A01  [U]  uidChanges() emits null as its first event when FirebaseAuth.instance.currentUser is null at subscribe time
F14-A02  [U]  uidChanges() emits the signed-in uid after a fake authStateChanges() stream emits a User
F14-A03  [U]  uidChanges() emits null again after that same fake stream emits null following a signed-in event (full signed-out -> signed-in -> signed-out cycle covered in one test)
F14-A04  [U]  uidChanges() does not re-emit when the underlying stream emits the same User twice in a row (distinct()); a StreamBuilder keyed on it does not rebuild its subtree for a duplicate emission
F14-A05  [I]  In lib/app.dart, a uid transition (null -> 'uid-1') disposes the previous MultiBlocProvider subtree and constructs a new one; every root Cubit instance after the transition is a different object identity than before it
F14-A06  [I]  A full round trip (null -> 'uid-1' -> null) leaves every root Cubit's state equal to the original guest-mode initial state — no residual data survives through two reconstructions
F14-A07  [I]  Guest-mode non-regression: with uidChanges() emitting only null for the whole run, the full existing flutter test suite (pre-this-task) passes unchanged — no existing assertion needed modification to accommodate this task
F14-A08  [I]  WardrobeCubit.state.items is the SeedData-derived in-memory list both immediately after a simulated sign-out and on a cold guest launch — a just-ended signed-in session leaves no stale Firestore-sourced items behind
F14-A09  [I]  After a simulated sign-in following guest-mode edits (e.g. a guest-added wardrobe item), the newly-constructed signed-in subtree's WardrobeCubit does not contain that guest-only edit — guest and signed-in state never bleed into each other
F14-A10  [U]  FirestoreService.userDoc(uid).path equals 'users/<uid>' for a representative uid
F14-A11  [U]  FirestoreService.subcollection(uid, name, ...).path is always prefixed 'users/<uid>/<name>' — never a top-level/unscoped collection path, for every collection name in the schema doc's §2-6 list
F14-A12  [U]  The toFirestore converter passed through subcollection() writes the document's own id as a plain field on the map in addition to it being the doc ID, matching the schema doc's "duplicate id on document" convention
F14-A13  [U]  The fromFirestore converter ignores a document whose stored id field disagrees with its actual Firestore doc ID and trusts the doc ID (the doc ID is the source of truth, the stored field is for query/export convenience only, per schema doc §2)
F14-A14  [U]  Existing Cubit-level tests that construct a Cubit directly (bypassing app.dart) never trigger any FirebaseAuth or Firestore call — auth_session.dart and firestore_service.dart are not imported transitively by any lib/features/*/cubit file
F14-A15  [U]  runBootstrapIfNeeded on a user doc with no seeded field present invokes seedWriter exactly once and leaves seeded: true afterward
F14-A16  [U]  runBootstrapIfNeeded on a user doc with seeded: false explicitly stored behaves identically to a missing seeded field — seedWriter still runs exactly once (missing and explicit-false are not distinguished)
F14-A17  [U]  runBootstrapIfNeeded on a user doc with seeded: true never invokes seedWriter
F14-A18  [U]  Two concurrent runBootstrapIfNeeded calls for the same brand-new uid (simulated via a fake Firestore double that races both transaction attempts) invoke seedWriter exactly once between them, never twice
F14-A19  [U]  If seedWriter throws, the transaction does not commit seeded: true — a subsequent runBootstrapIfNeeded call for that uid still invokes seedWriter (the failed attempt is retryable, not permanently marked done)
F14-A20  [L]  Against the live Firebase project (stylobuddy-b7e46), a real Google sign-in followed by sign-out in the running app drives uidChanges() through signed-out -> signed-in -> signed-out with lib/app.dart visibly rebuilding (no crash, no stuck loading state, guest SeedData reappears after sign-out) — deferred to the live-verification pass per the harness [L] convention, same as Milestone 1's live-run items
F14-A21  [L]  Against the live Firestore project, calling runBootstrapIfNeeded for a newly created real test user, then killing and relaunching the app before calling it again, results in seeded: true written exactly once with no duplicate seed documents — deferred to the live-verification pass
```

## 12. Edge cases

- Firebase Auth emitting a `User` with an empty-string `uid` (not expected from the real SDK,
  but defended against): treated the same as `null` by `uidChanges()` rather than keying a
  subtree on an empty path segment.
- Rapid sign-in/sign-out bouncing (e.g. a flaky network retry during auth): each distinct uid
  value still triggers exactly one full teardown/rebuild; `distinct()` only collapses
  *consecutive identical* values, not a legitimate `a -> null -> a` bounce.
- A test that builds `StyloBuddyApp` without ever calling `Firebase.initializeApp` first: this
  is the actual, common case across the suite (14+ call sites across `test/app_smoke_test.dart`,
  `test/core/router_test.dart`, `test/features/home/home_screen_test.dart`,
  `test/features/stylist/stylist_screens_test.dart`, and `test/features/support/f02_harness.dart`
  pass only a `router:` override, no `uidStream:`). These do **not** inject a fake
  `uidChanges()` stream; they rely on the synchronous guest-mode guard inside `uidChanges()`
  itself — `FirebaseAuth.instance` throws synchronously because `Firebase.initializeApp` was
  never called, `uidChanges()` catches that and returns a signed-out-only stream (F14-A14) — so
  `StyloBuddyApp()` still renders guest/SeedData state with zero setup. A handful of other tests
  (`test/app_backend_wiring_test.dart`'s F14-A04/A05/A06/A08/A09) *do* inject an explicit fake
  `uidStream:` where the test needs to drive a sign-in/sign-out transition. Real Firebase
  initialization against the live project is exercised only at the `[L]` gate.
- `runBootstrapIfNeeded` called for a uid whose user doc doesn't exist at all yet (not even an
  empty doc): treated identically to a doc that exists with `seeded` missing — the transaction
  creates the doc as part of committing.

## 13. Open questions

- **Per-Cubit dual-mode timing — RESOLVED before implementation.** Confirmed per the Task 1
  dispatch: `lib/app.dart`'s `StreamBuilder`/key mechanism is wired for every root Cubit now
  (reconstruction-on-auth-change is universal from day one), but no root Cubit — including
  `WardrobeCubit` — actually gets a dual-mode (in-memory vs Firestore) repository in this task.
  `WardrobeRepository` today only has `loadItems()` from `SeedData`; there is no
  `FirestoreWardrobeRepository` yet either (that is Task 2's job). Every root Cubit keeps its
  single existing in-memory construction in both the guest and signed-in subtree; F14-A05/A06
  are verified against "every root Cubit" as originally scoped, since the reconstruction
  mechanism itself (not any real repository swap) is what's under test.
- **`runBootstrapIfNeeded`'s seed-writer contract.** This task defines the transaction
  mechanism's shape (a callback given the transaction and the user doc reference) but not
  what a real writer looks like — Task 5 is where a concrete writer (seeding `ProfileState`
  defaults plus `wishlist: []`) is designed. If Task 5 finds the callback signature too narrow
  (e.g. needs to write to subcollections too, not just the user doc), amend F14's interface
  surface rather than inventing a second bootstrap mechanism.

---

## Completion block

```
Status: IMPLEMENTED (gates 1-3 closed; gate 4 deferred to live-verification pass)

[x] Gate 1  Interface documented (§6, matches implementation exactly)
[x] Gate 2  Unit      (A01-A04, A10-A19 + edge cases — test/shared/backend/)
[x] Gate 3  Integration (A05-A09 widget tests — test/app_backend_wiring_test.dart, plus a
                          literal `F14_A07` widget test and an A05 navigation-teardown
                          regression test added in the post-review fix round;
                          A07 guest-mode non-regression — full flutter test suite, 418/418 pass)
[ ] Gate 4  Live run   (A20, A21 — [L], deferred, not faked)

Assertions: 19/19 [U]/[I] PASS (A20, A21 are [L], pending live-verification pass)
Regression: flutter test (full suite) 418/418 pass; flutter analyze: No issues found!
```
