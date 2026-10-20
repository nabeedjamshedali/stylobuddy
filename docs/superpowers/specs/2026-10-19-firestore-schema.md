# Firestore Schema — Milestone 2

> Field names and types match `docs/foundation/03-domain-model.md` exactly
> per that document's own rule ("feature documents and code use these names
> exactly"). This doc is the data-changes section (`foundation template §8`)
> shared across every backend-wiring feature document, referenced rather
> than repeated.

Database: `stylobuddy-b7e46`, Firestore Native mode, region `nam5`
(already created). All paths below are under one root per user:

```
users/{uid}                              # doc = ProfileState fields, flat
  .seeded: bool                          # true once D5 bootstrap has run
users/{uid}/wardrobeItems/{itemId}       # itemId = ClothingItem.id (String)
users/{uid}/outfits/{outfitId}           # outfitId = Outfit.id.toString()
users/{uid}/wearEvents/{eventId}         # eventId = WearEvent.id.toString()
users/{uid}/plannedEntries/{dateKey}     # dateKey = 'yyyy-MM-dd', PlannerState.planned's existing Map key
users/{uid}/packingTrips/{tripId}        # tripId = Trip.id (String, unchanged)
```

No other top-level collections. `ShoppingCatalog` and onboarding copy are
not stored here (D1 — bundled app config, not user data).

## 1. `users/{uid}` (profile document)

| Field | Type | Notes |
|---|---|---|
| `name` | string | |
| `email` | string | mirrors `FirebaseAuth.currentUser.email` at sign-in; not re-read from Auth on every load |
| `styles` | array\<string\> | |
| `occasions` | array\<string\> | |
| `dailyNotifications` | bool | |
| `plannedNotifications` | bool | |
| `productNotifications` | bool | |
| `weatherConsent` | bool | |
| `climate` | string | |
| `plan` | string | |
| `billingCycle` | string | |
| `wishlist` | array\<string\> | **new** — moved here from a would-be `shopping` subcollection; it's a handful of `ShopEntry.id` strings, an array field is simpler than a subcollection for this size (D-call, see plan Task 6) |
| `seeded` | bool | **new**, infra-only, not part of `ProfileState` — set `true` by the D5 bootstrap, read once at sign-in to decide whether to seed |

`ProfileRepository.watchProfile()` excludes `seeded` from the `ProfileState`
it emits (infra field, not a domain field — do not add it to
`03-domain-model.md`'s `ProfileState` entry).

## 2. `users/{uid}/wardrobeItems/{itemId}`

| Field | Type | Notes |
|---|---|---|
| `id` | string | == doc ID, duplicated on the document for query/export convenience (standard Firestore pattern — cheap, avoids a second round trip to learn an item's own id) |
| `name` | string | |
| `category` | string | |
| `color` | string | |
| `occasion` | string | |
| `season` | string | |
| `wears` | int | |
| `sourceId` | string? | unchanged — still resolves bundled art for seed/demo items |
| `imageUrl` | string? | **new** — Supabase Storage path (`{uid}/{itemId}.jpg`), set only when the user uploaded a real photo (see `supabase-storage-and-functions.md`). As of Task 2, `user-photos` is a private bucket, so this is a storage path, not yet a fetchable URL — a signed read URL (or a public bucket) must be added before `GarmentImage` can prefer this over `sourceId`/`imageId` resolution. Falls back to the existing bundled-art logic when null. Added to `03-domain-model.md`'s `ClothingItem` entry as part of Task 2. |

## 3. `users/{uid}/outfits/{outfitId}`

| Field | Type | Notes |
|---|---|---|
| `id` | int | duplicated on the doc (see §2 rationale) |
| `name` | string | |
| `occasion` | string | |
| `why` | string | |
| `items` | array\<string\> | `ClothingItem` ids, order significant — preserved as Firestore array order |
| `worn` | int | |

## 4. `users/{uid}/wearEvents/{eventId}`

| Field | Type | Notes |
|---|---|---|
| `id` | int | duplicated on doc |
| `outfitId` | int | |
| `name` | string | |
| `occasion` | string | |
| `items` | array\<string\> | snapshot at wear time, per existing semantics — never re-derived from the live outfit |
| `timestamp` | Firestore Timestamp | maps to `DateTime` via `cloud_firestore`'s built-in conversion |

**2026-10-20 (F22/Task 9):** stale note corrected — `watchWearEvents()`
issues no `orderBy` at all; it is a bare `snapshots()` on the collection,
sorted client-side in Dart (newest-first, tie-broken by id descending),
matching `OutfitsCubit.wearEvents()`'s existing sort. No index of any kind
is needed for this collection (confirmed F22-A49; see §8 below and
`docs/features/F22-firestore-rules-hardening.md` §8).

## 5. `users/{uid}/plannedEntries/{dateKey}`

| Field | Type | Notes |
|---|---|---|
| `outfitId` | int | |
| `occasion` | string | |

Doc ID is the `'yyyy-MM-dd'` key itself — no separate `date` field needed,
same as today's `Map<String, PlannedEntry>` key.

## 6. `users/{uid}/packingTrips/{tripId}`

| Field | Type | Notes |
|---|---|---|
| `id` | string | duplicated on doc |
| `name` | string | |
| `destination` | string | |
| `start` | string | `'yyyy-MM-dd'`, unchanged (not a Timestamp — the existing code treats these as sortable strings, not dates to compute with beyond `_daysBetween`; converting to Timestamp would be scope creep for this phase) |
| `end` | string | |
| `type` | string | |
| `notes` | string | |
| `days` | int | |
| `items` | array\<map\> | each map = one `PackingItem` (`key`, `label`, `wardrobeId`, `packed`) — embedded, not a sub-subcollection. A trip's item list is small (≤12 per F10's own cap logic) and always read/written as a whole with its trip, so embedding avoids N+1 reads with no query need ever requiring items independent of their trip. |

`TripDraft` is never persisted (confirmed transient in the inventory) — it
stays a pure in-memory form mirror in `PackingCubit`.

## 7. What's explicitly excluded (transient Cubit state — do NOT add a repository method or collection for these)

Per the inventory's "cross-cutting flags," these stay exactly as in-memory
`Cubit` fields with no backing store, in both guest and signed-in mode:

- `WardrobeBrowseState.{filter,search}`, `ImportState` (all — it's a wizard
  scratch pad; only its *result*, via `WardrobeRepository.addItem`, persists)
- `SavedViewState.{tab,search}`
- `PlannerState.{year,month,day,editingOutfitId,editingOccasion}`
- `StylistState` (all — a generation session; only a save via
  `OutfitsRepository` persists)
- `BuilderState` (all — a draft; only `save()` via `OutfitsRepository`
  persists) and `BuilderSaveResult` (pure UI feedback DTO)
- `ShoppingState.{tab,selectedId}` (only `wishlist` persists, as `users/{uid}.wishlist`)
- `PackingState.{selectedTripId,draft}`
- `AuthState` (all — form/validation UI state; `email` already comes from
  `FirebaseAuth.currentUser`, never a separate store)
- `OnboardingState` (all — one-shot flow state; its *result* feeds the D5
  bootstrap's profile seed, per Task 5, not its own store)

## 8. Security rules (extends `firestore.rules`)

**2026-10-20 (F22/Task 9): done, corrected.** The example below as
originally written used a single `allow write: if ... request.resource.data
.keys()...` clause. That denies every delete outright, because
`request.resource` is `null` on a delete request, and it omitted the
`request.auth != null` guard and `allow read`. `firestore.rules` now splits
`delete` into its own clause (ownership only) from `create`/`update` (owner
+ field validation), and every field check is "absent, or correctly typed"
— never `hasAll` — because several real write paths legitimately produce
partial documents (profile merge-sets before bootstrap, `saveTrip`'s edit
branch, `upsertManual`'s edit branch needing a real `NOT_FOUND`). Full
rationale, the six implemented blocks, and the emulator-proven assertions
are in `docs/features/F22-firestore-rules-hardening.md` §5/§7/§11.

```
match /users/{uid}/wardrobeItems/{itemId} {
  function isOwner() { return request.auth != null && request.auth.uid == uid; }

  allow read, delete: if isOwner();
  allow create, update: if isOwner()
    && request.resource.data.keys().hasOnly(
         ['id','name','category','color','occasion','season','wears','sourceId','imageUrl'])
    && (!('id' in request.resource.data)
        || (request.resource.data.id is string && request.resource.data.id == itemId))
    && (!('wears' in request.resource.data)
        || (request.resource.data.wears is int && request.resource.data.wears >= 0))
    // sourceId/imageUrl are the one place explicit `null` is accepted —
    // every other field in this document rejects it.
    && (!('sourceId' in request.resource.data)
        || request.resource.data.sourceId == null
        || request.resource.data.sourceId is string);
}
# ...one analogous block per collection in §2-6, each checking its own
# field set and the invariants already enforced client-side today
# (e.g. outfits.worn >= 0, wearEvents.items is a list).
```

This section fixes the *shape* every block follows; the live
`firestore.rules` is the source of truth for the exact, current field sets.
