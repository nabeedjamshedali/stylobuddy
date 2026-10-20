# F17 — Calendar / Planner Backend

> Gives a signed-in user real Firestore persistence for their planned-outfit
> calendar, swapping `PlannerCubit`'s direct in-memory `Map<String,
> PlannedEntry>` mutation for the dual-mode repository pattern
> (`InMemoryPlannerRepository` / `FirestorePlannerRepository` behind one
> interface) — Task 4 of `docs/superpowers/plans/2026-10-19-backend-wiring.md`.
> Zero widget redesign, zero change to guest ("Skip for now") planner
> behavior. Depends on F14 (`uidChanges()`, `FirestoreService`, the
> auth-gated `StreamBuilder` in `lib/app.dart`). Grounded in
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D2, D4, D6)
> and `docs/superpowers/specs/2026-10-19-firestore-schema.md` §5 and §7.

**Status:** DONE (Gates 1-3 closed; Gate 4 — A19 `[L]` live device run — pending) · **Milestone:** 2 · **Depends on:** F14

---

## 1. Goal

Let a signed-in user's planned-outfit calendar — entries scheduled from the
calendar screens, the Stylist's "schedule this look," and the Saved detail
view's "plan a wear" — survive a cold restart and a different device, by
writing each date's plan to `users/{uid}/plannedEntries/{dateKey}` instead
of holding it only in `PlannerCubit`'s in-memory `planned` map. A guest gets
none of this and sees exactly what the current `flutter test` suite already
verifies — no network call, no new failure mode, the same
`SeedData.planned` seed every launch.

## 2. MVP scope

- New folder `lib/features/calendar/repository/`:
  - `planner_repository.dart`: an **abstract** `PlannerRepository`
    interface. Its methods mirror the write/read operations `PlannerCubit`
    already performs directly on its own state today — `plan`, `remove` —
    plus a `watchPlanned()` stream read per architecture D6. `PlannerCubit`'s
    other public methods (`select`, `selectDate`, `navigate`,
    `startScheduling`, `clearEditing`, `label`, `keyFor`) are pure
    transformations of transient, non-persisted state (schema doc §7:
    `PlannerState.{year,month,day,editingOutfitId,editingOccasion}`) and are
    **not** part of the repository interface — see §6 and §13.
  - `in_memory_planner_repository.dart`: today's `SeedData.planned` behavior
    moved behind the interface verbatim — same seed map, same
    synchronous-feeling writes (`SynchronousFuture`, per the Task 2/F15 and
    Task 3/F16 review lesson — not `async`, so guest-mode write timing stays
    byte-identical to today), no network call ever constructed on this
    branch. Used for guests, unchanged from today's `PlannerCubit`-held
    logic.
  - `firestore_planner_repository.dart`: real reads/writes under
    `users/{uid}/plannedEntries/{dateKey}` (schema doc §5) — the Firestore
    document ID **is** the `'yyyy-MM-dd'` key string itself, verbatim, with
    no separate `date` field and no duplicated `id` field on the document
    (schema doc §5 explicitly departs from the `id`-duplication convention
    used for `wardrobeItems`/`outfits`/`wearEvents` — there is no int `id`
    anywhere in this collection; see §13). `watchPlanned()` wraps
    `plannedEntries.snapshots()` and maps each document to a `MapEntry<String,
    PlannedEntry>` keyed by `doc.id`. `plan`/`remove` are plain `set()`/
    `delete()` calls, **not** `runTransaction` — unlike F16's `logWear`/
    `removeWear`, neither operation reads a prior value to compute a new one
    (`plan` fully overwrites a date's entry with the caller-supplied
    `PlannedEntry`; `remove` deletes unconditionally), so the Task 2/F15 and
    Task 3/F16 "read-modify-write must use `runTransaction`" lesson does not
    apply here — flagged explicitly so a reviewer does not assume a missing
    transaction is an oversight (see §13).
  - **Binding requirements carried forward from Tasks 2/3's review rounds,
    applied from day one, not as a second-round fix:**
    1. Every fire-and-forget write (if any end up unawaited at their
       `PlannerCubit` call site for UI-responsiveness) gets a `.catchError`
       attached.
    2. Every `watchPlanned()` stream subscription inside `PlannerCubit` has
       an `onError` handler — never an unhandled stream error.
    3. If `plan`/`remove`'s repository `Future` fails after `PlannerCubit`
       has already optimistically updated `state.planned`, the Cubit rolls
       back to the pre-call map, not just logs and leaves the optimistic
       state wrong (D6 "reconcile on failure", F16 §13's precedent).
- `lib/app.dart`: `PlannerCubit`'s construction (currently
  `PlannerCubit()` with no arguments, line ~163) becomes dual-mode under
  Task 1's `StreamBuilder` — in-memory for `uid == null`, Firestore for
  `uid != null` — following the same pattern F15/F16 established.
- `PlannerCubit`'s own public method names/signatures are unchanged in shape
  (`select`, `selectDate`, `navigate`, `plan`, `remove`, `startScheduling`,
  `clearEditing`, `label`, `keyFor`, `selectedKey`); only what is behind
  `plan`/`remove` changes from direct state mutation to "await the
  repository Future, then optimistically update local state" (architecture
  D6).

## 3. Later scope

- Any change to `Outfit`/`WearEvent` persistence (F16) — `PlannedEntry
  .outfitId` continues to simply reference an `Outfit.id` that may or may
  not still exist; this task does not add a lookup, a foreign-key check, or
  cleanup when the referenced outfit is deleted (`03-domain-model.md`:
  "Deleting an `Outfit` keeps ... any `PlannedEntry`; readers must tolerate
  the missing outfit" — unchanged, re-affirmed below in §10).
- Persisting any of `PlannerState`'s transient fields
  (`year`/`month`/`day`/`editingOutfitId`/`editingOccasion`) — explicitly
  excluded by schema doc §7; this task does not add a repository method or
  collection for them, in either guest or signed-in mode.
- Firestore security rules for `plannedEntries` (Task 9).
- Any change to the cross-feature calls into `PlannerCubit.startScheduling`
  from `lib/features/stylist/view/result_detail_view.dart` and
  `lib/features/saved/view/saved_detail_view.dart` — both continue to call
  `startScheduling`/`clearEditing` exactly as they do today; this task does
  not touch either file (no widget changes, per the plan's Global
  Constraints).

## 4. Roles and permissions

Reuses `docs/foundation/07-security.md`'s guest/authenticated roles, made
concrete the same way F15/F16 made it structural: `uid == null` ->
`InMemoryPlannerRepository`, zero Firestore calls, ever; `uid != null` ->
`FirestorePlannerRepository`, scoped to that `uid`'s own subtree via
`FirestoreService.subcollection` (F14-A11 — paths are always
`users/<uid>/plannedEntries`, never a cross-user or top-level path). No new
permission surface beyond that isolation guarantee is introduced this task.

## 5. Main flows

```text
Guest plans/removes a calendar entry (no Firebase user):
  Calendar screens ("plan this outfit" / "remove plan") or Stylist/Saved's
     "schedule this look" -> PlannerCubit.plan or .remove ->
     InMemoryPlannerRepository resolves immediately (SynchronousFuture) ->
     PlannerCubit optimistically updates state.planned
  (identical to today's existing flow; no network call constructed)

Signed-in user plans a new (or overwritten) entry:
  Calendar screens / Stylist / Saved -> PlannerCubit.plan(key, entry) ->
     FirestorePlannerRepository.plan writes/overwrites
     plannedEntries/{key} with {outfitId, occasion} -> Future resolves ->
     PlannerCubit optimistically updates state.planned[key] -> the live
     watchPlanned() snapshot later reconciles the same document

Signed-in user removes an entry:
  Calendar screens -> PlannerCubit.remove(key) ->
     FirestorePlannerRepository.remove deletes plannedEntries/{key} ->
     Future resolves -> PlannerCubit removes key from state.planned ->
     watchPlanned() later reconciles (the document is simply absent)

Signed-in user removes a key that has no document (already removed on
another device, or never existed):
  FirestorePlannerRepository.remove's delete() against a missing document
     is a no-op per Firestore's own semantics (no error) -> Future resolves
     -> PlannerCubit's optimistic Map.remove on a missing key is also a
     no-op -> both layers agree, no crash, no divergence

Sign-out then sign-in-again as a different (or the same) user:
  F14's auth-gated reconstruction (D3) tears down PlannerCubit entirely on
     the uid-keyed StreamBuilder rebuild -> no FirestorePlannerRepository
     stream subscription survives the transition -> the newly-constructed
     PlannerCubit for the new uid (or guest) starts from that uid's own
     watchPlanned() first emission (or the in-memory seed, for a sign-out)
     -> no planned-entry data from the previous session is ever visible in
     the new one, re-verifying Review Focus item 2 at this feature's own
     layer

An outfit referenced by a PlannedEntry.outfitId is deleted (F16, unrelated
Cubit) while a plan for it still exists:
  watchPlanned() continues to emit the PlannedEntry unchanged (this task
     adds no cascade/cleanup) -> the calendar screens' existing
     "tolerate a missing outfit" rendering path (pre-existing, per
     03-domain-model.md) is exercised exactly as it is today for guests
```

## 6. Interface surface

```text
abstract class PlannerRepository
  Stream<Map<String, PlannedEntry>> watchPlanned()        both impls
  Future<void> plan(String key, PlannedEntry entry)        both impls
  Future<void> remove(String key)                          both impls

class InMemoryPlannerRepository implements PlannerRepository    guest mode
class FirestorePlannerRepository implements PlannerRepository   signed-in mode
```

`PlannerCubit`'s public surface (`select`, `selectDate`, `navigate`, `plan`,
`remove`, `startScheduling`, `clearEditing`, `label`, `keyFor`,
`selectedKey`) is unchanged in shape. `select`, `selectDate`, `navigate`,
`startScheduling`, `clearEditing`, `label`, and `keyFor` are pure
synchronous transformations of `PlannerCubit.state`'s transient fields
(`year`, `month`, `day`, `editingOutfitId`, `editingOccasion`) or pure
string formatting — none of them call the repository, and none of them are
part of the `PlannerRepository` interface, per schema doc §7's explicit
exclusion list. Only `plan` and `remove` cross into the repository.
`PlannerCubit`'s constructor gains an optional `PlannerRepository`
parameter (named, defaulting to `InMemoryPlannerRepository()`, matching
F16's resolved constructor-parameter precedent so no existing
`PlannerCubit()` call site in a pre-existing test needs editing).

## 7. Domain model usage

`PlannedEntry` (`outfitId`, `occasion`) is read/written unchanged — no new
fields, no type change (`outfitId` stays `int` per architecture D4; there is
no `PlannedEntry.id` field to begin with, so D4's "doc ID reuses an existing
in-app id" is satisfied here by the `'yyyy-MM-dd'` map key rather than by an
`int`/`String` model field — see §13). No change to
`docs/foundation/03-domain-model.md` is needed this task.

## 8. Data changes

- Firestore: `users/{uid}/plannedEntries/{dateKey}` collection, fields per
  schema doc §5 (`outfitId`: int, `occasion`: string). Document ID is the
  `'yyyy-MM-dd'` key itself — no separate `date` field, no duplicated `id`
  field (schema doc §5 states this explicitly; this collection is the one
  exception to the §2-4 "duplicate id on doc" convention). No
  `firestore.rules` change this task (Task 9 owns that file; today's
  `users/{uid}/{document=**}` owner-only default-deny already covers this
  path at the auth-isolation level).
- No migration: the collection does not exist yet for any real user (this
  is the task that first creates it); no backfill needed.

## 9. Background work and events

- No Cloud Function, no scheduled job, no retry/queue logic triggered by
  this task — `plan`/`remove` are one-shot `set()`/`delete()` calls.
- `watchPlanned()`'s Firestore `snapshots()` listener is long-lived for the
  life of the signed-in `PlannerCubit` instance; it is torn down (per F14
  D3) on every sign-out/sign-in transition along with the rest of the
  subtree, never left subscribed past the Cubit's `close()`.

## 10. Degradation and failure

- Guest mode (`InMemoryPlannerRepository`) makes zero Firestore calls —
  structurally, not "falls back after a failed call," the same guarantee
  F14/F15/F16 established for other repositories.
- `FirestorePlannerRepository.watchPlanned()` losing network connection
  mid-session: Firestore's SDK-level offline cache/reconnect behavior
  applies (not added or suppressed by this task), matching F15/F16's same
  stance.
- `remove(key)` called against a `key` with no existing document (already
  removed elsewhere, or never existed): a silent no-op, never a thrown
  error — both the Firestore `delete()` and the in-memory `Map.remove`
  agree on this (§5).
- `plan(key, entry)` called against a `key` that already has an entry:
  the existing entry is fully overwritten by the new one (no merge, no
  partial update) — matches `PlannerCubit.plan`'s existing
  `{...state.planned, key: entry}` semantics exactly.
- A `PlannedEntry.outfitId` whose `Outfit` has since been deleted (F16,
  cross-feature, unrelated to this task): `watchPlanned()` still emits the
  `PlannedEntry` unchanged — this task adds no validation, cascade, or
  cleanup against `OutfitsRepository`; the calendar UI's existing
  "tolerate a missing outfit" behavior (pre-existing per
  `03-domain-model.md`) is unaffected and unchanged.
- A signed-in user with no planned entries at all (`watchPlanned()`'s first
  emission is an empty map): this is a valid, distinct state from "a date
  key exists but its `PlannedEntry.occasion` happens to be an empty
  string" — `state.planned[key]` being `null` (missing key entirely) must
  never be confused with a present `PlannedEntry` whose `occasion` field is
  `''` (empty); the calendar screens' existing missing-vs-present branch
  (`state.planned[selectedKey] == null` vs. not) is the only thing this
  task's repository swap must not disturb.

## 11. Validation assertions

```
F17-A01  [U]  FirestorePlannerRepository.plan, given a key with no existing document, writes a new plannedEntries/{key} document whose Firestore document ID equals the key verbatim ('yyyy-MM-dd' string) and watchPlanned()'s next emission includes it with outfitId/occasion round-tripped unchanged
F17-A02  [U]  FirestorePlannerRepository.plan, given a key with an existing document, fully overwrites outfitId and occasion with the new entry's values — no field from the old entry survives, matching {...state.planned, key: entry}'s overwrite semantics exactly
F17-A03  [U]  FirestorePlannerRepository's document never carries a separate 'id' or 'date' field — only outfitId and occasion are written, confirmed by reading the raw document data back and asserting its key set equals exactly {'outfitId', 'occasion'}
F17-A04  [U]  FirestorePlannerRepository.remove deletes exactly the target plannedEntries document; watchPlanned()'s next emission no longer includes that key, and every other key is unaffected
F17-A05  [U]  FirestorePlannerRepository.remove called against a key with no existing document resolves without throwing and performs no write (a verified no-op, not a crash)
F17-A06  [U]  FirestorePlannerRepository.plan and .remove are each implemented without runTransaction — a test double records every call made to the fake and asserts no transaction API is invoked by either method, documenting that this collection's writes are intentionally not read-modify-write (distinct from F16's logWear/removeWear)
F17-A07  [U]  FirestorePlannerRepository.watchPlanned() emits a Map<String, PlannedEntry> keyed by each document's own Firestore doc ID (not a field inside the document) — verified with at least two documents whose IDs differ from any field value coincidentally present
F17-A08  [U]  InMemoryPlannerRepository's watchPlanned()/plan()/remove() behavior is unchanged from today's PlannerCubit-held logic — the full pre-existing PlannerCubit test suite (test/features/calendar/planner_cubit_test.dart) passes unmodified against PlannerCubit constructed with InMemoryPlannerRepository, with zero existing assertion edited to accommodate this task
F17-A09  [U]  InMemoryPlannerRepository.plan/remove return a SynchronousFuture (or equivalent already-completed Future), not an async-declared method, verified by asserting the Future is already complete in the same microtask the call returns, before any pump/await — matching the Task 2/F15 and Task 3/F16 lesson that avoided flush-point workarounds
F17-A10  [U]  InMemoryPlannerRepository never imports or constructs a Firestore client — guest mode makes zero network calls, structurally (same guarantee style as F14-A14/F15-A08/F16-A16)
F17-A11  [I]  lib/app.dart: with uid == null, PlannerCubit is constructed with InMemoryPlannerRepository; with uid == 'uid-1', it is constructed with FirestorePlannerRepository — object type differs across the F14 sign-in/out transition, driven through a real StyloBuddyApp pumped via the uidStream/firestoreOverride harness (not a hand-built Cubit), per the Task 2/F15 and Task 3/F16 lesson that a hand-built-Cubit-only test let app.dart's own ternary go unverified
F17-A12  [I]  A full sign-in -> plan an entry -> sign-out -> sign-in-again cycle (F14's reconstruction pattern) leaves the newly-constructed PlannerCubit's state showing only that uid's own Firestore plannedEntries on re-sign-in, and the in-memory seed data (not the signed-in user's plans, and not an empty map either — the actual seed) on sign-out — no bleed-through in either direction (Review Focus item 2, re-verified at this feature's layer)
F17-A13  [I]  PlannerCubit.plan, when the repository call is in flight, has already optimistically updated state.planned before the Future resolves (optimistic-then-reconcile, D6) — then, on a simulated repository failure, rolls state.planned back to its pre-call value rather than leaving the optimistic entry in place
F17-A14  [I]  PlannerCubit.remove, when the repository call is in flight, has already optimistically removed the key from state.planned before the Future resolves — then, on a simulated repository failure, restores the removed entry rather than leaving state.planned permanently missing it
F17-A15  [U]  Any write call inside PlannerCubit/FirestorePlannerRepository that is not directly awaited at its call site (fire-and-forget) has a .catchError (or equivalent) attached — a test asserts no unhandled rejection/uncaught Future error surfaces for a write allowed to fail in the background; if no such unawaited call exists in the final implementation, this assertion is satisfied vacuously and the implementer notes that in the completion block rather than skipping the test
F17-A16  [U]  FirestorePlannerRepository.watchPlanned()'s stream subscription inside PlannerCubit has an onError handler attached — a test asserts a simulated stream error does not crash the Cubit or surface as an unhandled zone error
F17-A17  [U]  state.planned[key] being null (missing — no entry for that date) is distinct from a present PlannedEntry whose occasion is '' (empty string) — both are constructible via the repository round-trip and PlannerCubit.label/the calendar screens' missing-vs-present branch treats them differently (missing renders the empty-card state; present-with-empty-occasion renders a plan card with a blank occasion, never crashing or silently treating the two as the same case)
F17-A18  [U]  PlannerCubit.startScheduling/.clearEditing/.select/.selectDate/.navigate never call any PlannerRepository method — a test double that fails the test if any repository method is invoked is used to drive all five calls, confirming the transient-field exclusion in schema doc §7 is respected structurally, not just by convention
F17-A19  [L]  Against the live Firestore project (stylobuddy-b7e46), a real signed-in test user's plan-an-entry -> remove-it sequence round-trips correctly and is visible after killing and relaunching the app — deferred to the live-verification pass, documented in the task report rather than a CI-run test
```

## 12. Edge cases

- `plan` called twice in immediate succession for the same key before the
  first write's Future resolves: the second call's optimistic update
  simply overwrites the first in `PlannerCubit.state` (last-caller-wins,
  matching today's single-threaded in-memory behavior) and the second
  Firestore write similarly overwrites the first document — no
  de-duplication is added by this task, inherited risk, not newly
  introduced (same as F16 §12's equivalent note for `saveOrFind`).
- `navigate`'s month-length clamp (`state.day > length ? length : state.day`)
  runs entirely over transient state and is unaffected by this task; it
  continues to never touch the repository (F17-A18).
- A `PlannedEntry.outfitId` that never existed at all (not deleted, simply
  invalid — defensive case, not expected from any current call site):
  `watchPlanned()` emits it exactly as read; this task performs no
  validation against `OutfitsRepository`, consistent with §10's documented
  "tolerate a missing outfit" stance.
- `remove` on the only remaining planned entry: `watchPlanned()`'s next
  emission is an empty map — a valid, distinct state from "never had any
  entries," though this task does not and cannot distinguish the two
  (Firestore has no way to tell "empty collection, never written" from
  "empty collection, everything removed," and neither does today's
  in-memory `Map`) — not a new gap, the same shape as today.

## 13. Open questions

- **This collection is the one exception to the schema doc's "duplicate id
  on doc" convention (§2-4), and this document treats that as settled, not
  open** — flagged here only so a reviewer checking for symmetry with
  F15/F16 does not mistake the absence of an `id` field as an oversight.
  Schema doc §5 states explicitly: "Doc ID is the `'yyyy-MM-dd'` key itself
  — no separate `date` field needed." `PlannedEntry` itself also has no
  `id` field at the model layer (`outfitId`, `occasion` only), so there is
  no int/string id to duplicate in the first place. No action needed; this
  is an observation, not a decision left to the implementer.
- **Whether `FirestorePlannerRepository.plan`'s "fully overwrite" semantics
  should instead be a merge (`set(..., SetOptions(merge: true))`).** This
  document specifies a full overwrite (§10, F17-A02) to match
  `PlannerCubit.plan`'s existing `{...state.planned, key: entry}` behavior,
  which itself always replaces the whole `PlannedEntry` value for a key
  (the model has no optional/nullable fields a partial update could
  usefully preserve — both `outfitId` and `occasion` are required on
  `PlannedEntry`). This is not actually an open question in practice (there
  is nothing a merge would preserve that an overwrite wouldn't), but is
  named explicitly because F16 §13 had a real merge-vs-overwrite decision
  for `upsertManual` and a reviewer comparing the two tasks should not have
  to re-derive why this one doesn't need the same resolution-and-dated-note
  treatment.
- **Whether a future task should validate `PlannedEntry.outfitId` against
  `OutfitsRepository` at write time** (reject/warn on scheduling an outfit
  id that doesn't exist) is not decided here — out of scope per §3, and the
  current client-side call sites (`startScheduling`) already only ever
  pass an `outfitId` the Cubit just resolved via `OutfitsCubit.byId`, so the
  practical risk is low; flagged for a later task only if it surfaces as a
  real user-facing bug (stale plan pointing at a deleted outfit across
  devices).

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: BUILT (gates 1-3 complete; gate 4 deferred to live-verification pass)

[x] Gate 1  Interface documented — `lib/features/calendar/repository/planner_repository.dart`
[x] Gate 2  Unit — repository + in-memory tests (A01-A10)
[x] Gate 3  Integration — Cubit dual-mode/rollback/error-handling/transient-field
    tests (A11-A18) + real-app.dart `uidStream`/`firestoreOverride` harness
    tests (A11, A12)
[ ] Gate 4  Live run — A19 ([L]) deferred to the live-verification pass
    against the real Firestore project, not run in this task

Assertions: 18/19 PASS (A01-A18 implemented and tested; A19 [L] pending
live verification)
Regression: full `flutter test` suite green (0 pre-existing test edited;
`flutter analyze` clean)

Note on F17-A15: PlannerCubit's `plan`/`remove` are both fire-and-forget at
their own call sites, so this assertion is exercised non-vacuously (not the
vacuous-satisfaction fallback the assertion text allows for).
```
