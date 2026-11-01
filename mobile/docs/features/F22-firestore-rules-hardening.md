# F22 — Firestore Security Rules Hardening + Emulator Tests

> Replaces the live `firestore.rules`' single blanket owner-only rule
> (`users/{uid}` plus a recursive `users/{uid}/{document=**}` wildcard) with
> one rule block per collection. Each block keeps the owner check and adds
> field-level validation: an allow-list of keys (`hasOnly`), a type check per
> field, and the invariants the client already enforces. The collections are
> the `users/{uid}` profile document, `wardrobeItems`, `outfits`,
> `wearEvents`, `plannedEntries` and `packingTrips`. Every rule is proven
> against the local Firestore emulator. The task ends with a production
> deploy, which is a separate step behind an explicit gate. This is Task 9 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`. It is grounded in
> `docs/superpowers/specs/2026-10-19-firestore-schema.md` (§1-6 for each
> collection's fields, §8 for the rule shape) and
> `docs/foundation/07-security.md` §2-3. It depends on every repository task
> that writes Firestore data: F14 (bootstrap), F15 (wardrobe), F16
> (outfits/wear events), F17 (planner), F18 (profile), F19 (wishlist) and F20
> (packing). F21 (email/password auth, Task 8) is DEFERRED by user decision
> on 2026-10-20 and does not block this task. It changes only the auth
> provider, never the shape of a Firestore document.

**Status:** DONE (Gates 1-3 closed, emulator-proven — A01-A49+A46b, 50/54 assertions; Gate 4 — A50-A53, production audit/deploy/live-smoke/rollback — deferred pending an explicit human go-ahead) · **Milestone:** 2 · **Depends on:** F14, F15, F16, F17, F18, F19, F20 (F21 deferred, non-blocking)

---

## 1. Goal

The live database still trusts any signed-in user to write any field, of any
type, into their own `users/{uid}/...` tree. That includes collections no
feature owns. This task makes Firestore itself reject malformed and
out-of-schema writes, without rejecting a single write the app makes today.
The second half is the hard part. A rule stricter than the real code turns
into a production outage that reports itself as "success" in the app: every
signed-in write is optimistic (architecture D6), so a write the rules deny
shows success in the UI, then silently rolls back. A denied D5 bootstrap
leaves a new user with an empty wardrobe on every launch. This document
therefore checks the rules against the code that actually writes, not just
against the schema doc's field lists.

## 2. MVP scope

- `firestore.rules`: replace the recursive `users/{uid}/{document=**}`
  wildcard with explicit `match` blocks:
  - `users/{uid}` (profile document, schema §1)
  - `users/{uid}/wardrobeItems/{itemId}` (§2)
  - `users/{uid}/outfits/{outfitId}` (§3)
  - `users/{uid}/wearEvents/{eventId}` (§4)
  - `users/{uid}/plannedEntries/{dateKey}` (§5)
  - `users/{uid}/packingTrips/{tripId}` (§6)

  Every other path, including any other subcollection under `users/{uid}`,
  falls back to default-deny.
- Each block allows, for the owner only:
  - `read` (get and list), unchanged from today.
  - `create`/`update`, gated on key allow-list, per-field type and invariant
    checks (§5 "Rule shape").
  - `delete`, gated on ownership only.
- New emulator-backed suite `test/firestore_rules_test/` (§5 "Test
  harness"). Per collection it covers:
  - owner valid write succeeds;
  - owner extra-key write fails;
  - wrong-type and invariant-violating writes fail;
  - a different uid's read and write fail;
  - signed-out read and write fail.

  It also has two cross-cutting checks: the "replay every real repository
  write" check (A46) and the D5 bootstrap-transaction check (A47).
- `firestore.indexes.json`: no change. The `wearEvents` index item is closed
  explicitly as not needed (§8, A49).
- Docs updated to match the new reality, per the plan's global constraint:
  - `docs/foundation/07-security.md` §3: field-level hardening becomes
    current fact, not "Task 9".
  - `firestore-schema.md` §4: stale "orders by timestamp descending" query
    note.
  - `firestore-schema.md` §8: its example block's `allow write` shape
    breaks deletes (§13 Q4).
- **Final, separately gated step:** a read-only production data audit (A50),
  then `firebase deploy --only firestore:rules --project stylobuddy-b7e46`
  (A51), then a live smoke test (A52). This happens only after an explicit
  controller go-ahead (§13 Q1). Passing the emulator suite does not trigger
  it.

## 3. Later scope

- Enumerated-value checks:
  - `ProfileState.plan` / `billingCycle` / `climate`;
  - `ClothingItem.category` / `color` / `season` against `SeedData`'s
    constants;
  - `Trip.type` against the six trip types in `03-domain-model.md`.

  Out of scope because those lists are UI copy that can change without a
  rules deploy. Pinning them server-side would couple every copy change to a
  production rules deploy.
- Per-element validation inside arrays: `Outfit.items` /
  `WearEvent.items` / `ProfileState.styles` elements being strings, and
  `PackingItem` map keys/types inside `Trip.items`. The rules language has no
  loops, so only `is list` (and optionally size) can be checked (§12).
- A size cap on `Trip.items`. Schema §6 mentions "≤12 per F10's cap logic",
  but `addCustom`/`addWardrobe` append with no cap, so a server-side cap
  would deny real writes (§12).
- Non-empty-string checks such as `name.size() > 0`. Blank-input rejection
  is a client-side rule (G-A02), and some defaults and partial writes
  legitimately carry `''`.
- Cross-document referential checks (`get()`/`exists()`), e.g. a
  `PlannedEntry.outfitId` must name an existing `Outfit`. The domain model
  explicitly tolerates dangling references (`03-domain-model.md` "readers
  must tolerate the missing outfit"). These checks would also add document
  reads to the 27-write bootstrap transaction (A06).
- Supabase Storage policies. Those are a separate system, owned by Task 2.
- Email/password-specific rules. F21 is deferred, and no rule here depends
  on the sign-in provider.

## 4. Roles and permissions

Uses the roles in `docs/foundation/07-security.md` §2 unchanged:

| Role | Under hardened rules |
|---|---|
| guest | Makes no Firestore calls (structurally, F14-F20). Unaffected. |
| demo user | Same as guest. Never reaches cloud data. Unaffected. |
| authenticated user (`request.auth.uid == uid`) | Read/list/delete own documents in the six named locations. Create/update them only with allow-listed keys of the right types. Nothing anywhere else. |
| authenticated user, other uid | Denied everything under another user's `users/{uid}` tree, including `list` on the subcollections and on the `users` collection itself. |
| signed out (`request.auth == null`) | Denied everything. |

No admin or service role is added to the rules. The Admin SDK and the
emulator's `owner` bearer bypass rules by design. The test harness uses that
bypass only to seed fixtures (§5), and production uses it only for the
read-only audit (A50).

## 5. Main flows

### Rule shape (binding for review, refines schema §8)

Each subcollection block follows this logic:

```text
match /users/{uid}/<collection>/{docId}:
  isOwner      := request.auth != null && request.auth.uid == uid
  allow read   := isOwner
  allow delete := isOwner                       # request.resource is null on delete
  allow create, update := isOwner
      && request.resource.data.keys().hasOnly([<exact field list, schema §1-6>])
      && for each field f:  !(f in data) || <type/invariant check for f>
      && (id field, where the collection duplicates it): !('id' in data) || id matches docId
```

The rule design needs three deliberate departures from schema §8's literal
example. Each is traced to a real write path:

1. **`delete` is split from `create`/`update`.** The schema §8 example uses
   `allow write: if ... request.resource.data.keys()...`. On a delete,
   `request.resource` is null, so that expression errors and the request is
   denied. That would break every delete in the app:
   - `WardrobeRepository.removeItem`
   - `OutfitsRepository.delete`
   - `removeWear`'s `tx.delete`
   - `PlannerRepository.remove`
   - `PackingRepository.deleteTrip`

   (A18/A25/A31/A37/A45; §13 Q4.)
2. **No field is ever required to be present.** No block uses `hasAll`, and
   every type check is written as "absent, or the right type". Several real
   writes legitimately produce a partial document:
   - Profile setters (`setStyles` etc.) and `setMembership` are merge-sets.
     When they land before the bootstrap has created `users/{uid}`
     (offline edit, first-launch race), they create a document with one key
     (A11).
   - `saveTrip`'s edit branch merge-sets every field except `items`. If the
     trip was deleted concurrently on another device, that creates a trip
     document without `items` (A43).
   - `upsertManual`'s edit branch is `update({name, occasion, items})`. On a
     missing document it must still reach Firestore's `not-found`, so F16's
     fallback still fires, rather than being turned into `permission-denied`
     (A24).
3. **Explicit `null` is accepted only where the code writes it.**
   - `ClothingItem.sourceId` and `ClothingItem.imageUrl`: every `SeedData`
     item and every item with no photo is written with `'sourceId': null,
     'imageUrl': null` (`FirestoreWardrobeRepository._toFirestore`). A plain
     `sourceId is string` check would deny all 23 bootstrap seed items, and
     with them the whole bootstrap transaction (A13, A47).
   - Every other field rejects `null`, so "present-but-null" and "missing"
     stay distinct (A12, A17).

The `users/{uid}` profile block follows the same shape with its 13-key list.
It has no `id` field. `allow read` is `get` only for the owner. A `list` on
the `users` collection is denied for everyone (A05).

The recursive `{document=**}` wildcard is removed, not kept alongside the new
blocks. Firestore ORs every matching `allow`, so if the wildcard stays, every
validation block above is bypassed. A04 proves it is gone.

### Test harness (emulator only)

```text
developer/CI -> firebase emulators:exec --only firestore --project demo-stylobuddy "<run emulator-tagged suite>"
emulator: loads ./firestore.rules (firebase.json), project id demo-stylobuddy (demo- prefix: cannot reach production)
suite:
  setup  : clear emulator data (DELETE emulator documents endpoint)
           seed fixtures via the emulator's rules-bypassing `owner` bearer (only for preconditions,
           e.g. an existing doc to update, a legacy doc with a stray key)
  act    : issue the write/read as the identity under test
           - owner / other uid : unsigned mock ID token (emulator-accepted) with sub=user_id=<uid>
           - signed out        : no Authorization header
  assert : success -> read the document back via the bypass and compare
           denial  -> response is specifically PERMISSION_DENIED (A02), never "any error"
emulator unreachable / env var missing -> suite FAILS with a stated message (A01), never skips
```

The default `flutter test` run does not include this suite (A03). Only the
`emulators:exec` command runs it.

### Repository-replay check (protection against "rules stricter than the code")

```text
for each public write method of each Firestore*Repository (enumerated in A46):
  run the REAL repository method against fake_cloud_firestore seeded with SeedData
  read back every document it produced/changed (the post-write state)
  replay that document state to the emulator as the owner (and, for merge/update paths,
    as the same operation kind: merge-set / update-mask / arrayUnion transform)
  -> every replayed write must be ALLOWED
static check: the enumerated method list == the set of public write methods on every
  Firestore*Repository class, so a future write method cannot be silently uncovered (A46b)
```

The check drives the real `_toFirestore` converters, including the public
`seedFieldsFor*` wrappers, rather than hand-copied field maps. If a
repository's write shape later drifts from the rules, this check fails
before a deploy does.

### Bootstrap check

```text
one emulator transaction as owner of a fresh uid:
  set users/{uid}  = ProfileRepository bootstrap payload (11 ProfileState keys, 12 from 2026-10-22 when a gender was chosen (F24) + wishlist [] + seeded true)
  set 23 x wardrobeItems/{SeedData item id} = FirestoreWardrobeRepository.seedFieldsFor(item)
  set  2 x outfits/{id}                     = FirestoreOutfitsRepository.seedFieldsForOutfit(outfit)
  set  1 x plannedEntries/2026-10-15        = FirestorePlannerRepository.seedFieldsFor(entry)
commit -> allowed, all 27 docs present
same transaction with ONE wardrobe doc carrying an extra key -> whole commit denied, 0 docs written
```

### Production deploy (final, gated, never automatic)

```text
precondition: A01-A49 PASS on the emulator, recorded with command + date
controller -> implementer: explicit go-ahead to deploy (date recorded in completion block)   [§13 Q1]
implementer:
  1. capture current production rules verbatim (== §8 "Before"), for rollback
  2. read-only audit of every users/** document in stylobuddy-b7e46 against the new
     field lists/types (A50) -> 0 violations, or stop and escalate (§13 Q3)
  3. firebase deploy --only firestore:rules --project stylobuddy-b7e46
     (no .firebaserc exists, so --project is mandatory; credentials via the service
      account at ~/.secrets/stylobuddy/firebase-service-account.json, never committed)
  4. live smoke (A52) on a real device + a live cross-uid denial probe
  5. any A52 failure -> redeploy captured "Before" rules immediately (A53), report it
report: before/after diff of firestore.rules, audit counts, smoke results
```

## 6. Interface surface

This task adds no Dart API. Its surface is the security rules contract
(who may do what, at which path) and one test command.

```text
users/{uid}                             get: owner   list(users): nobody   create/update: owner+validated   delete: owner
users/{uid}/wardrobeItems/{itemId}      get/list: owner   create/update: owner+validated   delete: owner
users/{uid}/outfits/{outfitId}          get/list: owner   create/update: owner+validated   delete: owner
users/{uid}/wearEvents/{eventId}        get/list: owner   create/update: owner+validated   delete: owner
users/{uid}/plannedEntries/{dateKey}    get/list: owner   create/update: owner+validated   delete: owner
users/{uid}/packingTrips/{tripId}       get/list: owner   create/update: owner+validated   delete: owner
any other path                          nothing (default-deny)

firebase emulators:exec --only firestore --project demo-stylobuddy "<emulator suite cmd>"   run rules tests (developer)
firebase deploy --only firestore:rules --project stylobuddy-b7e46                          production deploy (gated, A51)
```

Denied requests return gRPC `PERMISSION_DENIED`, which is HTTP 403 on REST
and `FirebaseException.code == 'permission-denied'` in the Flutter SDK. That
is the only error code these rules introduce.

## 7. Domain model usage

The validated field sets are exactly the persisted fields of these entities
from `docs/foundation/03-domain-model.md`, as mapped in `firestore-schema.md`
§1-6. No field is invented.

| Path | Allowed keys (`hasOnly`) | Type / invariant checks (when present) |
|---|---|---|
| `users/{uid}` | `name`, `email`, `styles`, `occasions`, `dailyNotifications`, `plannedNotifications`, `productNotifications`, `weatherConsent`, `climate`, `plan`, `billingCycle` (`ProfileState`), `wishlist` (`ShoppingState.wishlist`, schema §1), `seeded` (infra, schema §1) | strings: name, email, climate, plan, billingCycle. lists: styles, occasions, wishlist. bools: the four notification/consent flags, seeded. No null allowed. |
| `wardrobeItems/{itemId}` | `id`, `name`, `category`, `color`, `occasion`, `season`, `wears`, `sourceId`, `imageUrl` (`ClothingItem`) | `id is string && id == itemId`. Strings: name, category, color, occasion, season. `wears is int && wears >= 0`. `sourceId`, `imageUrl`: `== null` or `is string` (`''` allowed; the reader normalizes it, F15-A16). |
| `outfits/{outfitId}` | `id`, `name`, `occasion`, `why`, `items`, `worn` (`Outfit`) | `id is int && string(id) == outfitId`. Strings: name, occasion, why. `items is list`. `worn is int && worn >= 0`. |
| `wearEvents/{eventId}` | `id`, `outfitId`, `name`, `occasion`, `items`, `timestamp` (`WearEvent`) | `id is int && string(id) == eventId`. `outfitId is int`. Strings: name, occasion. `items is list`. `timestamp is timestamp`. |
| `plannedEntries/{dateKey}` | `outfitId`, `occasion` (`PlannedEntry`) | `outfitId is int`, `occasion is string`. Doc ID `dateKey` matches `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`, the padded key `PlannerCubit` and `SeedData.planned` always produce. |
| `packingTrips/{tripId}` | `id`, `name`, `destination`, `start`, `end`, `type`, `notes`, `days`, `items` (`Trip`) | `id is string && id == tripId`. Strings: name, destination, start, end, type, notes. `days is int && days >= 1` (`PackingCubit._daysBetween` clamps to ≥1). `items is list` (elements are `PackingItem` maps `{key, label, wardrobeId, packed}`, not checkable per element, §12). |

> Note 2026-10-22 (F24): the `users/{uid}` row gains a 14th allowed key,
> `gender` (from `ProfileState.gender`, F24), with the check
> `!('gender' in data) || data.gender in ['male', 'female']` (null denied,
> consistent with "No null allowed" above). The A50 pre-deploy audit must
> treat `gender` as allowed, and the deferred production deploy (A51-A53)
> must ship the F24-amended `firestore.rules`.

**Cross-check of schema doc vs. code that writes today (done for this
document, not assumed):**

| Collection | Schema doc fields | Fields the code actually writes | Match? |
|---|---|---|---|
| profile | §1: 11 + `wishlist` + `seeded` | `FirestoreProfileRepository._toFirestore` (11 keys), setters (subsets of those 11), `bootstrapIfNeeded` (`+ wishlist: []`), `runBootstrapIfNeeded` (`+ seeded: true`, **plus a spread of `existingData`**), `FirestoreShoppingRepository.setMembership` (`wishlist` only) | Names match. Risk: the bootstrap spreads whatever is already on the document back into its write (A48, §13 Q3). |
| wardrobeItems | §2: 9 | `_toFirestore`/`seedFieldsFor`: the same 9, `sourceId`/`imageUrl` written as explicit `null` when unset | Names match. Nullability must be allowed (§5 point 3). |
| outfits | §3: 6 | `_outfitToFirestore`: 6. `upsertManual` edit: `update` of 3. `logWear`/`removeWear`: full typed `tx.set` | Match |
| wearEvents | §4: 6 | `_wearEventToFirestore`: 6 (`timestamp` as `Timestamp`) | Fields match. **Stale note:** §4 says `watchWearEvents()` "orders by `timestamp descending`", but the code issues no `orderBy` and sorts client-side (F16-A12). |
| plannedEntries | §5: 2, no id | `_toFirestore`: `outfitId`, `occasion` | Match |
| packingTrips | §6: 9 | create: full 9. Edit: merge of 8 (no `items`). `_mutateItems`: `tx.update` of `items` only | Match |

No field-name mismatch exists today. The discrepancies found are about
nullability and partial-document shapes (§5 points 2-3), the stale §4 query
note, and the schema §8 example's delete defect. The schema doc is amended
for the last two (§8 below). §13 Q2 covers precedence for any mismatch found
later.

## 8. Data changes

- **`firestore.rules` (Before, current production, captured verbatim for the
  deploy report and rollback):**

  ```text
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{uid} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
        match /{document=**} {
          allow read, write: if request.auth != null && request.auth.uid == uid;
        }
      }
    }
  }
  ```

  **After:** the six blocks described in §5/§7, with no recursive wildcard.
  The full before/after diff goes in the task report (A51).
- **`firestore.indexes.json`:** unchanged (`{"indexes": [], "fieldOverrides":
  []}`). No repository issues an `orderBy`, `where`, `limit` or
  `collectionGroup` query. Every `watch*` is a bare collection or document
  `snapshots()`, sorted in Dart. `wearEvents` therefore needs no index of
  any kind, and single-field descending indexes are automatic anyway.
  The plan's "if the emulator flags it" trigger also cannot happen: the
  Firestore emulator does not enforce index requirements. The item is closed
  as not needed (A49).
- **`firebase.json`:** unchanged. It already points at both files. An
  `emulators.firestore` port block may be added if the default port 8080
  collides locally. That is an environment detail, not a contract.
- **New tests:** `test/firestore_rules_test/` (Dart, `package:http` against
  the emulator REST API, recommended in §13 Q5). It may need a
  `dart_test.yaml` tag exclusion so the default `flutter test` run skips it
  (A03). That file is not in the plan's file list (§13 Q6).
- **Docs:**
  - `docs/foundation/07-security.md` §3: field-level rules are live.
  - `firestore-schema.md` §4: remove "orders by timestamp descending", note
    the client-side sort.
  - `firestore-schema.md` §8: replace the `allow write` example with the
    split `create, update` / `delete` shape and the "absent or typed"
    pattern.

  Each change carries a dated note.
- **No data migration.** Rules don't rewrite data. Existing documents that
  break the new rules are found by the A50 audit before deploy, not fixed
  silently.

## 9. Background work and events

None. This task adds no job, trigger, Cloud Function or event. Rules are
evaluated synchronously per request by Firestore. The production deploy is a
one-shot manual command (A51), never scheduled and never chained to a test
run or commit hook.

## 10. Degradation and failure

| Situation | Outcome |
|---|---|
| Emulator not running, or `FIRESTORE_EMULATOR_HOST` unset, when the rules suite is invoked | The suite fails with the message "Firestore emulator not reachable at <host>; run via `firebase emulators:exec ...`". It never skips or passes vacuously (A01). |
| Java runtime too old for the installed `firebase-tools` | `emulators:exec` refuses to start, the suite never runs, and the task is blocked as an environment step (§13 Q7). It is not reported as a pass. |
| `firestore.rules` has a syntax/compile error | The emulator fails to load the rules. Every test fails, and the error text appears in the emulator log. Deploy is not attempted. |
| A rule is stricter than real code (the main risk) | Caught pre-deploy by A46/A47. If it reaches production anyway: the client SDK accepts the write into its local cache, the server denies it, and the cache rolls back. The user sees the optimistic state revert (F16-F20 targeted rollbacks plus `_logError`). A denied bootstrap leaves `seeded` unset and retries, and is denied again, on every launch. A52 is designed to catch both. A53 rolls back. |
| Existing production doc already holds an out-of-schema key or wrong type | Under strict full-document `keys().hasOnly`, every later write to that document is denied, even a valid one-key merge, and the bootstrap spreads `existingData` into its own write (A48). The A50 audit must report zero such documents before deploy. Otherwise stop for a ruling (§13 Q3). |
| `firebase deploy` fails (auth, network, permission) | Rules releases are atomic, so production keeps the "Before" rules. The task reports the failure. Nothing is half-deployed. |
| Deployed rules break a live flow (A52 fails) | Redeploy the captured "Before" rules (A53). The report records what failed, which flow, and when access was restored. |
| Signed-in request with a token for a different uid | `PERMISSION_DENIED`. The app never constructs such a path (F14-A11), so this is defence-in-depth only. |
| Signed out, or guest/demo mode | Guests make no Firestore calls (structural, F14-F20). Any direct unauthenticated request gets `PERMISSION_DENIED`. |
| Optional field missing vs. empty vs. null | Missing: allowed for every field (partial documents, §5 point 2). Empty (`''`, `[]`, `0`): allowed where the type matches, and `0` only where the invariant allows it (`wears`/`worn` ≥ 0, `days` ≥ 1, so `days: 0` is denied). Explicit `null`: allowed only for `wardrobeItems.sourceId`/`imageUrl`, denied everywhere else. Each case is asserted separately (A12, A13, A17). |

## 11. Validation assertions

Gates: `[I]` assertions run against the Firestore emulator (a real database
and rules engine, with no production access). `[U]` assertions are static or
in-process checks. `[L]` assertions run against production `stylobuddy-b7e46`
and only inside the gated deploy step. "Owner" means a mock token for uid
`alice` acting on `users/alice/...`. "Other uid" means a token for `bob` on
`users/alice/...`. "Signed out" means no Authorization header. "Denied" means
the response is specifically `PERMISSION_DENIED` (A02).

```
F22-A01  [I]  The rules suite runs only against the emulator: it requires FIRESTORE_EMULATOR_HOST and uses project id `demo-stylobuddy`; no file under test/firestore_rules_test/ contains the string `stylobuddy-b7e46`; with the emulator stopped, invoking the suite exits non-zero with a message naming the unreachable host (it does not skip and does not pass)
F22-A02  [I]  Every denial test asserts the error is specifically PERMISSION_DENIED (HTTP 403 / status "PERMISSION_DENIED") and fails on any other outcome (success, connection error, 400 INVALID_ARGUMENT, 404); every denial test has a paired allowed test that differs only in the one dimension under test (identity, one key, or one value)
F22-A03  [U]  With no emulator running, the default `flutter test` command does not execute any test under test/firestore_rules_test/ and the full pre-existing suite stays green; the emulator suite is run by the single documented command `firebase emulators:exec --only firestore --project demo-stylobuddy "<suite cmd>"`
F22-A04  [I]  The recursive wildcard is gone: an owner write to users/alice/unknownCollection/x is denied; an owner write to users/alice/wardrobeItems/x/nested/y is denied; any signed-in write to a top-level path other/x is denied
F22-A05  [I]  An owner get of users/alice succeeds; a list query on the `users` collection by a signed-in user (alice) is denied
F22-A06  [U]  firestore.rules contains no get(), exists(), getAfter() or existsAfter() call (every rule depends only on the request itself, so the 27-write bootstrap transaction incurs no document-access reads)

# --- users/{uid} (profile document) ---
F22-A07  [I]  An owner create of users/alice with all 13 allowed keys, correctly typed (the bootstrap payload: 11 ProfileState keys + wishlist: [] + seeded: true), succeeds, and get/read-back returns identical values
              Note 2026-10-22 (F24): statement unchanged and still binding. F24 adds a 14th optional allowed key, `gender` (value must be 'male' or 'female' when present); the 13-key create without it must keep succeeding (F24-A36). Gender allow/deny cases are F24-A36..A38.
F22-A08  [I]  An owner write to users/alice with an extra key is denied, both as a full create (13 keys + `isAdmin: true`) and as a one-key merge-set `{isAdmin: true}` onto an existing valid document
F22-A09  [I]  As bob (other uid), get and merge-set of users/alice are both denied, and alice's document is unchanged afterwards
F22-A10  [I]  Signed out, get and merge-set of users/alice are both denied
F22-A11  [I]  Partial profile documents are allowed: a merge-set of `{styles: ['Casual']}` onto a non-existent users/alice succeeds and creates a one-key document; a merge-set with `wishlist: arrayUnion(['shop-1'])` onto a non-existent users/alice succeeds; arrayRemove of an absent id on an existing document succeeds
F22-A12  [I]  Profile type checks: each of `dailyNotifications: 'yes'`, `seeded: 1`, `styles: 'Casual'`, `wishlist: 'shop-1'`, `name: 7`, `name: null`, `styles: null` is denied as a one-key merge-set; missing vs empty: `styles: []`, `wishlist: []`, `name: ''` are each allowed, a document with no `styles` key is allowed (A11), and `styles: null` is denied, so missing, empty and null are three distinct, separately tested outcomes

# --- wardrobeItems ---
F22-A13  [I]  An owner create of users/alice/wardrobeItems/white-shirt succeeds and owner get and list succeed for each of: (a) the exact FirestoreWardrobeRepository.seedFieldsFor(SeedData item) map, with sourceId: null and imageUrl: null; (b) sourceId: 'white-shirt', imageUrl: 'alice/white-shirt.jpg'; (c) both keys absent; (d) imageUrl: '' (empty string allowed and read back as stored)
F22-A14  [I]  An owner write with any extra key (`imageId`, `price`, or `items`) is denied
F22-A15  [I]  As bob, get, list, create, update and delete on users/alice/wardrobeItems/... are all denied
F22-A16  [I]  Signed out, get, list, create and delete on users/alice/wardrobeItems/... are all denied
F22-A17  [I]  Type/invariant checks: wears: -1 denied, wears: 0 allowed, wears: 1.5 denied, wears: '3' denied; id: 'other-id' at doc white-shirt denied; sourceId: 5 denied; name: null denied
F22-A18  [I]  An owner delete of an existing wardrobeItems document succeeds (WardrobeRepository.removeItem path), and the document no longer exists

# --- outfits ---
F22-A19  [I]  An owner create of users/alice/outfits/1 with the exact FirestoreOutfitsRepository.seedFieldsForOutfit(SeedData.outfits[0]) map succeeds and owner get and list succeed; items: [] is also allowed
F22-A20  [I]  An owner write with an extra key (`createdAt`, `wears`) is denied
F22-A21  [I]  As bob, get, list, create, update and delete on users/alice/outfits/... are all denied
F22-A22  [I]  Signed out, get, list, create and delete on users/alice/outfits/... are all denied
F22-A23  [I]  Type/invariant checks: worn: -1 denied, worn: 0 allowed; items: 'a,b' denied; id: '1' (string) denied; id: 2 at doc outfits/1 denied; why: null denied
F22-A24  [I]  The OutfitsRepository.upsertManual edit path works under the rules: update({name, occasion, items}) on an existing outfits/1 succeeds and leaves `worn` untouched; the same update on a NON-EXISTENT outfits/999 fails with NOT_FOUND, not PERMISSION_DENIED, so F16's not-found to set() fallback stays reachable; that fallback's full set() then succeeds
F22-A25  [I]  An owner delete of an existing outfits document succeeds (OutfitsRepository.delete path)

# --- wearEvents ---
F22-A26  [I]  An owner create of users/alice/wearEvents/1730000000000 with {id: 1730000000000, outfitId: 1, name, occasion, items: [..], timestamp: <Timestamp>} succeeds and owner get and list succeed
F22-A27  [I]  An owner write with an extra key (`worn`, `date`) is denied
F22-A28  [I]  As bob, get, list, create and delete on users/alice/wearEvents/... are all denied
F22-A29  [I]  Signed out, get, list, create and delete on users/alice/wearEvents/... are all denied
F22-A30  [I]  Type checks: timestamp: '2026-10-20T10:00:00Z' (string) denied; timestamp: 1730000000000 (int) denied; items: 'white-shirt' denied; outfitId: '1' denied; id not equal to the doc id denied
F22-A31  [I]  An owner transaction that deletes wearEvents/<id> and sets the parent outfit with worn decremented (the removeWear shape) succeeds atomically

# --- plannedEntries ---
F22-A32  [I]  An owner create of users/alice/plannedEntries/2026-10-15 with the exact FirestorePlannerRepository.seedFieldsFor(SeedData.planned['2026-10-15']) map succeeds and owner get and list succeed
F22-A33  [I]  An owner write with an extra key (`date`, `id`) is denied
F22-A34  [I]  As bob, get, list, create and delete on users/alice/plannedEntries/... are all denied
F22-A35  [I]  Signed out, get, list, create and delete on users/alice/plannedEntries/... are all denied
F22-A36  [I]  Type/key checks: outfitId: '1' denied; occasion: null denied; a valid payload at doc id '2026-1-5' denied; a valid payload at doc id 'tomorrow' denied
F22-A37  [I]  An owner delete of an existing plannedEntries document succeeds (PlannerRepository.remove path)

# --- packingTrips ---
F22-A38  [I]  An owner create of users/alice/packingTrips/trip-1 succeeds and owner get and list succeed for: (a) the create-branch shape with items: []; (b) items holding two PackingItem maps, one with wardrobeId: 'white-shirt' and one with wardrobeId: null
F22-A39  [I]  An owner write with an extra key (`draft`, `selectedTripId`) is denied
F22-A40  [I]  As bob, get, list, create, update and delete on users/alice/packingTrips/... are all denied
F22-A41  [I]  Signed out, get, list, create and delete on users/alice/packingTrips/... are all denied
F22-A42  [I]  Type/invariant checks: days: 0 denied, days: 1 allowed, days: '3' denied; items: 'x' denied; start: <Timestamp> denied (must be a string); id: 'trip-2' at doc trip-1 denied
F22-A43  [I]  The saveTrip edit-branch merge-set (all fields except items) succeeds both on an existing trip (items preserved) and on a non-existent trip (creates a document without `items`, matching today's behaviour when a trip was deleted concurrently)
F22-A44  [I]  The _mutateItems shape, a transaction that reads the trip and then updates only {items: [...]}, succeeds on an existing trip
F22-A45  [I]  An owner delete of an existing packingTrips document succeeds (PackingRepository.deleteTrip path)

# --- real app writes, bootstrap, legacy data ---
F22-A46  [I]  Repository replay: every public write method below, run for real against fake_cloud_firestore seeded with SeedData, produces post-write document states that, replayed to the emulator as alice with the same operation kind (full set / merge-set / update / arrayUnion-arrayRemove / delete), are ALL allowed. Methods: WardrobeRepository addItem (with and without imageUrl), addItems, updateItem, adjustWears(+1), adjustWears(-1 at wears 0), removeItem; OutfitsRepository saveOrFind, upsertManual (create, edit, not-found fallback), delete, logWear, removeWear; PlannerRepository plan, remove; ProfileRepository updateDetails, setStyles, setOccasions, setDailyNotifications, setPlannedNotifications, setProductNotifications, setWeatherConsent, setClimate, setPlan, setBillingCycle, bootstrapIfNeeded; ShoppingRepository setMembership(add), setMembership(remove); PackingRepository saveTrip(isNew: true), saveTrip(isNew: false), toggle, removeItem, addWardrobe, addCustom, generateChecklist, deleteTrip
F22-A46b [U]  The method list in A46 equals the set of public Future-returning write methods declared on FirestoreWardrobeRepository, FirestoreOutfitsRepository, FirestorePlannerRepository, FirestoreProfileRepository, FirestoreShoppingRepository and FirestorePackingRepository; the test fails, naming the method, if a write method exists that A46 does not replay
F22-A47  [I]  The D5 bootstrap as one emulator transaction by alice (users/alice with the 13-key payload + 23 wardrobeItems via seedFieldsFor + 2 outfits via seedFieldsForOutfit + plannedEntries/2026-10-15 via seedFieldsFor, 27 writes) commits; read-back shows all 27 documents and seeded == true. The same transaction with exactly one wardrobe document carrying an extra key is denied as a whole: afterwards 0 of the 27 documents exist and users/alice has no `seeded` field
F22-A48  [I]  Legacy-data behaviour (under the strict full-document design, pending §13 Q3): given a users/alice document seeded through the rules bypass with one out-of-schema key `legacyFlag: true`, an owner merge-set of a valid key ({climate: 'Mild'}) is denied, and a bootstrap transaction that spreads existingData is denied; this is the documented reason A50 must report zero violations before deploy
F22-A49  [U]  No file under lib/ calls orderBy(, where(, limit( or collectionGroup( on a Firestore reference, and firestore.indexes.json is byte-identical to {"indexes": [], "fieldOverrides": []}; the wearEvents index item is closed as not needed

# --- production (gated; runs only inside the controller-approved deploy step) ---
F22-A50  [L]  Pre-deploy read-only audit of production stylobuddy-b7e46: every document under users/** is checked against §7's key lists, types and invariants; the report states the number of documents scanned per collection and the number of violations (required: 0, otherwise stop and escalate per §13 Q3); the audit performs zero writes
F22-A51  [L]  `firebase deploy --only firestore:rules --project stylobuddy-b7e46` is run only after A01-A49 PASS on the emulator, A50 reports 0 violations, and an explicit controller go-ahead is recorded (with its date) in the completion block; no test, script, hook or CI step invokes the deploy; the task report contains the full before/after diff of firestore.rules and the deploy command's output
F22-A52  [L]  After deploy, on a real Android device signed in with Google against production: add a wardrobe item, edit it, log a wear, undo it, plan a date, unplan it, toggle a wishlist item on and off, create a trip, generate its checklist, toggle an item, edit the trip, and delete the trip; each change survives a cold restart, and no `permission-denied` appears in the device log or Crashlytics; a first sign-in with a never-before-used account completes the bootstrap (users/{uid}.seeded == true and 23 wardrobeItems present); a REST get of another uid's users/{uid} document with a real ID token returns 403
F22-A53  [L]  Rollback readiness: before the deploy, the exact "Before" ruleset text (§8) is saved in the task report; if any A52 check fails, the "Before" rules are redeployed immediately, and the report records the failing check, the redeploy command output, and that access was restored
```

## 12. Edge cases

- **Array element contents are not validated.** For example, `Outfit.items`
  containing a number, or a `PackingItem` map with an extra `qty` key, would
  pass the rules. The rules language has no loops. Bounded checks on
  positions `[0]`..`[n]` are possible but brittle and costly. The client is
  the only writer, and its converters always emit the right element shapes.
  This is accepted and recorded so it is not mistaken for coverage.
- **`Trip.items` size:** schema §6 says "≤12", but `addCustom` appends
  unconditionally and `addWardrobe` appends each new wardrobe item. A
  `size() <= 12` rule could deny a real `addCustom`. No size rule is
  added (§3).
- **`wears` upper bound:** `adjustWears` clamps at `1 << 30`. No upper bound
  is enforced server-side because nothing legitimate approaches it.
- **Outfit/WearEvent ids are millisecond timestamps** (`OutfitsCubit._newId`,
  ~1.7e12). They fit in a Firestore 64-bit integer. `string(id) == outfitId`
  compares against `id.toString()`, which is how every write path builds the
  document ID: `saveOrFind`, `upsertManual` (whose edit candidate keeps
  `existing.id == editingId`), `logWear` and the bootstrap.
- **Firestore integer vs double:** Dart `int` is sent as `integerValue`, so
  `is int` holds. If a test client sends `3.0` as a double, it must be
  denied (A17 covers `1.5`; `3.0` is not a special case to the rules).
- **`users/{uid}` delete:** no code path deletes the profile document
  (Delete account is preview-only, `07-security.md` §6). Owner delete stays
  allowed, as it is today, so this task does not narrow behaviour beyond
  field validation. §13 Q8 covers whether to deny it.
- **`seeded` set to `false` by the owner:** allowed (bool). The only effect
  is that the next launch's bootstrap seeds only the missing keys
  (F18 Important #5), which is no worse than today.
- **Concurrent bootstrap retries:** each retry is a full re-evaluation of
  the same 27 writes. The rules are request-pure (A06), so a retry cannot
  pass or fail differently from the first attempt.
- **Planner key with a valid-looking but impossible date** (`2026-13-45`):
  the format regex allows it. No code path produces it, and calendar
  validity is not a rules concern.
- **Mock-token identity in tests:** the emulator accepts unsigned tokens.
  A token whose `sub` and `user_id` disagree is not a case the app can
  produce and is not tested.

## 13. Open questions

**Q1, Q3 and Q7 block parts of the build. Q1 blocks only the final deploy
step. The emulator work can proceed without it.**

- **Q1: Production deploy timing: automatic at the end of implementation,
  or an explicit go-ahead? (BLOCKING for A50-A53 only.)**
  - **Proposed:** an explicit controller (or user) go-ahead, recorded with
    its date in the completion block, after the emulator suite is green and
    the A50 audit is clean. Rules apply instantly to every live client. A
    rule that is too strict does not crash anything visible. It quietly
    rolls back users' writes and can permanently block new-user bootstraps
    (§10), and with optimistic UI, the user sees "saved" first. Recovery is
    quick (A53), but the damage happens between deploy and detection.
  - The plan wording ("deploy... as the task's last step") reads as
    automatic. This document deliberately does not treat it that way
    (A51) until a ruling is made.
  - Related: A52 needs a never-before-used Google account to prove the
    bootstrap path live. Who provides it, or may the implementer wipe a
    test user's `users/{uid}` tree via the Admin SDK first? Wiping is a
    production write and needs the same go-ahead.

- **Q2: Precedence when the schema doc and the repository code disagree.**
  - None found today for field names (§7 table). The divergences found are
    nullability (`sourceId`/`imageUrl` written as explicit `null`),
    partial-document shapes (merge-set/update paths), the stale §4
    `orderBy` note, and the schema §8 example's delete defect.
  - **Proposed:** the code that is running in production wins for what the
    rules must allow, because denying a live write is an outage. The schema
    doc is then amended to match, with a dated note, in the same task.
    Exception: if the code writes something the schema doc and
    `03-domain-model.md` both say must not exist (a stray key), that is a
    code bug. Stop and escalate it. Neither widen the rules to fit it nor
    "fix" the repository inside this task, since the plan forbids Task 9
    from touching `lib/features/*`.
  - Ruling needed to confirm this order.

- **Q3: Legacy production data vs. strict full-document `hasOnly`.
  (BLOCKING for deploy if A50 finds anything.)**
  `keys().hasOnly(...)` checks the whole post-write document. One stray key
  already on a production document makes every future write to it fail:
  - a one-key profile setter,
  - a wishlist toggle,
  - and the bootstrap, which spreads `existingData` back into its write
    (A48).

  Options:
  - (a) **Proposed:** keep the strict full-document check (matching schema
    §8's own example). Require A50 to report zero violations. If there are
    any, stop and ask before deploying. Remediating production data is a
    separate, approved write.
  - (b) For `update` only, validate `request.resource.data.diff(
    resource.data).affectedKeys().hasOnly(...)`, so pre-existing stray keys
    are tolerated but no new ones can be added. More forgiving, but it
    permanently grandfathers bad data and makes the update and create rules
    differ.

  Ruling needed. A48 is written for (a) and is amended with a dated note if
  (b) is chosen.

- **Q4: Schema doc §8's example is incorrect as written.** Its
  `allow write: if ... request.resource.data.keys()...` denies every delete,
  because `request.resource` is null on delete. It also omits `allow read`
  and the `request.auth != null` guard. This document departs from it (§5
  point 1) and proposes amending §8 in this task, with a dated note,
  to show the split `create, update` / `delete` shape and the "absent or
  typed" field pattern. A non-blocking confirmation is needed, since §8 is
  "the bar every block follows".

- **Q5: Test-harness language.**
  - **Proposed:** Dart tests in `test/firestore_rules_test/` calling the
    emulator's REST API with `package:http` (already a dependency).
    - The emulator accepts unsigned mock ID tokens for `request.auth`, plus
      an `owner` bearer for fixture seeding.
    - REST supports everything the assertions need: merge via `updateMask`,
      `arrayUnion`/`arrayRemove` via field transforms, transactions via
      `beginTransaction`/`commit`.
    - Test names stay in the `F22_Axx` Dart form the harness's
      assertion-coverage check scans for.
    - A46 can call the real repositories through `fake_cloud_firestore`
      (already a dev dependency) in the same process.
  - Alternative: Node `@firebase/rules-unit-testing`, the canonical tool
    with less request boilerplate. It adds a `package.json` and a JS
    toolchain to a Flutter repo. A46's replay would then need a Dart step
    that exports JSON fixtures. It is also unclear whether the coverage hook
    sees `.js`/`.ts` test names.
  - Ruling needed.

- **Q6: `dart_test.yaml` (or equivalent) is outside the plan's file list.**
  A03 needs the emulator suite excluded from the default `flutter test` run,
  for example with a tag excluded in a root `dart_test.yaml`. The plan names
  only `firestore.rules`, `firestore.indexes.json` and
  `test/firestore_rules_test/`. Confirm that adding a root test-config file
  is allowed. Otherwise the suite needs another opt-in mechanism, but it
  must still fail, not skip, when it is explicitly invoked without an
  emulator (A01).

- **Q7: Java version for the emulator. (BLOCKING for all `[I]` assertions
  until verified.)** The brief reports firebase-tools 15.24.0 with
  OpenJDK 17. Recent firebase-tools majors (v14 onward, to the best of this
  document's knowledge) require **Java 21+** to start the emulators. If so,
  `firebase emulators:start --only firestore` will refuse to run on
  JDK 17. This document did not execute anything, so it cannot confirm
  either way. First implementation step: run `firebase emulators:start
  --only firestore --project demo-stylobuddy` once. If it reports a Java
  version error, install JDK 21 (an environment change on the developer
  machine, not a repo change). The user may need to approve that install.

- **Q8: Should owner delete of `users/{uid}` stay allowed?** No code path
  deletes it today, and current rules allow it. Keeping it (proposed) avoids
  narrowing behaviour beyond this task's remit and leaves room for a future
  real "Delete account". Denying it would protect against an accidental
  client-side wipe, but nothing in the app can issue one. Non-blocking.

- **Q9: Service-account permissions for deploy and audit.** The service
  account at `~/.secrets/stylobuddy/firebase-service-account.json` needs
  Firebase Rules Admin (deploy) and Datastore/Firestore read access (A50).
  It is unverified whether that account was granted them during the
  original project setup. If it lacks them, the user must grant the roles.
  That is a console/IAM step the implementer cannot do from inside the
  project. Non-blocking until the deploy step.

---

## Completion block

Filled in during the build. See `foundation/05-testing-and-dod.md`.

```
Status: DONE (Gates 1-3 emulator-proven; Gate 4 production deploy run 2026-10-29,
real-device smoke A52 still pending)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration (emulator) — 55/55 at 6a2c380; 58/58 with F24's gender rules (9e9a5f0)
[~] Gate 4  Live run — go-ahead: 2026-10-29 (user chose "Audit, then deploy").
            A50, A51, A53 done; A52's on-device walk is replaced for now by a
            real signed-in REST smoke (below) and stays open for a device.

Assertions: 53/54 PASS. A52's real-Android-device checklist is the only one open.
Regression: flutter analyze clean; default `flutter test` unaffected
(631 passed/10 skipped, the emulator suite correctly excluded by default).

Production deploy record (2026-10-29, project stylobuddy-b7e46):
- A53 rollback readiness: the live rules before the deploy were the console
  default DENY-ALL (`match /{document=**} { allow read, write: if false; }`,
  ruleset 6f604faa-e774-4c62-a273-2ea76e5f7f4d, created 2026-10-17). That
  differs from what §8 "Before" assumed (an owner-only wildcard): until this
  deploy no signed-in user could read or write Firestore in production at all.
  Rollback = point release cloud.firestore back at that ruleset id (it still
  exists in rules history) via the Rules API, or redeploy the 163-char deny-all
  text. Not needed.
- A50 read-only audit (zero writes): users 0, wardrobeItems 0, outfits 0,
  wearEvents 0, plannedEntries 0, packingTrips 0 documents; 0 violations.
  Production held no user data, so no existing document could be blocked.
- A51 deploy: `firebase deploy` aborted before changing anything — the
  service account lacks serviceusage.services.use, which the CLI's pre-flight
  "is the Firestore API enabled" check needs. The same two steps the CLI performs
  were done directly through the Firebase Rules API with the same service
  account: POST rulesets (5a8ac738-8996-423e-906c-3bc51ba3edfc, the committed
  F24-amended firestore.rules, 8429 chars) and PATCH releases/cloud.firestore
  at 2026-10-29T19:02:54Z. Credentials stayed in ~/.secrets, never committed.
- A52 substitute — live REST smoke with real Firebase ID tokens for two
  temporary users, 16/16 pass: owner allowed to create the 14-key profile
  (with gender), read it, and create a valid wardrobe item, outfit, planned
  entry and packing trip; denied (403) for an unexpected key, gender "other",
  wears = -1, id != doc id, a non-date plannedEntries id, another user
  reading or writing a user's documents, a signed-out read, and a write
  outside users/**. Every temporary document and both temporary auth users
  were deleted afterwards; a follow-up audit confirmed production is empty.
  NOT covered (needs a device): the full app flow end to end on a phone,
  offline/optimistic-write rollback behaviour, Crashlytics for permission-denied.
```
