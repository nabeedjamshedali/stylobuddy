# F19 — Shopping Wishlist Backend

> Gives a signed-in user real Firestore persistence for `ShoppingState.wishlist`
> only, swapping `ShoppingCubit`'s direct in-memory `copyWith(wishlist: ...)`
> mutation for the dual-mode repository pattern (`InMemoryShoppingRepository` /
> `FirestoreShoppingRepository` behind one interface) — Task 6 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`. `ShoppingCatalog`
> itself (the five fixed `ShopEntry` rows) stays a bundled Dart constant,
> never read from or written to Firestore — only `wishlist`, a handful of
> `ShopEntry.id` strings, gets a repository method. `wishlist` lives on the
> **same** `users/{uid}` document F18's `ProfileRepository` already owns
> (schema doc §1), seeded there as `[]` by F18's now-fixed combined D5
> bootstrap — this document's central job is making the shared-document write
> path unambiguous: Task 6 is the *sole* post-bootstrap writer of `wishlist`,
> `ProfileRepository` exposes no method that touches it (confirmed in F18 §3/
> §13), and neither repository's writes may clobber the other's fields on that
> document. Depends on F14 (`uidChanges()`, `FirestoreService`, the
> auth-gated `StreamBuilder` in `lib/app.dart`) and F18 (the combined D5
> bootstrap that seeds `wishlist: []` alongside Profile's fields on the same
> document — Task 6 cannot land before Task 5's seed exists). Grounded in
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D2, D4, D5, D6)
> and `docs/superpowers/specs/2026-10-19-firestore-schema.md` §1.

**Status:** DONE (pending [L] live-verification pass) · **Milestone:** 2 · **Depends on:** F14, F18

---

## 1. Goal

Let a signed-in user's saved shopping suggestions (`ShoppingState.wishlist`,
a list of `ShopEntry.id` strings) survive a cold restart and a different
device, by writing it to the `wishlist` field on `users/{uid}` (schema doc
§1) instead of holding it only in `ShoppingCubit`'s in-memory `ShoppingState`.
A guest gets none of the Firestore part and sees exactly what the current
`flutter test` suite already verifies for `ShoppingCubit.toggleWishlist` —
no network call, no new failure mode. Because `wishlist` sits on the same
document as every `ProfileState` field, this feature's second, equally
binding goal is proving — not just asserting — that toggling wishlist
membership never resets or drops any Profile field on that document, and
that a Profile edit never resets or drops the wishlist (plan Task 6's own
explicit "reviewed explicitly for this" requirement).

## 2. MVP scope

- New folder `lib/features/shopping/repository/`:
  - `shopping_repository.dart`: an **abstract** `ShoppingRepository`
    interface with exactly the operations `ShoppingCubit` needs for
    `wishlist` — `watchWishlist()` (per architecture D6) and
    `toggleWishlist(String id)`. `ShoppingCubit.setTab`/`select` stay pure,
    unchanged, local `emit(state.copyWith(...))` calls — `tab` and
    `selectedId` are named exclusions in schema doc §7
    (`ShoppingState.{tab,selectedId}`) and get no repository method, ever.
  - `in_memory_shopping_repository.dart`: today's `ShoppingCubit.
    toggleWishlist`'s add-or-remove logic (`!state.wishlist.contains(id) ?
    [...wishlist, id] : wishlist.where((x) => x != id).toList()`) moved
    behind the interface verbatim — same semantics, same
    synchronous-feeling writes (`SynchronousFuture`, per the Task 2/F15,
    Task 3/F16, Task 4/F17, Task 5/F18 lesson — not `async`), no network
    call ever constructed on this branch. Used for guests, unchanged from
    today's `ShoppingCubit`-held logic.
  - `firestore_shopping_repository.dart`: real reads/writes of **only the
    `wishlist` key** on `users/{uid}` (schema doc §1) — `watchWishlist()`
    wraps `userDoc(uid).snapshots()` and maps the document to just its
    `wishlist` array (missing key -> `[]`, exactly like F18's
    `_listField`'s missing-vs-empty handling, not a coincidence — same
    convention, applied to one field instead of eleven). `toggleWishlist`
    computes the next array the same add-or-remove way the in-memory
    repository does (reading the current array off a `get()`/the latest
    cached snapshot, since there is no Firestore
    `FieldValue.arrayUnion`/`arrayRemove` ambiguity-free way to "toggle" —
    see §6/§13 for why this needs a `runTransaction`-free but still
    read-then-write call, and why that is *not* a repository-side
    read-modify-write of a *numeric* value the way F16's `logWear` was —
    it is a plain list membership flip, same shape as `ProfileCubit.
    togglePreference`'s Cubit-side computation in F18, just computed here
    since `ShoppingCubit` has no equivalent Cubit-side "already knows the
    final list" step today). The write itself is **always** a targeted
    field update — `_doc.set({'wishlist': nextList}, SetOptions(merge:
    true))` (same shape as F18's `_merge`) or `_doc.update({'wishlist':
    nextList})` — **never** `_doc.set({...wholeProfileShape})` and never a
    write that omits `merge: true`/uses bare `update` on more than the one
    key. This is the binding non-clobber requirement (§10, §11 A05/A06).
  - **Binding requirements carried forward from Tasks 2–5's review
    rounds, applied from day one, not as a second-round fix:**
    1. Any fire-and-forget `toggleWishlist` call (if `ShoppingCubit`'s
       call site ends up unawaited) gets a `.catchError` attached.
    2. `ShoppingCubit`'s `watchWishlist()` stream subscription has an
       `onError` handler — never an unhandled stream error.
    3. If `toggleWishlist`'s repository `Future` fails after
       `ShoppingCubit` has already optimistically updated `state`, the
       Cubit rolls back **targeted to only the `wishlist` field**,
       evaluated against the Cubit's *current* state at failure time,
       never a whole-`ShoppingState` snapshot captured before the call
       (D6 "reconcile on failure"; same lesson F17/F18 baked in from the
       start — see §13). In practice this means reverting only
       `wishlist`, never touching `tab`/`selectedId` even though they
       live on the same `ShoppingState` object.
- `lib/app.dart`: `ShoppingCubit`'s construction (currently
  `ShoppingCubit()` with no arguments, line ~283) becomes dual-mode under
  Task 1's `StreamBuilder` — in-memory for `uid == null`, Firestore for
  `uid != null` — following the same pattern F15/F16/F17/F18 established.
- `ShoppingCubit`'s own public method names/signatures are unchanged in
  shape (`setTab`, `select`, `toggleWishlist` — including its existing
  `bool` return value, "added" vs. "removed", used by the caller to decide
  the toast copy); only what is behind `toggleWishlist` changes from
  "direct `emit(state.copyWith(...))`" to "compute the next list, await
  the repository `Future`, then optimistically update local state"
  (architecture D6).
- **No duplicate write path.** `ProfileRepository` (F18) exposes no
  `wishlist`-shaped method and never includes `'wishlist'` in any `_merge`/
  `_toFirestore` payload (confirmed by reading
  `lib/features/profile/repository/firestore_profile_repository.dart` —
  its `_toFirestore` emits exactly the 11 `ProfileState` keys, and its
  `bootstrapIfNeeded`'s one-time seed write is the only place `'wishlist'`
  appears in that file, as a bootstrap default, never on a later write).
  `FirestoreShoppingRepository` is therefore the only code in the app that
  issues a non-bootstrap write touching `'wishlist'` — this is a stated
  design constraint (§6), not just an observation, and §11 A05 tests it
  directly against both repository sources.

## 3. Later scope

- `ShoppingCatalog` moving to Firestore/remote config — explicitly out of
  scope per architecture D2/schema doc's "What's explicitly excluded" (§1):
  it is bundled app config, not user data, and stays a static Dart
  constant.
- `ShoppingState.tab`/`selectedId` getting any repository method — named
  exclusions in schema doc §7, unchanged by this task.
- Firestore security rules for `users/{uid}` (Task 9) — this task writes
  under the existing owner-only default-deny rule, adds no new rule.
- Any UI/widget change to `shopping_view.dart`/`shop_item_view.dart` or any
  `widgets/sh_*.dart` file — frozen per the implementer contract's rulings;
  this task only touches `cubit/`, new `repository/` files, and
  `lib/app.dart`.
- A richer wishlist data shape (e.g. storing a `savedAt` timestamp per
  item) — schema doc §1 names `wishlist` as `array<string>` of
  `ShopEntry.id`s only; this task does not extend that shape.

## 4. Roles and permissions

Reuses `docs/foundation/07-security.md`'s guest/authenticated roles, made
concrete the same way F15/F16/F17/F18 made it structural: `uid == null` ->
`InMemoryShoppingRepository`, zero Firestore calls, ever; `uid != null` ->
`FirestoreShoppingRepository`, scoped to that `uid`'s own document via
`FirestoreService.userDoc` (F14-A11 — paths are always `users/<uid>`, never
a cross-user or top-level path). No new permission surface beyond that
isolation guarantee is introduced this task.

## 5. Main flows

```text
Guest toggles a wishlist item (no Firebase user):
  /shopping or a shop detail screen -> ShoppingCubit.toggleWishlist(id) ->
     InMemoryShoppingRepository resolves immediately (SynchronousFuture)
     -> ShoppingCubit optimistically updates state, returns true/false
  (identical to today's existing flow; no network call constructed)

Signed-in user toggles a wishlist item:
  Shop screens -> ShoppingCubit.toggleWishlist(id) ->
     FirestoreShoppingRepository reads the current wishlist array off
     users/{uid}, computes the add-or-remove result, writes it back via a
     targeted merge-set/update touching only the wishlist key -> Future
     resolves -> ShoppingCubit optimistically updates state, returns
     true/false -> the live watchWishlist() snapshot later reconciles the
     same document

A brand-new user signs up (first-ever sign-in for that uid):
  F18's combined D5 bootstrap (FirestoreService.runBootstrapIfNeeded,
     unchanged mechanism) already writes wishlist: [] on the same
     transaction that seeds ProfileState's defaults (F18-A03, re-verified
     not re-implemented here) -> ShoppingCubit's first watchWishlist()
     emission shows an empty wishlist, not a missing field

A signed-in user toggles wishlist, then edits a Profile field (or vice
versa), in close succession:
  ShoppingCubit.toggleWishlist(id) issues a targeted write touching only
     'wishlist' on users/{uid} -> ProfileCubit.<setter> issues its own
     targeted merge-set touching only its own changed field(s) on the
     same document (F18 §6) -> Firestore's merge-set semantics mean
     neither write's absent keys are touched by the other -> a
     watchProfile()/watchWishlist() read after both resolve shows both
     changes present together, never one silently reverted by the other's
     write landing after it (§10, §11 A05/A06 — the plan's "reviewed
     explicitly for this" requirement)

A write's repository Future fails (simulated, e.g. offline):
  ShoppingCubit has already optimistically applied the new wishlist to
     state -> the Future rejects -> ShoppingCubit reverts ONLY wishlist to
     its pre-toggle value, against its current state at the moment of
     failure -> tab/selectedId, if changed by an unrelated, concurrently
     in-flight call, are left untouched (F17/F18's targeted-revert lesson,
     applied here from the start)

Sign-out then sign-in-again as a different (or the same) user:
  F14's auth-gated reconstruction (D3) tears down ShoppingCubit entirely
     on the uid-keyed StreamBuilder rebuild -> no
     FirestoreShoppingRepository stream subscription survives the
     transition -> the newly-constructed ShoppingCubit for the new uid
     (or guest) starts from that uid's own watchWishlist() first emission
     (or ShoppingState()'s default empty wishlist, for a sign-out) -> no
     wishlist data from the previous session is ever visible in the new
     one, re-verifying Review Focus item 2 at this feature's own layer
```

## 6. Interface surface

```text
abstract class ShoppingRepository
  Stream<List<String>> watchWishlist()                      both impls
  Future<bool> toggleWishlist(String id)                    both impls
    -- returns true when id was added, false when removed,
       mirroring ShoppingCubit.toggleWishlist's existing bool contract

class InMemoryShoppingRepository implements ShoppingRepository   guest mode
class FirestoreShoppingRepository implements ShoppingRepository  signed-in mode
```

`ShoppingCubit`'s public surface (`setTab`, `select`, `toggleWishlist`) is
unchanged in shape and return type. `ShoppingCubit`'s constructor gains an
optional `ShoppingRepository` parameter (named `repository`, defaulting to
`InMemoryShoppingRepository()`, matching the F16/F17/F18-resolved
constructor-parameter precedent so no existing `ShoppingCubit()` call site
in a pre-existing test needs editing).

`FirestoreShoppingRepository.toggleWishlist` is the **only** write method
on this interface, and it is the one case in this feature where a plain
"hand the repository the final value" shape (F18's stance for every
`ProfileRepository` setter) does not apply — `ShoppingCubit` does not
pre-compute the next list the way `ProfileCubit.togglePreference` does for
styles/occasions, because `ShoppingCubit.toggleWishlist`'s `bool`
add-or-removed return value is itself derived from membership state the
repository is the one holding (for the signed-in case) or computing (for
the in-memory case). `FirestoreShoppingRepository.toggleWishlist` therefore
reads the current `wishlist` array (a single `get()`/the latest value
observed by its own `watchWishlist()` subscription — implementer's choice,
binding only on the observable outcome in §11) and writes back the
add-or-remove result in one targeted call. This is **not** a
`runTransaction` requirement the way F16's `logWear`/`removeWear` needed
one: a double-toggle race (two rapid taps) loses to last-write-wins exactly
the same way F18 §12 already accepts for `togglePreference`, not a new
risk class — see §13.

The write itself — regardless of whether it is phrased as `_doc.set({
'wishlist': next}, SetOptions(merge: true))` or `_doc.update({'wishlist':
next})` — touches **only** the `wishlist` key. Neither shape is a
whole-document `set()` without `merge: true`/without being scoped to one
key; this is the binding non-clobber constraint carried from F18's own
Important #5 lesson, applied here in the other direction (shopping writes
must not clobber Profile fields, exactly as Profile writes must not clobber
`wishlist`).

## 7. Domain model usage

`ShoppingState.wishlist` (`List<String>`, `docs/foundation/03-domain-model.md`'s
`ShoppingState` entry) is read/written unchanged — no new field, no type
change. `ShoppingState.tab`/`selectedId` are untouched by this task (schema
doc §7's named exclusion). No change to `docs/foundation/03-domain-model.md`
is needed this task.

## 8. Data changes

- Firestore: `users/{uid}` document, `wishlist: array<string>` field per
  schema doc §1 — already named there as `wishlist`'s home, already seeded
  as `[]` by F18's combined D5 bootstrap. This task adds no new field and
  no new collection; it adds the first and only post-bootstrap writer of
  that one existing field.
- This task **extends neither** Task 1's `runBootstrapIfNeeded` mechanism
  nor F18's `bootstrapIfNeeded` seed payload — `wishlist: []`'s seed write
  is already implemented and tested by F18 (F18-A03); this task does not
  re-touch that code path, confirmed by reading
  `firestore_profile_repository.dart`'s `bootstrapIfNeeded` (only place
  `'wishlist'` appears in that file).
- No migration: for any uid whose `users/{uid}` document already exists
  from an earlier task's own bootstrap writes, this task adds no backfill
  — if `seeded` is already `true` for a uid before this task's code runs
  for them, `wishlist` is whatever F18's bootstrap already wrote (`[]` or,
  for a uid bootstrapped before F18 shipped, possibly absent — see §10's
  missing-field handling) — same "no migration" stance as F15/F16/F17/F18.

## 9. Background work and events

- No Cloud Function, no scheduled job, no retry/queue logic triggered by
  this task — `toggleWishlist` is a one-shot targeted write.
- `watchWishlist()`'s Firestore `snapshots()` listener is long-lived for
  the life of the signed-in `ShoppingCubit` instance; it is torn down (per
  F14 D3) on every sign-out/sign-in transition along with the rest of the
  subtree, never left subscribed past the Cubit's `close()`.

## 10. Degradation and failure

- Guest mode (`InMemoryShoppingRepository`) makes zero Firestore calls —
  structurally, not "falls back after a failed call," the same guarantee
  F14/F15/F16/F17/F18 established for other repositories.
- `FirestoreShoppingRepository.watchWishlist()` losing network connection
  mid-session: Firestore's SDK-level offline cache/reconnect behavior
  applies (not added or suppressed by this task), matching F15/F16/F17/F18's
  same stance.
- A `toggleWishlist` repository call failing (offline, permission error,
  etc.) after `ShoppingCubit` already optimistically applied the new
  wishlist value: the Cubit reverts **only** `wishlist`, against its
  current state at the time of failure — never a captured-whole-
  `ShoppingState`-before-the-call restore, which could wipe a `tab`/
  `selectedId` change a different, concurrently-in-flight call had just
  made (F17/F18's own review-round-avoided bug, applied here from day one;
  see §11 A09/A10).
- `watchWishlist()` reading a `users/{uid}` document with an entirely
  missing `wishlist` field (practically unlikely given F18's bootstrap
  seeds it, but possible for a uid bootstrapped before F18's `wishlist`
  seeding landed, or any document mutated directly for a test) falls back
  to an empty list (`[]`) — distinct from an explicitly-present-but-empty
  array (`wishlist: []`, the normal just-bootstrapped case), which is read
  back verbatim as the same empty list by coincidence of value but via a
  different code path (one default-substitutes, the other reads a real
  value) — both are tested separately in §11 A11/A12 even though they
  produce the same `[]` result, because the project's missing-vs-empty
  convention (`03-domain-model.md` §4) requires the two paths be provably
  distinct in code, not merged into one untested assumption.
- A `toggleWishlist` call racing a Profile field write (or the reverse) on
  the same document: both are targeted `merge: true` writes touching
  disjoint keys, so Firestore's own merge-set semantics (not anything this
  task adds) guarantee neither write's omitted keys are touched — this is
  the "no duplicate write path"/"reviewed explicitly" requirement (§2, §6),
  verified directly rather than left to Firestore's documented behavior
  alone (§11 A05/A06).

## 11. Validation assertions

```
F19-A01  [U]  FirestoreShoppingRepository.toggleWishlist adding an id not already present results in watchWishlist() emitting a list containing that id, read back via Firestore's own array field on users/{uid} (not a duplicated in-memory cache)
F19-A02  [U]  FirestoreShoppingRepository.toggleWishlist removing an id already present results in watchWishlist() emitting a list without that id
F19-A03  [U]  FirestoreShoppingRepository.toggleWishlist returns true when the id was added and false when it was removed, matching ShoppingCubit.toggleWishlist's existing bool contract verbatim
F19-A04  [U]  ProfileRepository (F18) exposes no method whose name or payload references wishlist — grepping lib/features/profile/repository/firestore_profile_repository.dart's non-bootstrap write methods (updateDetails, setStyles, setOccasions, setDailyNotifications, setPlannedNotifications, setProductNotifications, setWeatherConsent, setClimate, setPlan, setBillingCycle) confirms none include 'wishlist' in its written field set — FirestoreShoppingRepository is the sole non-bootstrap writer of that field
F19-A05  [I]  A real Firestore round-trip (fake_cloud_firestore): ShoppingCubit.toggleWishlist(id) followed immediately by ProfileCubit.setClimate(v) against the same uid's document results in a final read showing BOTH the toggled wishlist AND the updated climate present together — neither write's resolution dropped the other's change (the plan's "reviewed explicitly for this" requirement, tested directly, not inferred)
F19-A06  [I]  The reverse ordering of A05 (ProfileCubit.setOccasions(...) followed immediately by ShoppingCubit.toggleWishlist(id)) produces the same non-clobbering result — both fields present, order-independent
F19-A07  [U]  Every FirestoreShoppingRepository write to users/{uid} is a targeted update touching only the wishlist key — a test double/fake records the exact field-key set written by toggleWishlist and asserts it is exactly {'wishlist'}, never a payload containing any ProfileState-owned key (name, email, styles, occasions, dailyNotifications, plannedNotifications, productNotifications, weatherConsent, climate, plan, billingCycle) and never an unscoped whole-document set() call
F19-A08  [U]  Guest mode (InMemoryShoppingRepository) behavior is unchanged from today's ShoppingCubit-held logic — the full pre-existing shopping-related test suite (test/features/shopping/shopping_cubit_test.dart or equivalent) passes unmodified against ShoppingCubit constructed with InMemoryShoppingRepository, with zero existing assertion edited to accommodate this task
F19-A09  [U]  InMemoryShoppingRepository's toggleWishlist returns a SynchronousFuture (or equivalent already-completed Future), not an async-declared method, verified by asserting the Future is already complete in the same microtask the call returns, before any pump/await — matching the Task 2/F15, Task 3/F16, Task 4/F17, Task 5/F18 lesson
F19-A10  [U]  InMemoryShoppingRepository never imports or constructs a Firestore client — guest mode makes zero network calls, structurally (same guarantee style as F14-A14/F15-A08/F16-A16/F17-A10/F18-A10)
F19-A11  [I]  lib/app.dart: with uid == null, ShoppingCubit is constructed with InMemoryShoppingRepository; with uid == 'uid-1', it is constructed with FirestoreShoppingRepository — object type differs across the F14 sign-in/out transition, driven through a real StyloBuddyApp pumped via the uidStream/firestoreOverride harness with a bounded-polling wait (never a bare pumpAndSettle() per the Task 2 known gotcha), never a hand-built Cubit, per the Task 2/3/4/5 lesson that a hand-built-Cubit-only test let app.dart's own ternary go unverified
F19-A12  [I]  ShoppingCubit.toggleWishlist, when the repository call is in flight, has already optimistically updated state before the Future resolves (optimistic-then-reconcile, D6) — then, on a simulated repository failure, rolls back ONLY wishlist to its pre-toggle value, evaluated against the Cubit's current state at failure time, rather than leaving the optimistic value in place
F19-A13  [I]  Two interleaved calls — toggleWishlist(id) that will fail, and setTab('closet')/select(otherId) issued before the first resolves — where only toggleWishlist fails: the targeted rollback (A12) reverts wishlist only — tab/selectedId's independently-applied, concurrently-succeeding change survives untouched (confound-free test proving the revert is field-scoped, not whole-ShoppingState, matching F17/F18's own review-round fix)
F19-A14  [U]  Any toggleWishlist call inside ShoppingCubit/FirestoreShoppingRepository that is not directly awaited at its call site (fire-and-forget) has a .catchError (or equivalent) attached — a test asserts no unhandled rejection/uncaught Future error surfaces for a write allowed to fail in the background; if no such unawaited call exists in the final implementation, this assertion is satisfied vacuously and the implementer notes that in the completion block rather than skipping the test
F19-A15  [U]  FirestoreShoppingRepository.watchWishlist()'s stream subscription inside ShoppingCubit has an onError handler attached — a test asserts a simulated stream error does not crash the Cubit or surface as an unhandled zone error
F19-A16  [I]  Sign-out then sign-in-again (same or different uid) leaves no stale wishlist bleed-through: signing out renders InMemoryShoppingRepository's default empty wishlist (not the previous signed-in user's saved items), and signing in as a different uid shows only that uid's own Firestore document's wishlist, never the prior uid's cached values (F14 Review Focus item 2, re-verified at this feature's layer)
F19-A17  [U]  watchWishlist() treats a Firestore document with an entirely missing wishlist field (e.g. a doc written before F18's wishlist-seeding existed) as an empty list — constructed directly against the fake (not through any current bootstrap call site) and distinguished in test code from an explicitly-present wishlist: [] (the normal just-bootstrapped case) by exercising two different code paths even though both yield []
F19-A18  [U]  A toggleWishlist call against a document whose wishlist field is explicitly present and non-empty (e.g. ['item-3']) correctly adds/removes relative to that real array, never silently treating a present-but-nonempty field as if it were missing/defaulted
F19-A19  [L]  Against the live Firestore project (stylobuddy-b7e46), a real test user's sign-up -> toggle two wishlist items -> edit a Profile field -> sign-out -> sign-in-again sequence round-trips correctly: both the wishlist and the Profile edit are visible together after killing and relaunching the app — deferred to the live-verification pass, documented in the task report rather than a CI-run test
```

## 12. Edge cases

- `toggleWishlist` called twice in immediate succession for the same id
  before the first write's `Future` resolves: the second call's optimistic
  update simply overwrites the first in `ShoppingCubit.state` (last-caller-
  wins, matching today's single-threaded in-memory behavior), and the
  second Firestore write's read-then-write may race the first's — this
  task does not add de-duplication or a transaction to close that race,
  inherited risk, not newly introduced (same shape as F16 §12/F17 §12/F18
  §12's equivalent notes; a double-tap flicker is an acceptable, pre-
  existing-class risk, not a new one this document is obligated to close).
- An id toggled that does not exist in `ShoppingCatalog` (a stale saved id
  from a catalog entry later removed from the bundled constant): the
  repository still stores/removes the raw string — `ShoppingCatalog` is
  not consulted by the repository layer at all, matching the existing
  `ShopEntry` detail screen's own stance (§2's `pair` doc comment: "ids
  missing from the current wardrobe are omitted at render time, not shown
  as placeholders" — same render-time-filtering principle, not a
  repository-level validation this task adds).
- A user with a very large wishlist (bounded in practice by the five-entry
  `ShoppingCatalog`, so at most 5 ids ever): no pagination/size-limit
  logic added — the field is small by construction, same reasoning schema
  doc §1 gives for choosing an array field over a subcollection.
- Profile's `bootstrapIfNeeded` (F18) running for a uid for the first time
  after this task ships, where that uid's document already has a
  non-bootstrap `wishlist` value (impossible in the normal flow since
  `wishlist` only gets written post-bootstrap by this task's own
  repository, which itself only runs once `seeded` is true — but checked
  anyway per F18's own Important #5 "only seed keys genuinely absent"
  guard): F18's `extraFields` callback already skips any key present in
  the transaction's own read, so a pre-existing `wishlist` value (however
  it got there) is never overwritten by a later/duplicate bootstrap
  attempt — re-verified here, not re-implemented (§11 A17 is the closest
  test; no new assertion needed since F18's guard already covers this by
  construction).

## 13. Open questions

- **Whether `toggleWishlist`'s read-then-write shape needs `runTransaction`
  is this document's call, decided no, not a re-derivation of an unstated
  plan decision.** The plan brief only says "toggling wishlist membership
  persists" without specifying the write mechanism. This document decides
  a plain read-then-targeted-write (no transaction) is correct, for the
  same reason `ProfileCubit.togglePreference`'s Cubit-side list computation
  needs none in F18: a double-tap race is accepted, pre-existing-class
  risk (§12), not a correctness requirement this feature must close. A
  reviewer who disagrees should amend §6/§11 A01-A03, not silently add a
  transaction during implementation.
- **Whether `watchWishlist()` should be a `Stream<List<String>>` (this
  document's choice) or a `Stream<ShoppingState>`-shaped wrapper matching
  `ProfileRepository.watchProfile()`'s full-state-stream shape is flagged,
  not left ambiguous: this document picks `Stream<List<String>>`** because
  `ShoppingRepository`'s only persisted field is `wishlist` itself —
  returning a full `ShoppingState` would require the repository to also
  own `tab`/`selectedId`, which schema doc §7 explicitly excludes from any
  repository. A reviewer who finds this inconsistent with
  `ProfileRepository`'s shape should raise it against this document's
  §6, not reinterpret silently.
- **Pre-existing cross-field clobber risk on `users/{uid}` outside this
  task's scope, checked and found absent**: reading
  `firestore_profile_repository.dart`'s every write method (`updateDetails`,
  every `set*`) confirms each one calls `_doc.set(fields, SetOptions(merge:
  true))` with only its own changed field(s) in `fields` — never a
  whole-document `set()` without `merge: true` and never a payload
  containing more keys than the one(s) that setter changed. This means
  Profile's existing write methods do **not** pose a latent clobber risk
  against a concurrent `wishlist` write (or vice versa) — Firestore's
  merge-set semantics on two disjoint-key payloads are safe by
  construction, confirmed rather than assumed, and §11 A05/A06 test this
  directly rather than relying on this read-through alone. This document
  found no fix required in Profile's existing code as a prerequisite for
  Task 6 — the non-clobber requirement is satisfied by this task's own
  `FirestoreShoppingRepository` also always writing a single-key, merge-true
  payload (§6), not by any change to F18's code.
- **This document carries forward F17/F18 §13's observation style**: the
  no-`runTransaction`, single-key-merge-write design (§6, A07) is a
  *settled* decision here, not an open question — named explicitly only so
  a reviewer comparing this task to F16's read-modify-write precedent or
  F18's "no transaction needed because the Cubit precomputes" framing does
  not mistake either absence for an oversight.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: DONE (pending [L] live-verification pass)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 18/19 PASS (A01-A18); A19 [L] deferred to live-verification pass
Regression: flutter test (full suite) green; flutter analyze clean
```
