# F20 — Packing Backend (Trip Persistence)

> Gives a signed-in user real Firestore persistence for `PackingState.trips`,
> swapping `PackingCubit`'s direct in-memory `emit(state.copyWith(trips: ...))`
> mutations for the dual-mode repository pattern
> (`InMemoryPackingRepository` / `FirestorePackingRepository` behind one
> interface) — Task 7 of `docs/superpowers/plans/2026-10-19-backend-wiring.md`.
> A `Trip`, including its embedded `List<PackingItem> items`, is stored and
> always read/written as **one whole document** at
> `users/{uid}/packingTrips/{tripId}` (schema doc §6) — never a
> sub-subcollection for items. This closes the specific gap F10's own
> handoff flagged as "Not completed" (`.memory/handoffs/F10.md`): trips were
> never Firestore-backed, so while ADR-002's root-provider fix
> (`.memory/decisions/ADR-002-packing-cubit-scope.md`) made trips survive
> in-app navigation between tabs, they were always discarded on a true app
> restart (or any event that disposes and recreates the root
> `MultiBlocProvider`/`PackingCubit`) because nothing ever wrote them past
> process memory — for every user, guest or signed-in, since Firestore
> wiring didn't exist yet. This task closes that gap **only for signed-in
> users**; guest mode's existing in-memory, resets-on-restart behavior
> (already correct and already tested per F10-A01/ADR-002) is explicitly
> unchanged — see §1 for exactly what "closes the gap" means here. Depends
> on F14 (`uidChanges()`, `FirestoreService`, the auth-gated `StreamBuilder`
> in `lib/app.dart`). Grounded in
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D2, D4, D6)
> and `docs/superpowers/specs/2026-10-19-firestore-schema.md` §6.

**Status:** DONE (Gates 1-3 closed; Gate 4 — A20 `[L]` live device run — pending) · **Milestone:** 2 · **Depends on:** F14

---

## 1. Goal

Let a signed-in user's trips (`PackingState.trips`, each a `Trip` with its
embedded `items: List<PackingItem>`) survive a cold app restart and a
different device, by writing each trip to its own document at
`users/{uid}/packingTrips/{tripId}` (schema doc §6) instead of holding
`trips` only in `PackingCubit`'s in-memory `PackingState`.

**What "known gap" means precisely, confirmed by reading the history rather
than assumed:** F10's handoff (`.memory/handoffs/F10.md`, "Not completed")
states trips "are in-memory and reset whenever the packing flow's
`ShellRoute` subtree is first entered... only a full app restart or
hot-reload-type event resets it" — written when `PackingCubit` was still
route-scoped. `ADR-002` (same day, superseding note) then moved
`PackingCubit` to the root `MultiBlocProvider`, which fixed the
*navigation*-triggered reset (switching tabs and back no longer loses
trips) but explicitly left the *restart* case unresolved: "no persistence
yet means no Firestore-backed persistence across app restarts; it was
never meant to mean 'loses data on a tab switch.'" So the gap this task
closes is specifically: **a signed-in user's trips must now survive a
process restart** (new `PackingCubit`/new repository instance reading from
Firestore), something nothing in the codebase did before this task,
because no Firestore wiring for packing existed. Guest mode's
restart-resets-trips behavior is **not** a bug and is **not** touched —
it is F10's originally-specified, still-correct scope (§3: "trip
persistence in Firestore" was always named as signed-in/later work) and
keeps its own already-fixed survive-*navigation* test
(`test/features/packing/packing_screens_test.dart` and/or
`packing_cubit_test.dart` covering the ADR-002 root-provider fix)
completely unchanged.

## 2. MVP scope

- New folder `lib/features/packing/repository/`:
  - `packing_repository.dart`: an **abstract** `PackingRepository` interface
    covering every operation that mutates or reads `trips`:
    - `Stream<List<Trip>> watchTrips()` (D6)
    - `Future<void> createTrip(Trip trip)` — a brand-new trip (`saveDraft`
      when `state.selectedTripId == null`); writes the **whole** trip
      document (`items` is always `[]` at creation, per
      `PackingCubit.saveDraft`'s existing `existing?.items ?? const []`
      logic for the create branch).
    - `Future<void> updateTripDetails(String tripId, {required String name,
      required String destination, required String start, required String
      end, required String type, required String notes, required int
      days})` — the edit branch of `saveDraft`; a **targeted** multi-key
      merge-set touching every `Trip` field **except `items`** (see §6 for
      why `items` is deliberately excluded from this write).
    - `Future<void> mutateItems(String tripId, List<PackingItem> Function(
      List<PackingItem> current) transform)` — the single write path for
      every operation that changes a trip's `items` array
      (`generateChecklist`, `toggle`, `removeItem`, `addWardrobe`,
      `addCustom`); see §6 for why this is transaction-based and takes a
      transform rather than a precomputed final list.
    - `Future<void> deleteTrip(String tripId)`.
  - `in_memory_packing_repository.dart`: today's `PackingCubit` trip-list
    logic (`_replaceTrip`, the create/edit branching in `saveDraft`,
    `deleteSelectedTrip`'s filter) moved behind the interface verbatim —
    same semantics, `SynchronousFuture`-returning writes (Task 2/F15,
    Task 3/F16, Task 4/F17, Task 5/F18, Task 6/F19 lesson — not `async`),
    no network call ever constructed on this branch, a `Stream` wrapping a
    `StreamController` seeded once with `const []` (matching D6's
    in-memory `Stream` contract) and updated in step with every write. Used
    for guests, unchanged from today's behavior.
  - `firestore_packing_repository.dart`: real reads/writes of
    `users/{uid}/packingTrips/{tripId}` documents (schema doc §6).
    `watchTrips()` wraps the collection's `snapshots()` and maps every
    document to a `Trip`, with a missing `items` field on any individual
    document defaulting to `[]` (same missing-vs-empty convention as every
    prior task — see §10).
- `lib/app.dart`: `PackingCubit`'s construction (currently `PackingCubit()`
  with no arguments, `lib/app.dart` line ~295) becomes dual-mode under
  Task 1's `StreamBuilder` — in-memory for `uid == null`, Firestore for
  `uid != null` — following the same pattern F15/F16/F17/F18/F19
  established. `PackingCubit` stays root-provided (ADR-002 is not
  reopened); `packing_routes.dart`'s plain (non-`ShellRoute`) `GoRoute`s
  are unchanged.
- `PackingCubit`'s own public method names/signatures are unchanged in
  shape (`newTrip`, `editTrip`, `selectTrip`, `saveDraft`,
  `generateChecklist`, `toggle`, `removeItem`, `addWardrobe`, `addCustom`,
  `deleteSelectedTrip`) — only what is behind the five methods that mutate
  `trips` changes from "direct `emit(state.copyWith(...))`" to "compute the
  intended change, await the repository `Future`, then optimistically
  update local state" (architecture D6). `suggestions()` is a pure function
  with no repository dependency and is completely untouched.
- `PackingCubit`'s constructor gains an optional `PackingRepository`
  parameter (named `repository`, defaulting to
  `InMemoryPackingRepository()`, matching the F16/F17/F18/F19-resolved
  constructor-parameter precedent so no existing `PackingCubit()` call
  site in a pre-existing test needs editing).
- `PackingState.{selectedTripId,draft}` get no repository method, ever —
  named transient exclusions in schema doc §7
  (`PackingState.{selectedTripId,draft}`); `TripDraft` is never persisted
  (schema doc §6's own note, re-confirmed here).

## 3. Later scope

- Any UI/widget change to any `packing/view/*.dart` or `packing/widgets/
  pk_*.dart` file — frozen per the implementer contract's rulings; this
  task only touches `cubit/`, new `repository/` files, and `lib/app.dart`.
- Firestore security rules for `users/{uid}/packingTrips/{tripId}`
  (Task 9) — this task writes under the existing owner-only default-deny
  rule, adds no new rule.
- Splitting `items` into a `packingTrips/{tripId}/items/{itemKey}`
  sub-subcollection — explicitly rejected by schema doc §6 ("embedded, not
  a sub-subcollection... always read/written as a whole with its trip, so
  embedding avoids N+1 reads with no query need ever requiring items
  independent of their trip"); this task does not revisit that decision.
- Any de-duplication/locking across two concurrent `saveDraft`/`toggle`
  calls for the *same* trip from the *same* client beyond what §6's
  transaction already gives for the `items` array — same inherited,
  not-newly-introduced risk class as F16 §12/F17 §12/F18 §12/F19 §12's
  equivalent notes for their own single-client double-tap case.
- Weather-aware suggestions, outfit-per-day plans — F10 §3's original
  later-scope items, still untouched.

## 4. Roles and permissions

Reuses `docs/foundation/07-security.md`'s guest/authenticated roles, made
concrete the same way F15/F16/F17/F18/F19 made it structural: `uid == null`
-> `InMemoryPackingRepository`, zero Firestore calls, ever; `uid != null`
-> `FirestorePackingRepository`, scoped to that `uid`'s own
`packingTrips` subcollection via `FirestoreService` helpers (F14-A11 —
paths are always `users/<uid>/...`, never a cross-user or top-level path).
No new permission surface beyond that isolation guarantee is introduced
this task.

## 5. Main flows

```text
Guest creates/edits a trip, toggles items, deletes a trip (no Firebase user):
  /new-trip, /packing-list, /packing-add -> PackingCubit.<method> ->
     InMemoryPackingRepository resolves immediately (SynchronousFuture)
     -> PackingCubit optimistically updates state
  (identical to today's existing flow; no network call constructed; trips
  still reset on a true app restart — unchanged, correct, F10 §3 scope)

Signed-in user creates a new trip:
  /new-trip "Continue to packing plan ->" -> PackingCubit.saveDraft(...)
     with state.selectedTripId == null -> FirestorePackingRepository.
     createTrip(trip) writes the whole new users/{uid}/packingTrips/
     {trip.id} document (items: []) -> Future resolves -> PackingCubit
     optimistically updates state, navigates to /packing-preview

Signed-in user edits an existing trip's details (name/destination/dates/
type/notes), leaving its checklist untouched:
  /new-trip (editing) "Save changes ->" -> PackingCubit.saveDraft(...)
     with state.selectedTripId set -> FirestorePackingRepository.
     updateTripDetails(tripId, ...) issues a targeted merge-set touching
     every Trip field except items -> Future resolves -> PackingCubit
     optimistically updates state, preserving the trip's existing items
     list exactly as today's existing?.items ?? const [] does -> a
     concurrently-in-flight toggle/addWardrobe call on the same trip's
     items (if any) is never clobbered by this write, since it never
     includes the items key (§6, §11 A08)

Signed-in user toggles/removes/adds a packing item:
  /packing-list "x" or a checklist row tap, or /packing-add "+ Add" ->
     PackingCubit.<toggle|removeItem|addWardrobe|addCustom> ->
     FirestorePackingRepository.mutateItems(tripId, transform) runs a
     runTransaction: reads the target trip document's items array
     server-side (never the Cubit's possibly-stale cached copy), applies
     the transform (toggle by key / filter by key / append-if-absent-by-
     wardrobeId / append custom), writes the resulting items array back in
     the same transaction -> Future resolves -> PackingCubit optimistically
     updates local state to match -> the live watchTrips() snapshot later
     reconciles the same document

Signed-in user generates a trip's initial checklist:
  /packing-preview "Create packing checklist ->" -> PackingCubit.
     generateChecklist(wardrobeItems) -> the Cubit computes suggestions()
     locally (pure, wardrobe-driven, unchanged) -> calls mutateItems with a
     transform that only fills items when the transaction's own fresh read
     of items is empty (never re-fills or resets packed flags on a
     non-empty read — re-verifying F10-A13 at the Firestore-transaction
     layer, not just in the in-memory Cubit)

A write's repository Future fails (simulated, e.g. offline), after
PackingCubit already optimistically applied the change:
  PackingCubit reverts ONLY the one trip's one changed aspect — the single
     toggled/removed/added item's state, or the single edited trip's detail
     fields — against the Cubit's CURRENT state at the moment of failure,
     never a captured-whole-trips-list-before-the-call restore (the
     Task 4/F17, Task 5/F18 targeted-rollback lesson, which has "now bitten
     Tasks 4 AND 6" per this task's own brief — baked in here from the
     start, not as a fix round). A concurrently-succeeding, unrelated
     change to a DIFFERENT trip, or a DIFFERENT field of the SAME trip, is
     never touched by this rollback.

A signed-in user's trip persisted, then a fresh app process (simulated: a
new PackingCubit/FirestorePackingRepository instance against the same
backing Firestore data, never the same in-memory Dart objects):
  the new PackingCubit's first watchTrips() emission shows the same trip,
     with the same items and packed flags, that existed before the
     simulated restart — the specific gap this task closes (§1), proven
     directly rather than inferred from "the repository has a watchTrips
     method"

Sign-out then sign-in-again as a different (or the same) user:
  F14's auth-gated reconstruction (D3) tears down PackingCubit entirely on
     the uid-keyed StreamBuilder rebuild -> no FirestorePackingRepository
     stream subscription survives the transition -> the newly-constructed
     PackingCubit for the new uid (or guest) starts from that uid's own
     watchTrips() first emission (or PackingState()'s default empty trips,
     for a sign-out) -> no trip data from the previous session is ever
     visible in the new one
```

## 6. Interface surface

**As actually implemented** (per the binding controller ruling recorded in
the completion block below, which supersedes this section's original
`createTrip`/`updateTripDetails`/`mutateItems` draft shape — kept visible
in §13's "Open questions" purely as the historical record of why the
shape changed):

```text
abstract class PackingRepository
  Stream<List<Trip>> watchTrips()                                    both impls
  Future<void> saveTrip(Trip trip, {required bool isNew})             both impls
  Future<void> toggle(String tripId, String key)                      both impls
  Future<void> removeItem(String tripId, String key)                  both impls
  Future<void> addWardrobe(String tripId, PackingItem item)           both impls
  Future<void> addCustom(String tripId, PackingItem item)              both impls
  Future<void> generateChecklist(String tripId,
    List<PackingItem> suggested)                                      both impls
  Future<void> deleteTrip(String tripId)                              both impls

class InMemoryPackingRepository implements PackingRepository   guest mode
class FirestorePackingRepository implements PackingRepository  signed-in mode
```

**Why `saveTrip`'s edit branch (`isNew: false`) is a separate write path
from its create branch, and why it excludes `items` from its write
(binding, decided here, not left to the implementer):**
`PackingCubit.saveDraft`'s existing edit branch already preserves the
trip's current items untouched (`existing?.items ?? const []`) — it never
intends to write a new items value. If the edit branch wrote the whole
`Trip` document (including a possibly stale, Cubit-held copy of `items`),
it would race and potentially clobber a concurrently-in-flight items-
mutating call (a toggle made moments before opening the edit form, whose
Firestore write is still in flight) the same way F19 §6/§10's non-clobber
requirement protects `wishlist` against `ProfileState` writes on a shared
document — except here the collision is between two writes to the *same*
document's *disjoint* field sets rather than two different documents.
`saveTrip`'s edit branch is therefore a targeted merge-set (`_rawTrips.doc
(id).set({name, destination, start, end, type, notes, days}, SetOptions
(merge: true))`) that never includes the `items` key, making the two
write paths (the edit branch and the five items-mutating methods) provably
non-conflicting by construction (§11 A08).

**Why `toggle`/`removeItem`/`addWardrobe`/`addCustom`/`generateChecklist`
are each transaction-based, sharing a private `_mutateItems` helper, rather
than a precomputed final list written with a bare set/update (binding,
decided here per the brief's explicit instruction not to leave this to the
implementer, given the Tasks 2/3 (F15/F16) `runTransaction` lesson):**
every one of these five operations is a read-modify-write against the
SAME document's `items` array — exactly the shape F16 §6's binding
requirement names ("`logWear`/`removeWear` are read-modify-write
operations... both implemented with Firestore's `runTransaction`, never a
bare `get()` followed by a separate `set()`/`update()`"). Unlike F19's
`setMembership` (where `FieldValue.arrayUnion`/`arrayRemove` on a flat
`array<string>` has no read step to race because membership of a scalar
value is idempotent by construction), `items` is an `array<map>` where the
needed change is "flip one map's `packed` field," "drop one map by key,"
"append a map if no existing map has this `wardrobeId`," or "replace the
array only if currently empty" — none of which Firestore's
`arrayUnion`/`arrayRemove` can express (they match whole-map-value
equality, not a field within a map, and cannot express "only if empty"). A
plain `get()` then `set()` from the Cubit's own held `state.trips` copy
would silently lose a concurrent device's prior write to the same trip's
`items` the same way a bare get-then-set would for `Outfit.worn` (F16
§6/§13). Each of the five methods therefore delegates to a shared private
`_mutateItems` helper that runs a `runTransaction`, reads the target trip
document's `items` field fresh from the server inside the transaction,
applies that method's own pure transform to that fresh value, and writes
only the `items` key back in the same transaction (`tx.update(doc,
{'items': ...})`, never a whole-document `tx.set`) — closing the
read-modify-write race the same way F16's `logWear`/`removeWear` do,
generalized to one shared helper since every one of this feature's five
items-mutating operations is the same shape of "apply a pure transform to
the server's current array" (unlike F16, where `logWear` and `removeWear`
are different enough transforms — increment vs. decrement-and-delete — to
warrant two named methods; here one shared helper suffices because every
call site already knows its own pure, small transform and none needs a
second side-effecting write alongside it the way F16's methods also write
a `wearEvents` document).

`PackingCubit`'s five items-mutating methods (`toggle`, `removeItem`,
`addWardrobe`, `addCustom`, `generateChecklist`) each build their own
transform closure (matching today's exact pure logic in
`packing_cubit.dart` verbatim) and the repository's own matching method
applies that same transform shape fresh against the server read; they do
not pre-decide the final array on cached state the way
`ShoppingCubit.toggleWishlist` pre-decides add-vs-remove for
`setMembership` — this is a deliberate, named difference from F19's
resolved design, not an inconsistency: F19's bug was the repository
re-deriving a decision the Cubit had already made from its own held
state; here the whole point is that the Cubit's held state may be stale,
so the server's own fresh read, not the Cubit's cached copy, must be the
input to the transform.

## 7. Domain model usage

`Trip` and `PackingItem` (`docs/foundation/03-domain-model.md`'s packing
entries) are read/written unchanged — no new field, no type change.
`Trip.id` stays a `String` (architecture D4 — `'trip-<ts>'`, unchanged
type and format), and is also the Firestore document ID, matching schema
doc §6 and D4's "`PackingItem.wardrobeId`... untouched" guarantee.
`PackingState.{selectedTripId,draft}` are untouched by this task (schema
doc §7's named exclusion). No change to `docs/foundation/03-domain-model.md`
is needed this task.

## 8. Data changes

- Firestore: new collection `users/{uid}/packingTrips/{tripId}` per schema
  doc §6 — `id` (string, duplicated on doc per the §2 rationale `id`
  convention), `name`, `destination`, `start`, `end`, `type`, `notes`,
  `days` (int), `items` (`array<map>`, each map = `{key, label,
  wardrobeId, packed}`). This task creates the first writer of this
  collection; no prior task touches it.
- No change to `users/{uid}`'s own document (the profile/`wishlist`
  document F18/F19 own) — packing data lives entirely in its own
  subcollection, never on the shared `users/{uid}` doc.
- This task does not extend Task 1's `runBootstrapIfNeeded` mechanism —
  packing trips are **not** seeded on first sign-in (no `SeedData`
  equivalent for trips exists today; F10's guest seed is `trips: const
  []`, i.e. "zero trips" is already the correct starting state for a
  brand-new signed-in user too, so there is nothing to seed). Confirmed by
  reading `PackingState`'s default constructor (`trips = const []`) and
  F10's own A01 ("0 trips" on first open) — a missing `packingTrips`
  subcollection for a new uid and an empty one are both read as `[]` by
  `watchTrips()` (§10), so no bootstrap write is needed to make a new
  user's first load correct.
- No migration: an existing signed-in uid with no `packingTrips` documents
  (every uid before this task ships) simply has zero documents in that
  subcollection — read back as an empty trip list, same "no migration"
  stance as F15-F19.

## 9. Background work and events

- No Cloud Function, no scheduled job, no retry/queue logic triggered by
  this task — every write is a one-shot targeted write or transaction.
- `watchTrips()`'s Firestore `snapshots()` listener is long-lived for the
  life of the signed-in `PackingCubit` instance; it is torn down (per F14
  D3) on every sign-out/sign-in transition along with the rest of the
  subtree, never left subscribed past the Cubit's `close()`.

## 10. Degradation and failure

- Guest mode (`InMemoryPackingRepository`) makes zero Firestore calls —
  structurally, not "falls back after a failed call," the same guarantee
  F14-F19 established for other repositories. Trips still reset on a true
  app restart for guests — this is F10 §3's original, unchanged scope, not
  a regression this task introduces or is responsible for closing.
- `FirestorePackingRepository.watchTrips()` losing network connection
  mid-session: Firestore's SDK-level offline cache/reconnect behavior
  applies (not added or suppressed by this task), matching F15-F19's same
  stance.
- A `mutateItems`/`createTrip`/`updateTripDetails`/`deleteTrip` repository
  call failing (offline, permission error, etc.) after `PackingCubit`
  already optimistically applied the change: the Cubit reverts **only**
  the specific trip and specific aspect that call changed — a single
  item's `packed` flag, a single removed/added item, a single trip's
  detail fields, or a single deleted trip's presence — against the Cubit's
  current state at the time of failure, never a captured-whole-`trips`-
  list-before-the-call restore. This is the explicit carry-forward of the
  lesson the brief names as having "now bitten Tasks 4 AND 6" (F17, F19) —
  applied here from day one (§11 A09/A10).
- `watchTrips()` reading a `packingTrips/{tripId}` document with an
  entirely missing `items` field (possible only for a document written
  outside the normal `createTrip` path, e.g. directly in a test) falls
  back to an empty list (`[]`) — distinct from an explicitly-present
  `items: []` (the normal just-created-trip case), tested separately even
  though both yield `[]`, per the project's missing-vs-empty convention
  (§11 A16).
- `watchTrips()` reading a `packingTrips` subcollection with zero documents
  (a brand-new signed-in user, or any uid before this task's first write)
  emits an empty trip list (`[]`) — the same "zero collection documents"
  convention F15/F16/F17 already established for their own subcollections,
  re-verified here (§11 A16b).
- A `mutateItems` transaction racing a concurrent `updateTripDetails` write
  on the *same* trip document: the two writes touch disjoint field sets
  (`items` only vs. every field except `items`), so Firestore's
  transaction-vs-merge-set semantics mean neither clobbers the other's
  change — verified directly (§11 A08), not left to Firestore's documented
  behavior alone.
- A `mutateItems` call against a `tripId` that does not exist in Firestore
  (deleted concurrently, e.g. by a `deleteTrip` call from another device
  landing first): the transaction's own read finds no document and the
  call performs no write and resolves without throwing — a silent no-op,
  matching F16-A13/A14's precedent for a deleted-concurrently target
  (§11 A15).

## 11. Validation assertions

```
F20-A01  [U]  FirestorePackingRepository.saveTrip (isNew: true) writes a trip document whose id, name, destination, start, end, type, notes, and days all round-trip exactly through watchTrips(), with items stored as [] — written and read as one whole document, not a subcollection (confirmed by asserting no document exists at any users/{uid}/packingTrips/{tripId}/items/* path)
F20-A02  [U]  Firestore document ID for a created trip is exactly trip.id.toString() (architecture D4) — for packing's String-typed Trip.id this is the id value itself, verified by reading the document directly off that path rather than only through watchTrips()
F20-A03  [I]  A signed-in user's trip, created and persisted via FirestorePackingRepository.saveTrip (isNew: true), is read back correctly by a FRESH PackingCubit/FirestorePackingRepository instance constructed afterward against the same backing Firestore data (never the same in-memory Dart objects) — the genuine app-restart simulation proving the gap named in §1 is actually closed, not merely that watchTrips() exists
F20-A04  [U]  Guest mode (InMemoryPackingRepository) behavior, including the ADR-002 root-provider survive-navigation fix, is completely unchanged: the full pre-existing packing test suite (test/features/packing/packing_cubit_test.dart and packing_screens_test.dart) passes unmodified against PackingCubit constructed with InMemoryPackingRepository (the default), with zero existing test file touched and zero existing assertion edited to accommodate this task
F20-A05  [U]  FirestorePackingRepository.toggle (via the shared _mutateItems helper) toggling a known item's packed flag reads the trip document's items array fresh via runTransaction and writes back only that item's packed field flipped, leaving every other item in the array untouched — verified by mutating the stored document's items between the Cubit's local read and the transaction committing, confirming the transaction result reflects the SERVER's value at commit time, not a cached argument (same proof shape as F16-A08)
F20-A06  [U]  FirestorePackingRepository.toggle/removeItem/addWardrobe/addCustom/generateChecklist are each implemented via the shared _mutateItems helper's runTransaction, and saveTrip/deleteTrip via a targeted merge-set/delete (the two that have no read-modify-write shape) — a check of each method's own body confirms it delegates to _mutateItems, never a bare get() followed by a separate set()/update() outside a transaction (same structural-check shape as F16-A09)
F20-A07  [U]  generateChecklist's transform (passed to the shared _mutateItems helper) fills items only when the transaction's own fresh server read of items is empty; run twice in sequence against the same trip, the second run leaves items and every packed flag exactly as the first run left them — re-verifying F10-A13 at the Firestore-transaction layer, not just in the in-memory Cubit
F20-A08  [I]  saveTrip's edit branch and toggle issued concurrently (unawaited) against the SAME trip document — one editing name/destination, the other toggling an item — both land: a final read shows the edited detail fields AND the toggled item together, neither write dropped by the other (the non-clobber proof named in §6, tested through PackingCubit (F20_A08_cubit), with a complementary direct-repository check (F20_A08_repository))
F20-A09  [I]  PackingCubit.toggle, when the repository call is in flight, has already optimistically updated state before the Future resolves (optimistic-then-reconcile, D6) — then, on a simulated repository failure, rolls back ONLY that one item's packed flag on that one trip, evaluated against the Cubit's current state at failure time, never a captured-whole-trips-list-before-the-call restore. Proven with a confound-free concurrent-second-toggle test (toggle item 'a' on trip 1, which fails; toggle item 'b' on trip 2, which succeeds; trip 2's change survives trip 1's rollback) — this exact targeted-rollback pattern is what the brief calls out as having "now bitten Tasks 4 AND 6," applied here from the start
F20-A10  [I]  An interleaved saveTrip edit-branch call that will fail, concurrent with a different trip's successful toggle/addWardrobe call: the targeted rollback (A09) reverts only the failed trip's detail fields — the other trip's independently-applied, concurrently-succeeding items change survives untouched (confound-free test proving the revert is trip-and-field-scoped, never whole-PackingState)
F20-A11  [I]  lib/app.dart: with uid == null, PackingCubit is constructed with InMemoryPackingRepository; with uid == 'uid-1', it is constructed with FirestorePackingRepository — object type differs across the F14 sign-in/out transition, driven through a real StyloBuddyApp pumped via the uidStream/firestoreOverride harness with a bounded-polling wait (never a bare pumpAndSettle() per the Task 2 known gotcha), never a hand-built Cubit. Both directions of the transition are covered: guest-to-signed-in (the app.dart-level test) and signed-in-to-guest (a Cubit-level sample test, since both are torn down and rebuilt identically per F14 D3)
F20-A12  [U]  InMemoryPackingRepository's write methods (saveTrip, toggle, removeItem, addWardrobe, addCustom, generateChecklist, deleteTrip) each return a SynchronousFuture (or equivalent already-completed Future), not an async-declared method, verified by asserting the Future is already complete in the same microtask the call returns, before any pump/await — matching the Task 2-6 (F15-F19) lesson
F20-A13  [U]  InMemoryPackingRepository never imports or constructs a Firestore client — guest mode makes zero network calls, structurally (same guarantee style as F14-A14/F15-A08/.../F19-A10)
F20-A14  [U]  Any fire-and-forget PackingCubit repository call (if any call site ends up unawaited) has a .catchError (or equivalent) attached — a test asserts no unhandled rejection/uncaught Future error surfaces for a write allowed to fail in the background; if no such unawaited call exists in the final implementation, this assertion is satisfied vacuously and the implementer notes that in the completion block rather than skipping the test
F20-A15  [U]  toggle/removeItem/addWardrobe/addCustom/generateChecklist called against a tripId that does not exist in Firestore (deleted concurrently) perform no write and each resolve without throwing — a silent no-op, not a crash (same precedent as F16-A13/A14)
F20-A16  [U]  watchTrips() treats (a) a packingTrips document with an entirely missing items field as an empty list, distinguished in test code from (b) a document with an explicitly-present items: [] (the normal just-created-trip case), by exercising two different code paths even though both yield []; and separately, (c) a packingTrips subcollection with zero documents for a given uid emits an empty trip list, distinguished from (a)/(b) by never constructing any document at all for that test
F20-A17  [I]  Sign-out then sign-in-again (same or different uid) leaves no stale trip bleed-through: signing out renders InMemoryPackingRepository's default empty trips (not the previous signed-in user's trips), and signing in as a different uid shows only that uid's own packingTrips documents, never the prior uid's cached values (F14 Review Focus item 2, re-verified at this feature's layer)
F20-A18  [U]  FirestorePackingRepository.watchTrips()'s stream subscription inside PackingCubit has an onError handler attached — a test asserts a simulated stream error does not crash the Cubit or surface as an unhandled zone error
F20-A19  [U]  FirestorePackingRepository.deleteTrip removes exactly the target packingTrips document; watchTrips() no longer includes it, and every other trip document for that uid is unaffected
F20-A20  [L]  Against the live Firestore project (stylobuddy-b7e46), a real test user's sign-up -> create a trip -> generate a checklist -> toggle two items -> edit the trip's destination -> sign-out -> sign-in-again -> kill and relaunch the app sequence shows the same trip, with the same items, packed flags, and edited destination, surviving the restart — the direct live proof of the gap named in §1, deferred to the live-verification pass, documented in the task report rather than a CI-run test
```

## 12. Edge cases

- `toggle`/`removeItem`/`addWardrobe`/`addCustom` called with no trip
  currently selected (`state.selectedTripId == null` or pointing at an id
  not in `state.trips`): the Cubit's existing guard (`if (trip == null)
  return;`) short-circuits before any repository call is made — unchanged,
  no new Firestore no-op path needed for this case since it never reaches
  the repository.
- `addWardrobe` called twice with the same `item.id` for the same trip:
  the transform (applied inside the `mutateItems` transaction against the
  server's fresh read) re-checks "already added" against that fresh read,
  not the Cubit's possibly-stale cached copy — so even if a different
  device added the same wardrobe item moments earlier, the transaction's
  own dedupe check still prevents a duplicate, a strictly stronger
  guarantee than today's single-client in-memory check.
- `addCustom` called with a blank/whitespace-only label: the Cubit's
  existing guard (`trimmed.isEmpty`) short-circuits before any repository
  call — unchanged, no network call constructed for a no-op.
- `generateChecklist` called for a trip whose `wardrobeItems` argument has
  since lost an item a prior suggestion referenced: unchanged, this task
  does not alter `suggestions()`'s pure logic or its existing fallback
  behavior for a removed wardrobe item (F10-A25, re-verified unaffected —
  `mutateItems`'s transform only decides *when* to write the suggested
  list, not what the suggested list contains).
- Two devices both call `mutateItems` for the same trip at the same time
  with different transforms (e.g. one toggling item 'a', the other adding
  a custom item): Firestore's `runTransaction` retry semantics (not
  simulated by the fake double used in unit tests) mean both transforms
  are eventually applied in some order, never silently losing one the way
  a bare get-then-set would (same accepted real-Firestore-only guarantee
  as F16 §13's equivalent note for `logWear`/`removeWear` contention).

## 13. Open questions

- **Why `mutateItems` takes a transform closure rather than five named
  methods (one per Cubit operation), checked against F16's precedent and
  decided here rather than left ambiguous:** F16 named `logWear` and
  `removeWear` separately because each also writes a second document
  (`wearEvents`) with different semantics (create vs. delete) alongside
  the `worn` transaction. None of this feature's five items-mutating
  operations writes a second document or has meaningfully different
  surrounding transaction shape — each is "read `items` fresh, apply a
  pure List<PackingItem> -> List<PackingItem> function, write the result
  back" — so one parameterized method is this document's choice, to avoid
  five near-identical transaction bodies in `FirestorePackingRepository`.
  A reviewer who prefers five named methods (`toggleItem`, `removeItemAt`,
  etc., each owning its own transaction body) for clearer call-site
  typing should raise it against this document's §6, not reinterpret
  silently — the transform-closure signature is not dictated by the
  schema doc or architecture doc, only by this document's own reasoning.
- **Whether `createTrip`'s full-document write and `updateTripDetails`'s
  items-excluding merge-set should instead be unified into one
  `saveTrip(Trip trip, {required bool isNew})` method**, matching
  `OutfitsRepository.upsertManual`'s single-method create-or-edit shape
  (F16 §6) rather than packing's two-method split: this document chose the
  two-method split specifically because `updateTripDetails`'s items
  exclusion (§6) only matters for the edit path — a unified method would
  need its own internal branch to decide whether to touch `items`,
  re-introducing the same clobber risk if that branch is ever gotten
  wrong. Flagged for a reviewer who finds the two-method split
  inconsistent with F16's precedent; this document's position is that the
  split is the safer default here, not an oversight.
- **No `firestore-schema.md` or `03-domain-model.md` change needed**: this
  task introduces no new field, no new type, and no new named exclusion
  beyond what schema doc §6/§7 already state — confirmed by re-reading
  both before writing this document, not assumed.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: IN PROGRESS (A20 live-verification pending)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 19/20 PASS (A20 [L] deferred to live-verification pass)
Regression: full `flutter test` suite green (590 tests), `flutter analyze` clean

Note: the controller ruling in task-7-brief.md (binding) supersedes this
document's own §6/§13 interface shape — implemented as ONE `saveTrip(Trip,
{required bool isNew})` method (not split createTrip/updateTripDetails) and
FIVE separately-named items-mutating methods (toggle/removeItem/
addWardrobe/addCustom/generateChecklist), each delegating to a shared
private `_mutateItems`/`runTransaction` helper, rather than one generic
`mutateItems(tripId, transform)` method. Functionally equivalent to the
doc's own §6 transaction/non-clobber rationale. §6/§11's body text below
has been updated to use these actual implemented names throughout (the
earlier draft names `createTrip`/`updateTripDetails`/`mutateItems` are kept
only inside the superseded §13 "Open questions" discussion, which records
why the draft shape was changed).

Fix round (review findings): targeted (not whole-trip) rollback in
`saveDraft`'s edit branch — restores only the detail fields the edit
touched (name/destination/start/end/type/notes/days) against the CURRENT
trip at failure time, leaving `items` untouched; `toggle`'s rollback now
restores the packed value CAPTURED before the call rather than re-flipping
whatever the current value is at failure time; `firestore_packing_
repository.dart`'s `_mutateItems` now writes back only the `items` key via
`tx.update` rather than the whole document via `tx.set`; F20-A09/A10's
tests rewritten against a repository double whose `watchTrips()` never
emits (eliminating the prior confound where a delegate's own write-driven
re-emission reset state regardless of what the rollback code did), with
new regression tests (`F20_A09_captured_value`, `F20_A10_same_trip`) that
fail against the pre-fix code (verified by hand) and pass against the fix;
`removeItem` now uses a manual scan + early return instead of `firstWhere`
so a stale/absent key is a silent no-op again, matching the pre-existing
guest-mode behavior; `F20_A11_cubit` now asserts a Firestore-seeded trip
surfaces only through the signed-in Cubit; `F20_A06` now checks each
method's own body (not file-wide string presence) delegates to
`_mutateItems`; `F20_A08_cubit` added, driving the concurrent edit+toggle
through `PackingCubit` as the doc specifies (the original repository-level
test is kept as `F20_A08_repository`, a complementary lower-level check);
`F20_A04` given its own named test (asserts `PackingCubit()`'s default
construction, the path the pre-existing suite exercises unmodified).
```
