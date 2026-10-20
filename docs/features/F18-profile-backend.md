# F18 — Profile Backend + Onboarding Handoff Fix

> Gives a signed-in user real Firestore persistence for their `ProfileState`
> (`users/{uid}`, schema doc §1), swapping `ProfileCubit`'s direct in-memory
> field mutation for the dual-mode repository pattern
> (`InMemoryProfileRepository` / `FirestoreProfileRepository` behind one
> interface) — Task 5 of `docs/superpowers/plans/2026-10-19-backend-wiring.md`.
> Also closes a real, verified gap: `OnboardingCubit`'s `chosenOccasions`
> (intro slide 4) and `chosenChips` ("Occasions you dress for" on
> `/personalize`) are toggled in onboarding but today never reach
> `ProfileState` — a new signed-up user's profile shows only the hardcoded
> defaults, never what they picked. Zero widget redesign, zero change to
> guest ("Skip for now") profile behavior. Depends on F14
> (`uidChanges()`, `FirestoreService`, the auth-gated `StreamBuilder` in
> `lib/app.dart`) and reaffirms F14's existing `runBootstrapIfNeeded`
> transaction mechanism (Task 1) rather than replacing it. Grounded in
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D2, D5, D6)
> and `docs/superpowers/specs/2026-10-19-firestore-schema.md` §1.

**Status:** DONE (Gates 1-3 closed; Gate 4 — A20 `[L]` live device run — pending) · **Milestone:** 2 · **Depends on:** F14

---

## 1. Goal

Let a signed-in user's profile — name, email, chosen styles/occasions,
notification toggles, weather consent, climate, plan, billing cycle — survive
a cold restart and a different device, by writing it to `users/{uid}`
(schema doc §1) instead of holding it only in `ProfileCubit`'s in-memory
`ProfileState`. At the same time, fix the inventory-flagged gap so that a
new user's first bootstrap-seeded profile actually reflects what they chose
during onboarding (`chosenOccasions`/`chosenChips`), not just
`ProfileState()`'s hardcoded defaults. A guest gets none of the Firestore
part and sees exactly what the current `flutter test` suite already
verifies for `ProfileCubit` — no network call, no new failure mode.

## 2. MVP scope

- New folder `lib/features/profile/repository/`:
  - `profile_repository.dart`: an **abstract** `ProfileRepository`
    interface. Its methods mirror the write operations `ProfileCubit`
    already performs directly on its own state today, one per setter —
    `updateDetails(name, email)`, `setStyles(styles)`,
    `setOccasions(occasions)`, `setDailyNotifications(v)`,
    `setPlannedNotifications(v)`, `setProductNotifications(v)`,
    `setWeatherConsent(v)`, `setClimate(v)`, `setPlan(v)`,
    `setBillingCycle(v)` — plus `watchProfile()` per architecture D6.
    `ProfileCubit.togglePreference` stays a pure Cubit-local computation of
    the *next* list (exactly as it already is: `current.contains(value) ?
    current.where(...).toList() : [...current, value]`), then calls
    `setStyles`/`setOccasions` with that already-computed list — so the
    repository method itself is always a plain overwrite of one field,
    never a repository-side read-modify-write (see §6, §10, §13 for why
    this means no method here needs `runTransaction`, unlike F16's
    `logWear`/`removeWear`).
  - `in_memory_profile_repository.dart`: today's `ProfileState()`-default
    behavior moved behind the interface verbatim — same defaults, same
    synchronous-feeling writes (`SynchronousFuture`, per the Task 2/F15,
    Task 3/F16, Task 4/F17 review lesson — not `async`), no network call
    ever constructed on this branch. Used for guests, unchanged from
    today's `ProfileCubit`-held logic.
  - `firestore_profile_repository.dart`: real reads/writes of
    `users/{uid}` (schema doc §1) — `watchProfile()` wraps
    `userDoc(uid).snapshots()` and maps the document to a `ProfileState`,
    excluding the infra-only `seeded` field (already true per F14's doc
    comment) and the `wishlist` field (schema doc §1: `wishlist` lives on
    the same document but belongs to `ShoppingState`/Task 6, not
    `ProfileState` — see §13). Each `set*`/`updateDetails` method is a
    plain `set(doc, {field: value}, SetOptions(merge: true))` call, **not**
    `runTransaction` — the Cubit always hands the repository the final
    value to write, so there is nothing left to read-then-modify at the
    repository layer (see §6).
  - **Binding requirements carried forward from Tasks 2–4's review rounds,
    applied from day one, not as a second-round fix:**
    1. Every fire-and-forget write (if any end up unawaited at their
       `ProfileCubit` call site) gets a `.catchError` attached.
    2. `ProfileCubit`'s `watchProfile()` stream subscription has an
       `onError` handler — never an unhandled stream error.
    3. If a `set*`/`updateDetails` repository `Future` fails after
       `ProfileCubit` has already optimistically updated `state`, the
       Cubit rolls back — **targeted to only the field(s) that failed**,
       evaluated against the Cubit's *current* state at failure time, never
       a whole-`ProfileState` snapshot captured before the call (D6
       "reconcile on failure"; this is Task 4/F17's own review-round fix,
       baked in here from the start rather than repeated as a fix round —
       see §13).
- **Onboarding handoff fix** (the inventory gap, confirmed real by reading
  the code — see this document's own research, not just the plan's say-so,
  recorded in §13): `OnboardingCubit.toggleOccasion`/`toggleChip` currently
  only mutate `OnboardingState`, which is scoped to the onboarding
  `ShellRoute` (`lib/features/onboarding/onboarding_routes.dart`) and is
  torn down the moment navigation leaves that shell (e.g. `/personalize`'s
  "Continue →" button pushes `AppRoutes.auth`, a *different* `ShellRoute*
  with its own, unrelated `AuthCubit`). `AuthCubit.signInWithGoogle()`
  (`lib/features/auth/cubit/auth_cubit.dart`) today has no access to, and
  makes no call toward, `OnboardingCubit` or `ProfileRepository` — sign-in
  success just routes straight to `AppRoutes.home` from `auth_view.dart`
  (a widget file, frozen per the implementer contract's rulings). This
  task adds the minimum cubit-layer plumbing (no `view`/`widgets` file
  edited) so that whatever occasions the user toggled across both
  `chosenOccasions` and `chosenChips` are available to the D5 bootstrap
  seedWriter the first time that uid's profile is seeded — see §13 for why
  the exact mechanism (not the resulting behavior) is left to the
  implementer's judgment.
- `lib/app.dart`: `ProfileCubit`'s construction (currently
  `ProfileCubit()` with no arguments, line ~175) becomes dual-mode under
  Task 1's `StreamBuilder` — in-memory for `uid == null`, Firestore for
  `uid != null` — following the same pattern F15/F16/F17 established.
- `ProfileCubit`'s own public method names/signatures are unchanged in
  shape (`updateDetails`, `togglePreference`, `setDailyNotifications`,
  `setPlannedNotifications`, `setProductNotifications`,
  `setWeatherConsent`, `setClimate`, `setPlan`, `setBillingCycle`); only
  what is behind each from "direct `emit(state.copyWith(...))`" to "await
  the repository `Future`, then optimistically update local state"
  (architecture D6) changes.

## 3. Later scope

- `wishlist`'s actual read/toggle methods (Task 6) — this task only makes
  sure the D5 bootstrap write includes `wishlist: []` on the shared
  document; it adds no `ProfileRepository` method that reads or writes
  `wishlist` at any other time. Task 6 is the sole post-bootstrap writer of
  that field, against the same `users/{uid}` document, through its own
  narrow accessor — not through `ProfileRepository` (plan Task 6 brief's
  explicit "no duplicate write path" requirement; flagged again in §13).
- `personalizeStyles` (the `OptionTile` row on `/personalize`, "What feels
  most like you?") is **not** part of this fix. Reading
  `lib/features/onboarding/view/personalize_view.dart` confirms its
  `onTap` only calls `AppToast.show` — there is no `OnboardingCubit` method
  and no state field capturing which style tile is selected
  (`preselectedStyle` is a hardcoded constant, never toggled). There is
  nothing here to forward, and this task does not add a
  `chosenStyles`-shaped field to `OnboardingState` to invent one — out of
  scope, flagged rather than silently decided (§13).
- Firestore security rules for `users/{uid}` (Task 9).
- Supabase Storage / profile photo upload — `ProfileState` has no image
  field today; not added by this task.
- Any change to `AuthCubit`'s validation rules, error messages, or its
  demo-only email/password forms — this task only gives
  `AuthCubit.signInWithGoogle()`'s success path one additional effect
  (forwarding onboarding choices before/alongside navigating home), not a
  behavior change to anything it already does.

## 4. Roles and permissions

Reuses `docs/foundation/07-security.md`'s guest/authenticated roles, made
concrete the same way F15/F16/F17 made it structural: `uid == null` ->
`InMemoryProfileRepository`, zero Firestore calls, ever; `uid != null` ->
`FirestoreProfileRepository`, scoped to that `uid`'s own document via
`FirestoreService.userDoc` (F14-A11 — paths are always `users/<uid>`, never
a cross-user or top-level path). No new permission surface beyond that
isolation guarantee is introduced this task.

## 5. Main flows

```text
Guest edits their profile (no Firebase user):
  Profile screens (edit details / toggle style or occasion / notification
     toggles / weather consent / climate / plan / billing) ->
     ProfileCubit.<setter> -> InMemoryProfileRepository resolves
     immediately (SynchronousFuture) -> ProfileCubit optimistically
     updates state
  (identical to today's existing flow; no network call constructed)

Signed-in user edits a field:
  Profile screens -> ProfileCubit.<setter>(nextValue) ->
     FirestoreProfileRepository.<setter> merge-sets that one field on
     users/{uid} -> Future resolves -> ProfileCubit optimistically updates
     state -> the live watchProfile() snapshot later reconciles the same
     document

A brand-new user signs up via Google (first-ever sign-in for that uid):
  FirestoreService.runBootstrapIfNeeded(uid, seedWriter) (Task 1,
     unchanged mechanism) reads users/{uid}.seeded -> false/missing ->
     FirestoreProfileRepository's seedWriter writes ProfileState()'s
     hardcoded defaults AS OVERRIDDEN by whatever occasions the user
     toggled during onboarding (see next flow), plus wishlist: [] ->
     tx.set(doc, {seeded: true}, merge: true) (Task 1's existing commit,
     not re-implemented) -> ProfileCubit's first watchProfile() emission
     shows the seeded, onboarding-aware profile

Onboarding handoff (the gap this task fixes):
  /intro slide 4 -> OnboardingCubit.toggleOccasion(name) and
     /personalize -> OnboardingCubit.toggleChip(name) each also record
     the toggle into a small app-lifetime-scoped holder that survives the
     onboarding ShellRoute's teardown (exact shape left to the
     implementer, see §13 — OnboardingState itself does not survive
     navigating to /auth's separate ShellRoute) -> user taps "Continue
     with Google" on /auth -> AuthCubit.signInWithGoogle() succeeds ->
     before/alongside routing to AppRoutes.home, the uid's first
     FirestoreProfileRepository bootstrap seedWriter reads that holder's
     accumulated occasions (chosenOccasions ∪ chosenChips, see §13 for the
     union decision) and writes them as ProfileState.occasions instead of
     the hardcoded default list -> the holder is cleared so it cannot leak
     into a later, unrelated sign-up in the same app process

A user toggles nothing during onboarding, then signs up:
  The holder is empty -> the bootstrap seedWriter falls back to
     ProfileState()'s hardcoded default occasions (['Everyday','Office'])
     -> never writes an empty occasions list just because the user made no
     selection (§10, §11 A07) — "didn't choose" is not "chose to clear
     everything"

A write's repository Future fails (simulated, e.g. offline):
  ProfileCubit has already optimistically applied the new value to
     state -> the Future rejects -> ProfileCubit reverts ONLY the field(s)
     that failed, read against its current state at the moment of
     failure -> any other field changed by a different, concurrently
     in-flight setter is left untouched (F17's targeted-revert lesson,
     applied here from the start)

Sign-out then sign-in-again as a different (or the same) user:
  F14's auth-gated reconstruction (D3) tears down ProfileCubit entirely on
     the uid-keyed StreamBuilder rebuild -> no FirestoreProfileRepository
     stream subscription survives the transition -> the newly-constructed
     ProfileCubit for the new uid (or guest) starts from that uid's own
     watchProfile() first emission (or ProfileState()'s defaults, for a
     sign-out) -> no profile data from the previous session is ever
     visible in the new one, re-verifying Review Focus item 2 at this
     feature's own layer
```

## 6. Interface surface

```text
abstract class ProfileRepository
  Stream<ProfileState> watchProfile()                      both impls
  Future<void> updateDetails(String name, String email)    both impls
  Future<void> setStyles(List<String> styles)               both impls
  Future<void> setOccasions(List<String> occasions)         both impls
  Future<void> setDailyNotifications(bool v)                both impls
  Future<void> setPlannedNotifications(bool v)               both impls
  Future<void> setProductNotifications(bool v)               both impls
  Future<void> setWeatherConsent(bool v)                     both impls
  Future<void> setClimate(String v)                          both impls
  Future<void> setPlan(String v)                              both impls
  Future<void> setBillingCycle(String v)                      both impls

class InMemoryProfileRepository implements ProfileRepository    guest mode
class FirestoreProfileRepository implements ProfileRepository   signed-in mode
```

`ProfileCubit`'s public surface (`updateDetails`, `togglePreference`,
`setDailyNotifications`, `setPlannedNotifications`,
`setProductNotifications`, `setWeatherConsent`, `setClimate`, `setPlan`,
`setBillingCycle`) is unchanged in shape. `togglePreference` keeps
computing the next `styles`/`occasions` list itself (as it already does)
and simply calls the matching repository setter with that final list —
this is why **no** `ProfileRepository` method needs `runTransaction`: the
read-then-modify step already happened in the Cubit before the repository
is ever called, unlike F16's `logWear`/`removeWear` which read a prior
numeric value *inside* the repository call. `ProfileCubit`'s constructor
gains an optional `ProfileRepository` parameter (named, defaulting to
`InMemoryProfileRepository()`, matching the F16/F17-resolved
constructor-parameter precedent so no existing `ProfileCubit()` call site
in a pre-existing test needs editing).

The onboarding-handoff mechanism (the holder described in §5/§13) is
**not** part of `ProfileRepository`'s interface — it is a small,
implementer-named piece that only `OnboardingCubit`'s toggle methods write
into and only `FirestoreProfileRepository`'s bootstrap seedWriter reads
from. Its exact class name/shape is left to the implementer; §11's
assertions (not this section) are the binding contract for its observable
behavior.

## 7. Domain model usage

`ProfileState` (`name`, `email`, `styles`, `occasions`,
`dailyNotifications`, `plannedNotifications`, `productNotifications`,
`weatherConsent`, `climate`, `plan`, `billingCycle`) is read/written
unchanged — no new field, no type change
(`docs/foundation/03-domain-model.md`'s `ProfileState` entry, including
its existing note that the Firestore document also carries an
infra-only `seeded: bool` the state itself excludes). `OnboardingState`'s
`chosenOccasions`/`chosenChips` (`Set<String>`) are read by the handoff
mechanism but are never themselves persisted as a field — only their
resulting effect on `ProfileState.occasions` is (schema doc §7: "its
*result* feeds the D5 bootstrap's profile seed ... not its own store" —
already decided there, this task implements it). No change to
`docs/foundation/03-domain-model.md` is needed this task.

## 8. Data changes

- Firestore: `users/{uid}` document, fields per schema doc §1 (`name`,
  `email`, `styles`, `occasions`, `dailyNotifications`,
  `plannedNotifications`, `productNotifications`, `weatherConsent`,
  `climate`, `plan`, `billingCycle`, plus `wishlist: array<string>` and
  `seeded: bool`, both already named by the schema doc as belonging on
  this document even though `wishlist` is not part of `ProfileState` and
  `seeded` is infra-only). No `firestore.rules` change this task (Task 9
  owns that file; today's `users/{uid}/{document=**}` owner-only
  default-deny already covers the document itself at the auth-isolation
  level).
- This task **extends** Task 1's existing `runBootstrapIfNeeded` seedWriter
  contract (`lib/shared/backend/firestore_service.dart`, already
  implemented) — it does not rewrite the transaction mechanism, the
  `seeded` guard, or the lock-keying behavior. `FirestoreProfileRepository`
  supplies the `seedWriter` function; `FirestoreService` still owns
  running it inside the transaction and committing `seeded: true`
  afterward.
- No migration: for any uid whose `users/{uid}` document already exists
  from Task 1/2/3/4's own bootstrap writes (wardrobe/outfits/planned
  entries), this task's profile fields are added onto the *same* document
  via the *same* `seeded`-guarded bootstrap — not a second, separate
  seeding pass. If `seeded` is already `true` for a uid by the time this
  task's code runs for them (e.g. they were bootstrapped by an earlier
  task's own profile-document touch, if any), no profile fields are
  retroactively backfilled — same "no migration" stance as F15/F16/F17.

## 9. Background work and events

- No Cloud Function, no scheduled job, no retry/queue logic triggered by
  this task — every `set*`/`updateDetails` call is a one-shot merge-`set()`
  call.
- `watchProfile()`'s Firestore `snapshots()` listener is long-lived for the
  life of the signed-in `ProfileCubit` instance; it is torn down (per F14
  D3) on every sign-out/sign-in transition along with the rest of the
  subtree, never left subscribed past the Cubit's `close()`.

## 10. Degradation and failure

- Guest mode (`InMemoryProfileRepository`) makes zero Firestore calls —
  structurally, not "falls back after a failed call," the same guarantee
  F14/F15/F16/F17 established for other repositories.
- `FirestoreProfileRepository.watchProfile()` losing network connection
  mid-session: Firestore's SDK-level offline cache/reconnect behavior
  applies (not added or suppressed by this task), matching F15/F16/F17's
  same stance.
- A `set*`/`updateDetails` repository call failing (offline, permission
  error, etc.) after `ProfileCubit` already optimistically applied the new
  value: the Cubit reverts **only** the field(s) the failed call was
  writing, against its current state at the time of failure — never a
  captured-whole-`ProfileState`-before-the-call restore, which would wipe
  any other field a concurrently in-flight, independently-succeeding
  setter had just changed (F17's own review-round bug, avoided here from
  day one; see §11 A12/A13).
- A new user toggling nothing during onboarding: the bootstrap seedWriter
  writes `ProfileState()`'s hardcoded default `occasions`
  (`['Everyday','Office']`), never an empty list — "no selection" must
  never be confused with "explicitly cleared to nothing" (there is no UI
  path producing the latter today, but the repository's write behavior
  must still make the distinction, matching the project's
  missing-vs-empty convention from `03-domain-model.md` §4).
- A returning user's `users/{uid}` document predates this task's profile
  fields (practically unlikely given "no migration" in §8, but possible if
  a uid was only ever bootstrapped by an earlier task before this one
  landed): `watchProfile()` reading a document with an entirely missing
  `occasions`/`styles`/`climate`/`plan`/`billingCycle` field falls back to
  `ProfileState()`'s matching hardcoded default for that field — distinct
  from an explicitly-present-but-empty value (`occasions: []` or
  `climate: ''`), which is read back verbatim, never silently coerced to
  the default (§11 A18/A19).

## 11. Validation assertions

```
F18-A01  [U]  FirestoreProfileRepository round-trips every ProfileState field (name, email, styles, occasions, dailyNotifications, plannedNotifications, productNotifications, weatherConsent, climate, plan, billingCycle) unchanged through a write-then-watchProfile() read
F18-A02  [U]  FirestoreProfileRepository's raw document, read directly (bypassing watchProfile()'s mapping) after any write, carries exactly ProfileState's 11 fields plus wishlist and seeded — never a stray extra field — and watchProfile()'s emitted ProfileState never exposes wishlist or seeded as one of its own fields (mirrors F14's seeded-exclusion precedent; schema doc §1)
F18-A03  [U]  The D5 bootstrap write (FirestoreService.runBootstrapIfNeeded's seedWriter, supplied by FirestoreProfileRepository) sets wishlist: [] on a brand-new user's first sign-in, alongside Task 1's existing seeded: true merge-set (verified unchanged — a second runBootstrapIfNeeded call for the same uid performs no further seed write at all, reaffirming F14's guard rather than reimplementing it)
F18-A04  [U]  Every FirestoreProfileRepository write method (updateDetails, setStyles, setOccasions, setDailyNotifications, setPlannedNotifications, setProductNotifications, setWeatherConsent, setClimate, setPlan, setBillingCycle) is implemented without runTransaction — a test double records every call made to the fake and asserts no transaction API is invoked by any of them, documenting that each one is a plain overwrite of a value the Cubit already fully computed (distinct from F16's logWear/removeWear)
F18-A05  [I]  RED-first regression, run and shown failing against current main before any Task 5 code change lands (command + failing output pasted into the completion block): toggling at least one occasion on /intro's slide 4 and at least one chip on /personalize, then completing Google sign-in through AuthCubit.signInWithGoogle(), results in the resulting ProfileCubit's state showing only ProfileState()'s hardcoded default occasions — none of the user's onboarding choices present — proving the gap is real, not a misread of the plan
F18-A06  [I]  After the handoff fix, the same sequence as A05 results in ProfileCubit's resulting ProfileState.occasions containing every name the user toggled across both chosenOccasions and chosenChips (duplicates collapsed; union semantics, see §13), persisted through the D5 bootstrap write so it survives a simulated app relaunch/re-sign-in (re-read via watchProfile(), not just the first optimistic emit)
F18-A07  [U]  A user who toggles nothing during onboarding (chosenOccasions and chosenChips both empty) still bootstraps with ProfileState()'s existing hardcoded default occasions (['Everyday','Office']) — the bootstrap seedWriter never writes an empty occasions list just because no selection was made, distinguishing "didn't choose" from "chose to clear everything"
F18-A08  [U]  Guest mode (InMemoryProfileRepository) behavior is unchanged from today's ProfileCubit-held logic — the full pre-existing profile-related test suite (test/features/profile/profile_cubit_test.dart or equivalent) passes unmodified against ProfileCubit constructed with InMemoryProfileRepository, with zero existing assertion edited to accommodate this task
F18-A09  [U]  InMemoryProfileRepository's write methods return a SynchronousFuture (or equivalent already-completed Future), not an async-declared method, verified by asserting the Future is already complete in the same microtask the call returns, before any pump/await — matching the Task 2/F15, Task 3/F16, Task 4/F17 lesson
F18-A10  [U]  InMemoryProfileRepository never imports or constructs a Firestore client — guest mode makes zero network calls, structurally (same guarantee style as F14-A14/F15-A08/F16-A16/F17-A10)
F18-A11  [I]  lib/app.dart: with uid == null, ProfileCubit is constructed with InMemoryProfileRepository; with uid == 'uid-1', it is constructed with FirestoreProfileRepository — object type differs across the F14 sign-in/out transition, driven through a real StyloBuddyApp pumped via the uidStream/firestoreOverride harness with a bounded-polling wait (never a bare pumpAndSettle() per the Task 2 known gotcha), never a hand-built Cubit, per the Task 2/3/4 lesson that a hand-built-Cubit-only test let app.dart's own ternary go unverified
F18-A12  [I]  ProfileCubit.<any setter>, when the repository call is in flight, has already optimistically updated state before the Future resolves (optimistic-then-reconcile, D6) — then, on a simulated repository failure, rolls back ONLY the field(s) that setter was writing, evaluated against the Cubit's current state at failure time, rather than leaving the optimistic value in place or reverting to a captured-whole-state-before-the-call snapshot
F18-A13  [I]  Two interleaved setter calls (e.g. setClimate then, before it resolves, setPlan) where only the first fails: the targeted rollback (A12) reverts climate only — plan's independently-applied, concurrently-succeeding change survives untouched (confound-free test proving the revert is field-scoped, not whole-object — F17's own review-round fix, applied from day one here)
F18-A14  [U]  Any write call inside ProfileCubit/FirestoreProfileRepository that is not directly awaited at its call site (fire-and-forget) has a .catchError (or equivalent) attached — a test asserts no unhandled rejection/uncaught Future error surfaces for a write allowed to fail in the background; if no such unawaited call exists in the final implementation, this assertion is satisfied vacuously and the implementer notes that in the completion block rather than skipping the test
F18-A15  [U]  FirestoreProfileRepository.watchProfile()'s stream subscription inside ProfileCubit has an onError handler attached — a test asserts a simulated stream error does not crash the Cubit or surface as an unhandled zone error
F18-A16  [I]  Sign-out then sign-in-again (same or different uid) leaves no stale ProfileState bleed-through: signing out renders InMemoryProfileRepository's default ProfileState (not the previous signed-in user's data, and not an empty/blank state either), and signing in as a different uid shows only that uid's own Firestore document's values, never the prior uid's cached values (F14 Review Focus item 2, re-verified at this feature's layer)
F18-A17  [U]  AuthCubit.submitSignup's existing name validation (name.trim().length < 2 rejected) means a FirestoreProfileRepository bootstrap seedWriter is never invoked with an empty name for a real signup — verified by a test asserting the seedWriter's captured name argument is never '' when driven through AuthCubit's own validated submitSignup path (does not relax or change AuthCubit's validation; only confirms this task's seedWriter never second-guesses it)
F18-A18  [U]  watchProfile() treats a Firestore document's entirely-missing occasions (or styles) field — e.g. a doc written before this task's fields existed — as ProfileState's hardcoded default list for that field; an explicitly-present-but-empty array (occasions: [], written directly for the test, not through any current ProfileCubit call site) is read back as a genuinely empty list, never silently coerced back to the default — the two cases are constructed directly against the fake and produce different ProfileState values
F18-A19  [U]  watchProfile() treats a missing climate/plan/billingCycle string field (legacy doc) as ProfileState's hardcoded default string value for that field, distinct from an explicitly-written empty string ('', written directly for the test since no current ProfileCubit setter ever produces one) which is read back verbatim as '' and never coerced to the default
F18-A20  [L]  Against the live Firestore project (stylobuddy-b7e46), a real test user's onboarding-choice -> sign-up -> profile-edit -> sign-out -> sign-in-again sequence round-trips correctly and the bootstrap-seeded profile (including the onboarding-forwarded occasions and wishlist: []) is visible after killing and relaunching the app — deferred to the live-verification pass, documented in the task report rather than a CI-run test
```

## 12. Edge cases

- A user toggles an occasion/chip, then untoggles it, before ever reaching
  `/auth`: the handoff holder's final state is whatever is currently
  toggled at the moment sign-in succeeds (last-state-wins, no history) —
  matching `OnboardingState`'s own toggle semantics exactly (no
  de-duplication logic needed beyond the existing `Set<String>` toggle).
- A user abandons onboarding entirely (closes the app between
  `/personalize` and completing sign-up, or never signs up at all) and
  later relaunches, restarting onboarding from scratch: since the handoff
  holder is app-process-lifetime only (never persisted to disk, per §5),
  it starts empty again on the fresh process — no stale choices from an
  earlier, abandoned attempt can leak into a later, unrelated sign-up in
  the same cold start, and no choices survive a full app kill either way
  (acceptable: the entire onboarding navigation stack is already lost on a
  cold restart today, this is not a new loss).
- `chosenOccasions` and `chosenChips` overlap in vocabulary (`introOccasions`
  includes `'Office'`/`'Wedding'`/`'Party'`; `personalizeChips` includes
  `'Everyday'`/`'Office'`/`'Wedding'`/`'Party'`/`'Travel'`) — the union
  (§13) naturally de-duplicates a name picked in both places; this task
  adds no separate de-duplication step beyond `Set` union's own semantics.
- `togglePreference` called twice in immediate succession for the same
  field before the first write's `Future` resolves: the second call's
  optimistic update simply overwrites the first in `ProfileCubit.state`
  (last-caller-wins, matching today's single-threaded in-memory behavior)
  and the second Firestore write similarly overwrites the first merge-set
  — no de-duplication added by this task, inherited risk, not newly
  introduced (same shape as F16 §12/F17 §12's equivalent notes).
- `updateDetails` editing `email` on a signed-in user: per schema doc §1,
  this field only *mirrors* `FirebaseAuth.currentUser.email` at sign-in and
  is "not re-read from Auth on every load" — so an edit here changes only
  the Firestore-stored copy, never calls back into `FirebaseAuth` to
  change the actual sign-in email; this task does not add that
  cross-system sync (pre-existing stance, re-affirmed, not decided here).

## 13. Open questions

- **Exact mechanism for the onboarding-handoff holder (§5, §6) is left to
  the implementer; only its observable behavior (§11, especially A05/A06/
  A07) is binding.** The current routing structure
  (`onboarding_routes.dart`'s `ShellRoute` holding `OnboardingCubit`,
  `auth_routes.dart`'s separate `ShellRoute` holding `AuthCubit`, confirmed
  by reading both files) means `OnboardingCubit`'s state does not survive
  navigating from `/personalize` to `/auth` — the two Cubits are never
  siblings in the widget tree at the moment sign-in succeeds. Candidate
  shapes (not prescribed): a small app-lifetime singleton/static holder
  that `OnboardingCubit.toggleOccasion`/`toggleChip` also write into; a
  root-level Cubit provided above both shells (e.g. in `app_router.dart`'s
  top-level `GoRouter` config or a wrapper above it); or passing the
  accumulated set as route "extra" data through the navigation calls
  already made by `intro_view.dart`/`personalize_view.dart` (these are
  widget files and are frozen per the implementer contract's rulings — so
  this candidate would require either routing the data through calls those
  widgets *already* make without adding new widget logic, or asking the
  controller for an explicit, narrow exception; raised here rather than
  assumed).
- **Union semantics for chosenOccasions ∪ chosenChips -> ProfileState.occasions
  is this document's call, not a re-derivation of an unstated plan
  decision.** The plan brief names both sets ("forward
  chosenOccasions/chosenChips into the Profile repository") without
  specifying how two separate toggle sets become one `ProfileState.occasions`
  list. Reading `personalize_view.dart` confirms there is no
  `chosenStyles`-shaped state to map `chosenChips` to instead (see §3) —
  both sets are occasion-shaped UI (`introOccasions` glyph rows on slide 4;
  `personalizeChips` under the "Occasions you dress for" section title on
  `/personalize`), so union into the single `occasions` field is the only
  sensible mapping. This document decides that union (not last-one-wins,
  not two separate fields) is correct; a reviewer who disagrees should
  amend A06, not silently reinterpret it during implementation.
- **`personalizeStyles` (the "What feels most like you?" tiles) capture
  nothing today** (confirmed: `onTap` only toasts, `selected` is a
  hardcoded constant, no `OnboardingCubit` method or field exists for it).
  Whether a future task should add real style-tile selection state and
  forward it to `ProfileState.styles` the same way this task forwards
  occasions is not decided here — out of scope per §3, flagged for
  product input rather than invented.
- **Whether `wishlist`'s presence on the same `users/{uid}` document (but
  outside `ProfileRepository`'s interface) risks a future accidental
  duplicate write path once Task 6 lands** is flagged, not resolved, here
  — Task 6's own brief already names this review focus explicitly ("confirm
  no duplicate write path versus Task 5's profile doc"); this document's
  contribution is only to make sure `ProfileRepository` itself exposes no
  method that could collide (§3), leaving Task 6 to verify its own side.
- This document carries forward F17 §13's observation style: the
  `runTransaction`-free design for every `ProfileRepository` write method
  (§6, A04) is a *settled* decision, not an open question — named
  explicitly only so a reviewer comparing this task to F16's
  read-modify-write precedent does not mistake the absence of a
  transaction for an oversight.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: DONE (A01-A19 implemented and verified; A20 [L] pending live-verification pass)

[x] Gate 1  Interface documented (lib/features/profile/repository/profile_repository.dart)
[x] Gate 2  Unit (profile_repository_test.dart, profile_cubit_dual_mode_test.dart,
    profile_cubit_test.dart unmodified)
[x] Gate 3  Integration (app_backend_wiring_test.dart F18_A11/F18_A16_app;
    onboarding_handoff_test.dart F18_A05_A06/F18_A07 driven through real
    AuthCubit.signInWithGoogle() against faked Firebase Auth/Google
    Sign-In plugin objects)
[ ] Gate 4  Live run (A20, deferred — not exercised against the live
    Firestore project `stylobuddy-b7e46`)

Assertions: 19/20 PASS (A20 [L] pending)
Regression: full `flutter test` suite green — 538/538 passed; `flutter analyze` — No issues found!
```

### Fix round (review findings)

All review findings addressed — see
`.superpowers/sdd/2026-10-19-backend-wiring/task-5-report.md`'s "Fix round" section for the
full write-up. Summary:

- **Critical (controller ruling):** `lib/app.dart`'s signed-in `ProfileCubit` branch now makes
  the single production `runBootstrapIfNeeded` call for wardrobe/outfits/planner's own D5 seed
  data too (a `seedWriter` reusing each `FirestoreXRepository.seedFieldsFor*` write shape),
  folded under the one shared `seeded` flag alongside Profile's own `extraFields` payload. New
  test `fix_round_Important1_combined_bootstrap` (test/app_backend_wiring_test.dart) proves a
  brand-new signed-in user's bootstrap actually seeds Firestore with `SeedData`'s wardrobe
  items/outfits/planned entries, not just profile fields — verified RED (fails against the
  pre-fix `lib/app.dart`) → GREEN.
- **Important #2 (F18-A05 RED evidence):** replaced the compile-error RED evidence with real
  behavioral RED output, re-run against a `git worktree` checkout of commit `031162f` (main
  immediately before this task) — see the report for the full command/output. The test passes
  on that commit, proving the gap is real: a toggled onboarding occasion never reaches a
  post-sign-in, argument-less `ProfileCubit()`.
- **Important #3 (real app.dart-level handoff test):** added
  `fix_round_Important3_new_uid` and `fix_round_Important3_returning_uid`
  (test/app_backend_wiring_test.dart) — both pump the real `StyloBuddyApp`, drive a fake uid
  stream, and poll the injected fake Firestore directly, rather than hand-reimplementing
  `lib/app.dart`'s consume-and-bootstrap logic as the original `onboarding_handoff_test.dart`
  did.
- **Important #4 (real name/email seed):** `FirestoreProfileRepository.bootstrapIfNeeded` now
  accepts `name`/`email`, sourced in `lib/app.dart` from a new
  `currentUserProfileHint()` (`lib/shared/backend/auth_session.dart`) that reads
  `FirebaseAuth.instance.currentUser?.displayName`/`?.email`, falling back to the hardcoded
  defaults only when unavailable/empty.
- **Important #5 (no clobbering a pre-existing field):** `runBootstrapIfNeeded`'s `extraFields`
  callback is now handed the transaction's own read snapshot, and
  `FirestoreProfileRepository.bootstrapIfNeeded` only includes keys genuinely absent from it.
  Also fixed a fake_cloud_firestore limitation found while testing this (its `tx.set(...,
  merge: true)` does not merge against the document's pre-transaction state, only against
  earlier writes in the same transaction) by explicitly spreading the snapshot's own data into
  the final write. `F18_A16_app` rewritten to pre-seed a race scenario deterministically
  (pre-existing `name` field, no `seeded` flag) and assert the edit survives, instead of
  "waiting out" a race and treating that as success.
- **Minor #1:** removed the `F18_A08` `expect(true, isTrue)` placeholder; real A08 coverage is
  `profile_cubit_test.dart`, unmodified.
- **Minor #2:** `F18_A10` now also greps the source file for `cloud_firestore`, matching
  F14-A14/F15-A08's structural-check precedent.
- **Minor #3:** `F18_A02` now reconstructs `ProfileState` from only its 11 known fields and
  greps `profile_state.dart`'s source for `wishlist`/`seeded`, instead of a bare
  `isA<ProfileState>()`.
- **Minor #4/#5:** no change — Minor #4 (`F18_A11`/`F18_A16_app` coverage) was already accepted
  by the reviewer as adequate; Minor #5 (`ProfileCubit`'s `BlocProvider` laziness) left as-is to
  avoid disturbing other tests' Cubit-construction-timing assumptions, noted as an open,
  non-blocking question for a future pass.

Regression after fix round: full `flutter test` suite green — 543/543 passed; `flutter
analyze` — No issues found!
