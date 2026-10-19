# F16 — Saved / Outfits Backend

> Gives a signed-in user real Firestore persistence for their saved outfits
> and wear history, swapping `OutfitsCubit`'s direct in-memory state
> mutation for the dual-mode repository pattern (`InMemoryOutfitsRepository` /
> `FirestoreOutfitsRepository` behind one interface) — Task 3 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`. Zero widget
> redesign, zero change to guest ("Skip for now") saved/outfits behavior.
> Depends on F14 (`uidChanges()`, `FirestoreService`, the auth-gated
> `StreamBuilder` in `lib/app.dart`) and reuses, but does not modify, the
> cross-feature call `OutfitsCubit` already makes into
> `WardrobeRepository.adjustWears` (F15) on log-wear/undo-wear — that call
> stays exactly as-is; this task is only about `Outfit`/`WearEvent`'s own
> persistence. Grounded in
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D2, D4, D6)
> and `docs/superpowers/specs/2026-10-19-firestore-schema.md` §3-4.

**Status:** NOT STARTED · **Milestone:** 2 · **Depends on:** F14

---

## 1. Goal

Let a signed-in user's saved outfits and wear history — outfits created via
the Builder or the Stylist's "save this look," wears logged or undone,
outfits deleted — survive a cold restart and a different device, by writing
them to `users/{uid}/outfits/{outfitId}` and `users/{uid}/wearEvents/{eventId}`
instead of holding them only in `OutfitsCubit`'s in-memory state. A guest
gets none of this and sees exactly what the current `flutter test` suite
already verifies — no network call, no new failure mode, the same
`SeedData.outfits` seed every launch.

## 2. MVP scope

- New folder `lib/features/saved/repository/`:
  - `outfits_repository.dart`: an **abstract** `OutfitsRepository` interface.
    Its methods mirror the write/read operations `OutfitsCubit` already
    performs directly on its own state today — `byId`, `saveOrFind`,
    `upsertManual`, `delete`, `logWear`, `removeWear`, `wearEvents` — plus a
    `watchOutfits()` stream read and a `watchWearEvents()` stream read per
    architecture D6. `byId` and `wearEvents` are pure in-memory lookups over
    whatever the Cubit currently holds in state today (not repository
    round-trips) — see §6 for exactly which methods move behind the
    interface as writes versus which stay Cubit-local reads over
    already-streamed state, and §13 for the one open question this split
    raises.
  - `in_memory_outfits_repository.dart`: today's `SeedData.outfits`/empty
    `wearLog` behavior moved behind the interface verbatim — same seed list,
    same synchronous-feeling writes (a `Future` that completes
    already-resolved), no network call ever constructed on this branch.
    Used for guests, unchanged from today's `OutfitsCubit`-held logic.
  - `firestore_outfits_repository.dart`: real reads/writes under
    `users/{uid}/outfits/{outfitId}` and `users/{uid}/wearEvents/{eventId}`
    (schema doc §3-4) — `outfitId`/`eventId` are `Outfit.id.toString()` /
    `WearEvent.id.toString()` per architecture D4 (the model fields stay
    `int`; only the Firestore document ID is the stringified form).
    `watchOutfits()` wraps `outfits.snapshots()`; `watchWearEvents()` wraps
    `wearEvents.snapshots()` ordered `timestamp descending` (schema doc §4's
    documented query pattern, matching `OutfitsCubit.wearEvents()`'s
    existing sort exactly, including its tie-break on `id` descending for
    equal timestamps). Writes are `Future<void>`.
  - **Binding requirement, not a suggestion** (per the Task 2/F15 review
    lesson named in the plan's Review Focus and the architecture doc's D6
    note): `logWear` and `removeWear` are read-modify-write operations
    against `Outfit.worn` — both are implemented with Firestore's
    `runTransaction`, never a bare `get()` followed by a separate `set()`/
    `update()`. No other method in this repository is read-modify-write
    (`saveOrFind`'s "reuse an identical outfit" check reads from the
    locally-held `watchOutfits()` stream state inside the Cubit, not a
    fresh server read inside the write — see §13 for why that is an
    accepted, documented gap rather than a silent one).
- `lib/app.dart`: `OutfitsCubit`'s construction becomes dual-mode under
  Task 1's `StreamBuilder` — in-memory for `uid == null`, Firestore for
  `uid != null` — following the same pattern F15 established for
  `WardrobeCubit`.
- `OutfitsCubit`'s own public method names/signatures are unchanged in shape
  (`byId`, `saveOrFind`, `upsertManual`, `delete`, `logWear`, `removeWear`,
  `wearEvents`); only what is behind them changes from direct state
  mutation to "await the repository Future, then optimistically update
  local state" (architecture D6), matching F15's established Cubit-side
  pattern for `WardrobeCubit`.
- Every write call this task adds that is not directly awaited at its call
  site inside the Cubit (there should be none that are truly
  fire-and-forget, but any that end up unawaited for UI-responsiveness
  reasons) gets a `.catchError` attached from day one — **not** a
  second-round fix, per the F15 review history named in this task's brief.

## 3. Later scope

- `BuilderCubit`'s own save flow (it calls `OutfitsCubit.saveOrFind`/
  `upsertManual` already, unchanged) — no `BuilderCubit` file changes this
  task.
- `StylistState`'s generation session persistence — explicitly excluded by
  schema doc §7 ("only a save via `OutfitsRepository` persists"); this task
  does not add any new persistence for the generation session itself.
- Firestore security rules for `outfits`/`wearEvents` (Task 9).
- Any change to `WardrobeRepository.adjustWears` or its call sites — the
  cross-feature `OutfitsCubit -> WardrobeRepository.adjustWears` call (F15)
  is reused exactly as it exists today; this task does not touch
  `lib/features/wardrobe/`.
- Deleting an `Outfit`'s associated `WearEvent`s when the outfit itself is
  deleted — unchanged from today's behavior (`03-domain-model.md`: "Deleting
  an `Outfit` keeps its `WearEvent`s, history is retained").

## 4. Roles and permissions

Reuses `docs/foundation/07-security.md`'s guest/authenticated roles, made
concrete the same way F15 made it structural for wardrobe: `uid == null` ->
`InMemoryOutfitsRepository`, zero Firestore calls, ever; `uid != null` ->
`FirestoreOutfitsRepository`, scoped to that `uid`'s own subtree via
`FirestoreService.subcollection` (F14-A11 — paths are always
`users/<uid>/outfits` and `users/<uid>/wearEvents`, never a cross-user or
top-level path). No new permission surface beyond that isolation guarantee
is introduced this task.

## 5. Main flows

```text
Guest saves/logs/undoes a wear (no Firebase user):
  Stylist "save this look" / Builder "save" -> OutfitsCubit.saveOrFind or
     .upsertManual -> InMemoryOutfitsRepository resolves immediately ->
     OutfitsCubit optimistically updates state
  /saved tab -> "log wear" -> OutfitsCubit.logWear -> InMemoryOutfitsRepository
     resolves immediately -> OutfitsCubit updates outfits.worn and wearLog,
     then calls WardrobeCubit.adjustWears(items, 1) exactly as today (F15,
     unchanged)
  (identical to today's existing flow; no network call constructed)

Signed-in user saves a new outfit:
  Stylist/Builder "save" -> OutfitsCubit.saveOrFind/.upsertManual -> checks
     state.outfits (already streamed from Firestore via watchOutfits()) for
     an identical-items match -> no match -> FirestoreOutfitsRepository
     writes a new users/{uid}/outfits/{id} document, id = Outfit.id.toString()
     -> Future resolves -> OutfitsCubit optimistically updates local state ->
     the live watchOutfits() snapshot later reconciles the same document

Signed-in user logs a wear:
  /saved tab -> "log wear" -> OutfitsCubit.logWear(outfitId) ->
     FirestoreOutfitsRepository.logWear runs a runTransaction: reads the
     current outfits/{outfitId} document server-side, increments worn by
     exactly 1 off that read value (never off cached local state), writes a
     new wearEvents/{id} document with items snapshotted from the
     transaction's own read of the outfit -> transaction commits atomically
     or the whole op fails and is retried by the Firestore SDK per its own
     transaction-retry semantics (not application-level retry logic added
     by this task) -> Future resolves -> OutfitsCubit optimistically updates
     local state -> WardrobeCubit.adjustWears(items, 1) called exactly as
     today (F15, unchanged, outside this transaction)

Signed-in user undoes a wear:
  /saved -> wear history -> "undo" -> OutfitsCubit.removeWear(eventId) ->
     FirestoreOutfitsRepository.removeWear runs a runTransaction: reads the
     target wearEvents/{eventId} document and its parent outfits/{outfitId}
     document server-side, computes max(0, worn - 1) off that read value,
     deletes the wearEvents document and writes the clamped worn value in
     the same transaction -> Future resolves -> OutfitsCubit updates local
     state -> WardrobeCubit.adjustWears(event.items, -1) called exactly as
     today (F15, unchanged, outside this transaction)

Signed-in user's logWear/removeWear transaction races with a concurrent
write to the same outfit (e.g. two devices logging a wear near-simultaneously):
  -> Firestore's runTransaction detects the conflicting read and
     automatically retries the transaction function against a fresh read,
     per the Firestore SDK's own documented transaction semantics -> both
     wears are eventually recorded, worn ends up incremented twice, never
     silently lost and never double-counted from a stale read (this is
     exactly the failure mode a bare get-then-set would not protect against
     — see §13 for why this is called out explicitly rather than assumed)

Sign-out then sign-in-again as a different (or the same) user:
  F14's auth-gated reconstruction (D3) tears down OutfitsCubit entirely on
     the uid-keyed StreamBuilder rebuild -> no FirestoreOutfitsRepository
     stream subscription survives the transition -> the newly-constructed
     OutfitsCubit for the new uid (or guest) starts from that uid's own
     watchOutfits()/watchWearEvents() first emission (or the in-memory seed,
     for a sign-out) -> no outfit/wear data from the previous session is
     ever visible in the new one, re-verifying Review Focus item 2 at this
     feature's own layer
```

## 6. Interface surface

```text
abstract class OutfitsRepository
  Stream<List<Outfit>> watchOutfits()                               both impls
  Stream<List<WearEvent>> watchWearEvents()                         both impls
  Future<Outfit> saveOrFind(Outfit draft, {required List<Outfit> current})   both impls
  Future<Outfit> upsertManual({
      int? editingId, required String name,
      required List<String> items, required String occasion,
      required List<Outfit> current})                              both impls
  Future<void> delete(int id)                                       both impls
  Future<void> logWear(int outfitId, {required Outfit outfit})      both impls
  Future<void> removeWear(int eventId, {required WearEvent event})  both impls

class InMemoryOutfitsRepository implements OutfitsRepository            guest mode
class FirestoreOutfitsRepository implements OutfitsRepository           signed-in mode
```

`OutfitsCubit`'s public surface (`byId`, `saveOrFind`, `upsertManual`,
`delete`, `logWear`, `removeWear`, `wearEvents`) is unchanged in shape.
`byId` and `wearEvents` remain pure synchronous lookups over
`OutfitsCubit.state` — populated by subscribing to `watchOutfits()` /
`watchWearEvents()` — not repository round-trips themselves; they are not
part of the `OutfitsRepository` interface. `saveOrFind` and `upsertManual`
on the interface accept the Cubit's currently-held `outfits` list
(`current`) rather than re-reading it, because the "reuse an identical
outfit" / "edit in place" checks are matches against already-streamed
state, not a fresh server read — this mirrors how `WardrobeCubit` already
holds its own state and is the one place this task's repository boundary
differs from a pure CRUD surface (flagged explicitly in §13 rather than
silently reconciled). `logWear`/`removeWear` similarly accept the
already-resolved `outfit`/`event` the Cubit found via `byId` purely so the
Firestore implementation's transaction knows which document IDs to touch
without a redundant lookup — the transaction itself still re-reads
server-side state for the actual increment/decrement, per §5's binding
requirement; `current`/`outfit`/`event` are never used by
`FirestoreOutfitsRepository` as the source of truth for the numeric
read-modify-write, only as routing information.

## 7. Domain model usage

`Outfit` (`id`, `name`, `occasion`, `items`, `why`, `worn`) and `WearEvent`
(`id`, `outfitId`, `name`, `occasion`, `items`, `timestamp`) are read/written
unchanged — no new fields, no type change on `id` (stays `int` on both
models per architecture D4; only the Firestore document ID is the
stringified form). No change to `docs/foundation/03-domain-model.md` is
needed this task.

## 8. Data changes

- Firestore: `users/{uid}/outfits/{outfitId}` and
  `users/{uid}/wearEvents/{eventId}` collections, fields per schema doc §3-4
  (`outfits`: `id`, `name`, `occasion`, `why`, `items`, `worn`; `wearEvents`:
  `id`, `outfitId`, `name`, `occasion`, `items`, `timestamp` as a Firestore
  `Timestamp`, mapped to/from `DateTime` via `cloud_firestore`'s built-in
  conversion). No `firestore.rules` change this task (Task 9 owns that
  file; today's `users/{uid}/{document=**}` owner-only default-deny already
  covers both paths at the auth-isolation level).
- No migration: neither collection exists yet for any real user (this is
  the task that first creates them); no backfill needed.

## 9. Background work and events

- `logWear`/`removeWear` are one-shot transactions, not retried/queued
  background jobs beyond Firestore's own SDK-internal transaction-retry
  behavior (§5) — no application-level retry loop is added by this task.
- No Cloud Function, no scheduled job triggered by this task.
- `watchOutfits()`/`watchWearEvents()`'s Firestore `snapshots()` listeners
  are long-lived for the life of the signed-in `OutfitsCubit` instance;
  both are torn down (per F14 D3) on every sign-out/sign-in transition
  along with the rest of the subtree, never left subscribed past the
  Cubit's `close()`.

## 10. Degradation and failure

- Guest mode (`InMemoryOutfitsRepository`) makes zero Firestore calls —
  structurally, not "falls back after a failed call," the same guarantee
  F14/F15 established for other repositories.
- `logWear`/`removeWear` never drive `Outfit.worn` below 0 — the Firestore
  transaction clamps at 0 exactly as `OutfitsCubit.removeWear`'s existing
  `o.worn > 0 ? o.worn - 1 : 0` does today, now enforced against the
  server-read value inside the transaction rather than against
  possibly-stale local state.
- `FirestoreOutfitsRepository.watchOutfits()`/`watchWearEvents()` losing
  network connection mid-session: Firestore's SDK-level offline
  cache/reconnect behavior applies (not added or suppressed by this task),
  matching F15-§10's same stance for wardrobe.
- `logWear`/`removeWear` called with an `outfitId`/`eventId` that does not
  exist in Firestore (e.g. deleted on another device between the Cubit's
  local `byId` lookup and the write landing): the transaction's read finds
  no document — the write is a no-op (no document created, no crash), and
  the Future resolves without mutating `worn`/`wearLog` for a document that
  is not there; this mirrors `OutfitsCubit.logWear`/`removeWear`'s existing
  "silently return if `byId`/the matching event lookup finds nothing" guard,
  now also checked server-side rather than only client-side.
- `saveOrFind` finding no identical-items match, versus finding one: both
  are two distinct, already-covered outcomes (new outfit written vs.
  existing outfit returned) — not a missing/empty distinction needing new
  handling.
- `wearEvents(outfitId: ...)` with no matching events for that outfit
  (missing filter match) returns an empty list, distinct from the
  unfiltered call never being empty for a user with any wear history at
  all — both are valid list shapes, never confused with a "repository
  error."

## 11. Validation assertions

```
F16-A01  [U]  FirestoreOutfitsRepository.saveOrFind, given no existing outfit with identical items, writes a new outfits/{id} document (id == the new Outfit.id.toString()) and watchOutfits()'s next emission includes it with every field round-tripped unchanged (name, occasion, why, items, worn)
F16-A02  [U]  FirestoreOutfitsRepository.saveOrFind, given an existing outfit with identical items (order-sensitive, matching OutfitsCubit's current listEquals check), writes no new document and returns the existing outfit unchanged
F16-A03  [U]  FirestoreOutfitsRepository's document ID for a saved/upserted outfit equals Outfit.id.toString() verbatim — the model field stays an int, never re-derived or re-typed
F16-A04  [U]  The stored outfits document also carries id as a plain int field equal to int.parse(doc ID) (schema doc §3's "duplicate id on document" convention)
F16-A05  [U]  FirestoreOutfitsRepository.upsertManual with editingId set to an existing outfit's id replaces exactly that document's name/items/occasion fields; a second watchOutfits() emission reflects the update, every other document is unaffected, and worn is left untouched
F16-A06  [U]  FirestoreOutfitsRepository.upsertManual with editingId omitted (or not matching any existing outfit) creates a new document with worn: 0, distinct id from any existing outfit
F16-A07  [U]  FirestoreOutfitsRepository.delete removes exactly that outfits document; watchOutfits() no longer includes it; any wearEvents documents referencing that outfitId are left untouched (history retained, per 03-domain-model.md)
F16-A08  [U]  FirestoreOutfitsRepository.logWear increments the target outfit's worn by exactly 1 and writes a new wearEvents document whose items field is a snapshot of the outfit's items at the time of the transaction's own server-side read, not the caller-supplied outfit argument, verified by mutating the stored outfit's items between the Cubit's byId lookup and the transaction committing
F16-A09  [U]  FirestoreOutfitsRepository.logWear and .removeWear are each implemented via runTransaction — a test double that tracks whether any read-modify-write path in this repository ever calls a bare get() followed by a separate set()/update() without an enclosing transaction fails the test; this is checked for both methods independently
F16-A10  [U]  FirestoreOutfitsRepository.removeWear never drives the parent outfit's worn below 0 even when called against an outfit whose stored worn is already 0 (clamped at 0 inside the transaction, mirroring OutfitsCubit's existing o.worn > 0 ? o.worn - 1 : 0 invariant, now re-verified at the Firestore-transaction layer)
F16-A11  [U]  FirestoreOutfitsRepository.removeWear deletes exactly the target wearEvents document and leaves every other wearEvents document (including ones for the same outfitId) untouched
F16-A12  [U]  FirestoreOutfitsRepository.watchWearEvents() emits events ordered by timestamp descending, tie-broken by id descending for equal timestamps — matching OutfitsCubit.wearEvents()'s existing sort exactly, verified with at least two events sharing one timestamp value
F16-A13  [U]  FirestoreOutfitsRepository.logWear called against an outfitId that does not exist in Firestore (deleted concurrently) performs no write to any outfits or wearEvents document and its Future resolves without throwing — a silent no-op, not a crash
F16-A14  [U]  FirestoreOutfitsRepository.removeWear called against an eventId that does not exist in Firestore performs no write to any outfits or wearEvents document and its Future resolves without throwing
F16-A15  [U]  InMemoryOutfitsRepository's watchOutfits()/watchWearEvents()/saveOrFind/upsertManual/delete/logWear/removeWear behavior is unchanged from today's OutfitsCubit-held logic — the full pre-existing OutfitsCubit test suite passes unmodified against OutfitsCubit constructed with InMemoryOutfitsRepository, with zero existing assertion edited to accommodate this task
F16-A16  [U]  InMemoryOutfitsRepository never imports or constructs a Firestore client — guest mode makes zero network calls, structurally (same guarantee style as F14-A14/F15-A08)
F16-A17  [I]  lib/app.dart: with uid == null, OutfitsCubit is constructed with InMemoryOutfitsRepository; with uid == 'uid-1', it is constructed with FirestoreOutfitsRepository — object type differs across the F14 sign-in/out transition, not just its data
F16-A18  [I]  OutfitsCubit.logWear, when the repository call is in flight, still calls WardrobeCubit.adjustWears(outfit.items, 1) after the repository Future resolves (not before, not skipped) — the F15 cross-feature call contract is unchanged by this task's async-ification
F16-A19  [I]  OutfitsCubit.removeWear, when the repository call is in flight, still calls WardrobeCubit.adjustWears(event.items, -1) after the repository Future resolves — same contract as A18 for the undo path
F16-A20  [I]  A full sign-in -> save an outfit -> log a wear -> sign-out -> sign-in-again cycle (F14's reconstruction pattern) leaves the newly-constructed OutfitsCubit's state showing only that uid's own Firestore data on re-sign-in, and the in-memory seed data (not the signed-in user's outfits) on sign-out — no bleed-through in either direction (Review Focus item 2, re-verified at this feature's layer)
F16-A21  [I]  Two concurrent logWear calls against the same outfitId (simulating two devices) against a fake Firestore double that supports transaction retry both succeed and worn ends at the seed value + 2, not +1 (no lost update from a stale read) — re-verifying the binding runTransaction requirement under contention, not just in isolation
F16-A22  [U]  Any write call inside OutfitsCubit/FirestoreOutfitsRepository that is not directly awaited at its call site (fire-and-forget) has a .catchError (or equivalent) attached — a test asserts no unhandled rejection/uncaught Future error surfaces for a write that is allowed to fail in the background; if no such unawaited call exists in the final implementation, this assertion is satisfied vacuously and the implementer notes that in the completion block rather than skipping the test
F16-A23  [L]  Against the live Firestore project (stylobuddy-b7e46), a real signed-in test user's save-outfit -> log-wear -> undo-wear -> delete-outfit sequence round-trips correctly and is visible after killing and relaunching the app — deferred to the live-verification pass, documented in the task report rather than a CI-run test
```

## 12. Edge cases

- `saveOrFind` called twice in immediate succession with the same draft
  items before the first write's Future resolves: the second call's
  identical-items check runs against `current` (the Cubit's last-known
  state, per §6) which may not yet include the first write's optimistic
  update if the caller races the two calls — this task does not add
  de-duplication beyond what `OutfitsCubit`'s existing single-threaded
  call pattern already provides (every UI entry point awaits one call
  before allowing another); flagged as inherited risk, not newly
  introduced, since the in-memory implementation has the identical
  characteristic today.
- `upsertManual` with `editingId` pointing at an outfit that existed in
  `current` but has since been deleted server-side (another device): the
  Firestore write targets a document ID that no longer exists — Firestore
  treats a `set()`/`update()` against a missing document per its own
  normal semantics (an `update()` would fail; see §13 for which call this
  task uses and why).
- A `WearEvent.timestamp` collision (two wears logged in the same
  millisecond, matching `OutfitsCubit._newId()`'s existing collision-proofing
  for `id` but not for `timestamp` itself): ordering falls through to the
  `id`-descending tie-break exactly as `OutfitsCubit.wearEvents()` already
  does (F16-A12) — not a new case, just re-verified against Firestore's
  stored `Timestamp` field.
- `removeWear` on the last remaining `WearEvent` for an outfit: `worn`
  clamps to 0, the `wearEvents` collection for that outfit becomes empty,
  `watchWearEvents(outfitId: ...)`-equivalent filtering (done Cubit-side
  over the full stream, per schema doc's lack of a composite index) returns
  an empty list — not an error.

## 13. Open questions

- **`saveOrFind`/`upsertManual`'s "check against current state" shape is not
  a pure repository method.** Per §6, these two methods take the Cubit's
  already-held `outfits` list as a parameter rather than re-reading
  Firestore themselves, because the "is there already an identical-items
  outfit" / "which outfit am I editing" checks are checks against
  already-streamed state, mirroring how `WardrobeCubit`/`ImportCubit`
  already behave. This is a deliberate deviation from a pure CRUD
  interface and is flagged rather than silently decided — an alternative
  design would have `FirestoreOutfitsRepository.saveOrFind` do its own
  Firestore query (e.g. `where('items', isEqualTo: ...)`) instead of
  trusting client-held state, which would be more correct under
  multi-device concurrency (closing the gap named in the first Edge Case
  above) at the cost of an extra round trip and a query shape Firestore's
  array-equality semantics may not support cleanly for ordered lists.
  Recommend keeping the client-state-based approach for this task (matches
  F15's existing pattern, avoids new query complexity) but this is a real,
  not-fully-closed correctness gap under true multi-device concurrency; a
  later task should revisit if duplicate-outfit reports surface in
  practice.
- **`upsertManual` targeting a concurrently-deleted document: `set()` vs.
  `update()`.** This document does not decide whether
  `FirestoreOutfitsRepository.upsertManual`'s edit-in-place path uses a
  `set()` (which would recreate the document, silently undoing the other
  device's delete) or an `update()` (which fails against a missing
  document, surfacing as a Future error the Cubit must handle). The
  implementer must choose one, and must handle whichever failure mode
  `update()` introduces (if chosen) without crashing the save flow —
  resolve before writing the transaction code and amend this section with
  the decision and a dated note, following F15 §13a's precedent for how
  this kind of mid-implementation decision gets recorded.

  **Resolved 2026-10-20 (Task 3 implementer, per the controller's binding
  ruling):** the edit-in-place path calls `update()` with only
  `name`/`occasion`/`items` in the payload (deliberately excluding `worn`
  so a partial update can never clobber it, F16-A05); on a `FirebaseException`
  with code `'not-found'` it falls back to a full `set(candidate)` instead of
  rethrowing — recreating the document rather than crashing the save flow,
  matching the controller ruling verbatim. See
  `lib/features/saved/repository/firestore_outfits_repository.dart`'s
  `upsertManual`.

  **Resolved 2026-10-20 (Task 3 implementer, interface deviation from this
  section's literal §6 pseudocode, recorded for the same reason as the
  decision above):** `OutfitsRepository.upsertManual` takes the Cubit's
  already-fully-built `candidate` `Outfit` (final `id` already decided by
  `OutfitsCubit._newId()`) rather than raw `name`/`items`/`occasion` fields.
  Raw fields would let this repository's own "create" branch independently
  mint a *different* id than the one `OutfitsCubit` already optimistically
  emitted into local state for the exact same reason `saveOrFind`'s `draft`
  parameter is already a full `Outfit` object — a user could already be
  mid-navigation on `/saved/{id}` using the Cubit's id by the time
  `watchOutfits()`'s next snapshot reconciles a *different* persisted id,
  which this interface shape structurally prevents. `OutfitsRepository.logWear`
  similarly gained a `required WearEvent event` parameter (not in this
  section's literal pseudocode) for the same id-consistency reason. See
  `lib/features/saved/repository/outfits_repository.dart`'s class doc
  comment for the full reasoning.
- **Whether `logWear`/`removeWear`'s transaction should also write the
  `WardrobeCubit.adjustWears` side effect atomically.** Today (and per F15,
  unchanged by this task) `OutfitsCubit` calls `WardrobeRepository.adjustWears`
  as a separate call after the outfit/wearEvent transaction commits — the
  two writes (outfit's `worn`/wearEvents collection, and each affected
  wardrobe item's `wears`) are not atomic with each other, only internally
  consistent within each repository's own transaction. This is inherited
  from the existing cross-feature call shape (`OutfitsCubit` holds a
  reference to `WardrobeCubit`, not `WardrobeRepository` directly) and is
  explicitly out of scope to change per §3 — flagged here so a reviewer
  does not mistake it for an oversight: a crash between the two calls
  leaves `worn`/`wearEvents` updated but a wardrobe item's `wears` count
  stale until some future reconciliation, a pre-existing gap this task
  does not introduce or close.
- **No composite index decision needed**, confirmed by schema doc §4: single-
  field descending on `timestamp` is automatic; this document assumes no
  Firestore console/CLI index-creation step is required for `watchWearEvents()`,
  consistent with the schema doc's own note — flagged only because if that
  assumption is wrong in practice (a composite index turns out to be
  required once a `where(outfitId: ...)` filter is added server-side rather
  than client-side), that filtering decision (§6, Edge Cases) would need to
  be revisited.

---

## Completion block

```
Status: IMPLEMENTED (A23 [L] deferred to live-verification pass)

[x] Gate 1  Interface documented  — lib/features/saved/repository/outfits_repository.dart
[x] Gate 2  Unit                  — test/features/saved/firestore_outfits_repository_test.dart,
                                     test/features/saved/in_memory_outfits_repository_no_backend_test.dart
[x] Gate 3  Integration            — test/features/saved/outfits_cubit_dual_mode_test.dart,
                                     test/features/saved/outfits_cubit_test.dart (unmodified from
                                     pre-F16, see review-round note below),
                                     test/features/saved/saved_screens_test.dart (unmodified from
                                     pre-F16), test/app_backend_wiring_test.dart (F16_A17_app_wiring)
[ ] Gate 4  Live run               — A23 [L] pending, not exercised this task

Assertions: 22/23 PASS (A23 [L] deferred, pending live-verification pass per the agent harness contract)

F16-A22 note: OutfitsCubit does have unawaited fire-and-forget writes
(saveOrFind/upsertManual/delete/logWear/removeWear all fire the repository
call via an unawaited async closure for UI-responsiveness, matching
WardrobeCubit's F15 pattern) — every one has a try/catch that logs via
`_logError` and never rethrows, so A22 is satisfied non-vacuously, not
vacuously. See `lib/features/saved/cubit/outfits_cubit.dart`. Coverage gap
(review round, 2026-10-20): the only test actually asserting "no unhandled
Future error" exercises `saveOrFind`'s failure path
(`F16_A22` in `outfits_cubit_dual_mode_test.dart`); `upsertManual`/
`delete`/`logWear`/`removeWear`'s equivalent paths are structurally
identical (same `unawaited(() async { try {...} catch {...} })` shape,
confirmed by inspection) but are not each individually exercised by a
`runZonedGuarded` test — left as-is rather than adding four near-duplicate
tests for the same structural pattern; flag for a future reviewer if that
judgment should change.

F16-A21 note (review round, 2026-10-20): a literal "two genuinely
concurrent logWear calls, worn ends at seed + 2" test against
`fake_cloud_firestore` loses an update (lands on 1, not 2) because the fake
has no retry-on-conflict model of real Firestore transactions — the same
limitation F15 documented for `WardrobeRepository.adjustWears`
(`test/features/wardrobe/firestore_wardrobe_repository_test.dart`).
Implemented instead as a sequential-call test proving each call reads
fresh server state (not a cached argument) plus a structural
`runTransaction`-presence check, both in
`test/features/saved/outfits_cubit_dual_mode_test.dart` (`F16_A21`,
`F16_A21_structural`). Real Firestore's own transaction-retry semantics
(not simulated by this fake) are what close this gap in production.

F16-A20 note (review round, 2026-10-20): the cross-uid isolation check
through `app.dart` itself (as opposed to hand-built Cubits, which
`F16_A20` already covers) is deferred to Task 9's emulator pass, which
owns that check per the backend-wiring plan.

Review round (2026-10-20) fixes: `InMemoryOutfitsRepository`'s write
methods now return `SynchronousFuture(...)` (not `async`) so guest-mode
writes resolve inline with zero added latency — this made the
microtask-flush edits to three pre-existing tests
(`outfits_cubit_test.dart`'s wardrobe-wears test, `saved_screens_test.dart`'s
F08_A23/A24) unnecessary; all three were reverted to their original
pre-F16 form and still pass. `OutfitsCubit`'s repository parameter now
defaults to `InMemoryOutfitsRepository()` (named, not positional — Dart
disallows mixing optional-positional with named parameters in one
signature, and `clock` had to stay named for the same no-edit reason), so
`outfits_cubit_test.dart`/`builder_cubit_test.dart`'s original
`OutfitsCubit(wardrobe, clock: ...)` call needs no edit at all.
`watchOutfits()` now sorts newest-first by id descending (previously
Firestore's native lexicographic-by-doc-id order), matching guest mode's
always-newest-first ordering. `logWear`/`removeWear` now roll the Cubit's
own optimistic `worn`/`wearLog` change back to its pre-call value on a
repository transaction failure (controller ruling, D6 "reconcile on
failure" — a Firestore transaction never queues offline the way `set()`
does, so a failed transaction has no later snapshot to reconcile from).
Added `test/app_backend_wiring_test.dart`'s `F16_A17_app_wiring`, which
drives `StyloBuddyApp` itself (uidStream + firestoreOverride) rather than
hand-building both Cubits, closing the gap where `app.dart`'s own
uid-based ternary could have been inverted/hard-coded without any test
catching it.

Regression: flutter test (full suite) — see task report's fix-round
section for the exact post-fix count; flutter analyze — "No issues
found!".
```
