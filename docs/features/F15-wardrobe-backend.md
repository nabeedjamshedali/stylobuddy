# F15 — Wardrobe Backend

> Gives a signed-in user real Firestore persistence for their wardrobe and a real
> camera/gallery photo flow that uploads to Supabase Storage, swapping
> `lib/features/wardrobe/repository/wardrobe_repository.dart` from a single
> in-memory class into the dual-mode pattern (`InMemoryWardrobeRepository` /
> `FirestoreWardrobeRepository` behind one interface) — Task 2 of
> `docs/superpowers/plans/2026-10-19-backend-wiring.md`. Zero widget redesign,
> zero change to guest ("Skip for now") wardrobe behavior. Depends on F14
> (`uidChanges()`, `FirestoreService`, the auth-gated `StreamBuilder` in
> `lib/app.dart`) and F06 (the existing `WardrobeCubit`/`ImportCubit` method
> surface this task sits behind). Grounded in
> `docs/superpowers/specs/2026-10-19-backend-architecture.md` (D2, D4, D5, D6,
> D7), `docs/superpowers/specs/2026-10-19-firestore-schema.md` §2, and
> `docs/superpowers/specs/2026-10-19-supabase-storage-and-functions.md` §1-2.

**Status:** DONE (Gates 1-3 closed; Gate 4 — A26 `[L]` live device run — pending) · **Milestone:** 2 · **Depends on:** F06, F14

---

## 1. Goal

Let a signed-in user's wardrobe — items added, edited, removed, worn — survive a
cold restart and a different device, by writing it to
`users/{uid}/wardrobeItems/{itemId}` instead of holding it only in
`WardrobeCubit`'s in-memory state. Let a signed-in user attach a real photo
(camera or gallery) to an item they import, stored in Supabase Storage and
referenced by a `imageUrl` on the Firestore document. A guest gets none of
this and sees exactly what the current `flutter test` suite already verifies
(F06) — no network call, no new failure mode, same seed data every launch.

## 2. MVP scope

- `lib/features/wardrobe/repository/wardrobe_repository.dart`: `WardrobeRepository`
  becomes an **abstract** interface (today it is one concrete class with only
  `loadItems()`). Interface methods mirror the write operations
  `WardrobeCubit` already performs directly on its own state today
  (`addItems`, `updateItem`, `removeItem`, `adjustWears`), plus a singular
  `addItem` for the photo-upload-then-save path (see §5/§13 — the storage
  spec names this method singular; the existing Cubit-level method is plural
  batch-only, reconciled below), and a `watchItems()` stream read per
  architecture D6.
- `InMemoryWardrobeRepository`: today's `SeedData.items` behavior moved
  behind the interface verbatim — same seed list, same synchronous-feeling
  writes (a `Future` that completes already-resolved), no network call ever
  constructed on this branch. Used for guests, unchanged from today's
  `WardrobeRepository`.
- `FirestoreWardrobeRepository`: real reads/writes under
  `users/{uid}/wardrobeItems/{itemId}` (schema doc §2) — `itemId` is
  `ClothingItem.id` verbatim (already a `String`, D4; no type change, no
  re-mapping). `watchItems()` wraps `snapshots()`; writes are `Future<void>`.
- `lib/app.dart`: `WardrobeCubit`'s construction becomes the **first** real
  dual-mode swap under Task 1's `StreamBuilder` — in-memory for `uid == null`,
  Firestore for `uid != null` — resolving F14 §13's open question that no
  root Cubit yet had a real repository swap (F14-A05/A06 tested the
  reconstruction mechanism only, not a repository choice).
- `lib/shared/backend/storage_repository.dart`: `Future<String> uploadWardrobePhoto({required String itemId, required XFile file})` —
  calls the Edge Function for a signed URL, `PUT`s the bytes with
  `package:http`, returns the resulting URL.
- `supabase/functions/storage-upload-url/index.ts`: real and deployed this
  task — verifies the caller's Firebase ID token, returns a signed upload
  URL scoped to `{firebaseUid}/{itemId}.jpg`. Storage doc §1 originally
  named a 60-second expiry; as resolved in §13a below, Supabase's
  `createSignedUploadUrl` API does not support a caller-supplied expiry for
  upload URLs — the live function uses the service's own fixed window
  (confirmed ~2 hours).
- `supabase/functions/_shared/firebase-auth.ts`: `verifyFirebaseToken(req)` —
  JWT verification against Firebase's published JWKS (cached), written this
  task, reused unmodified by Task 10's `ai-stylist` stub.
- `ImportCubit` gains a real picked-file path: `image_picker` opens the
  camera/gallery, the picked `XFile` becomes part of the current draft; on
  the batch-completing save, a draft with a real picked file is uploaded via
  `uploadWardrobePhoto` before the resulting `ClothingItem` (now carrying
  `imageUrl`) reaches `WardrobeRepository`. A draft with no picked file (the
  existing simulated/demo path, F06's `sourceId`-based pool images) is
  **unchanged** — not deleted, kept as the fallback.
- `ClothingItem` gains `imageUrl: String?` (schema doc §2; added to
  `docs/foundation/03-domain-model.md`'s `ClothingItem` entry as part of this
  task, per the plan's "foundation docs updated by the task that changes the
  reality" rule).
- `pubspec.yaml`: adds `image_picker`; adds `http` if not already present.

## 3. Later scope

- `GarmentImage` (`lib/shared/widgets/garment_image.dart`) actually rendering
  `imageUrl` instead of only bundled asset art — **explicitly not done this
  task**; see §13, this is a real gap, not an oversight.
- Background removal / AI tagging stays the existing simulated pipeline
  (`/analyzing`'s 1150 ms delay, F06) — this task only replaces the storage
  layer under the existing simulated review flow, it does not add real
  image processing.
- `clothing-catalog` public bucket — reserved, unused (architecture D7).
- Retrying a failed photo upload automatically, or a background upload
  queue — out of scope; a failed upload today just means `imageUrl: null`
  forever for that item unless the user re-triggers an upload through a
  future edit flow (not built here).
- `ai-stylist` Edge Function (Task 10) — `firebase-auth.ts` is written here
  but only consumed by `storage-upload-url` in this task.
- Firestore security rules for `wardrobeItems` (Task 9).

## 4. Roles and permissions

Reuses `docs/foundation/07-security.md`'s guest/authenticated roles, made
concrete the same way F14 made it structural: `uid == null` →
`InMemoryWardrobeRepository`, zero Firestore/Storage calls, ever; `uid !=
null` → `FirestoreWardrobeRepository`, scoped to that `uid`'s own subtree via
`FirestoreService.subcollection` (F14-A11 — paths are always
`users/<uid>/wardrobeItems`, never a cross-user or top-level path). The
`storage-upload-url` function is the only place a new permission check is
introduced: it requires a valid Firebase ID token in the `Authorization`
header and signs a URL scoped to that token's own `uid` — it never accepts a
client-supplied `uid` or `itemId`-only request without a token.

## 5. Main flows

```text
Guest adds an item (import flow, no picker used):
  /import -> pick camera|gallery source -> /import-source -> /batch -> /analyzing
  -> /review (per draft) -> last draft "Save to my wardrobe ->"
  -> ImportCubit builds ClothingItem drafts (sourceId-based pool art, imageUrl
     never set) -> InMemoryWardrobeRepository.addItems(drafts) resolves
     immediately -> WardrobeCubit optimistically updates state -> /add-confirm
  (identical to today's F06 flow; no network call constructed)

Signed-in user adds an item with a real picked photo:
  /import -> camera|gallery -> image_picker returns an XFile -> draft carries
     the XFile (not yet uploaded) -> user reviews/edits fields -> last draft
     confirmed
  -> for each draft with a picked file: uploadWardrobePhoto(itemId: draft.id,
     file: xfile) -> storage-upload-url Edge Function verifies the caller's
     Firebase ID token -> signed URL (~2 hour expiry, Supabase's fixed
     window for upload URLs — see §13a) -> Flutter PUTs the bytes
     directly to that URL -> uploadWardrobePhoto resolves with the storage
     path (not a fetchable URL — the `user-photos` bucket is private, see
     §13a)
  -> the draft's ClothingItem is saved with imageUrl set to that path via
     FirestoreWardrobeRepository.addItem/addItems
  -> WardrobeCubit optimistically updates state; the Firestore snapshot
     listener later reconciles the same document -> /add-confirm

Signed-in user adds an item, upload fails (network, expired signed URL,
Edge Function down, or missing/invalid Firebase token mid-flow):
  -> uploadWardrobePhoto's Future completes with an error (or the Edge
     Function's non-200 response surfaces as one)
  -> the draft's ClothingItem is still saved via
     FirestoreWardrobeRepository.addItem/addItems, with imageUrl: null
  -> the save is never delayed past the upload attempt and never fails as a
     whole because the photo step failed -> a toast/error signal is
     surfaced (mechanism: see §13, open question) -> /add-confirm proceeds
     exactly as the no-photo path

Edge Function, storage-upload-url, called directly:
  request with a valid Firebase ID token -> verifyFirebaseToken succeeds
  -> service-role createSignedUploadUrl() scoped to
     {firebaseUid}/{itemId}.jpg -> 200 with the signed URL, Supabase's fixed
     ~2 hour upload-URL expiry (see §13a — not a caller-configurable 60s)
  request with a missing or invalid/expired token -> verifyFirebaseToken
  fails -> 401, no signed URL ever generated

Bootstrap-seeding re-verification (Review Focus item 4, wardrobe-specific):
  a brand-new signed-in user's wardrobeItems subcollection is empty
  -> FirestoreWardrobeRepository.watchItems() simply reflects "empty" as its
     first snapshot; WardrobeCubit's construction performs zero writes of
     its own (it only subscribes to the stream) -> whichever task owns the
     real seedWriter (F14 mechanism; F14 §13 names Task 5 as the first real
     caller) commits wardrobeItems exactly once, guarded by the users/{uid}
     .seeded transaction -> even if WardrobeCubit's stream subscription and
     the bootstrap transaction race on the same cold start, the wardrobe
     path contributes no competing write, so no double-seed is possible
     from this task's code
```

## 6. Interface surface

```text
abstract class WardrobeRepository
  Stream<List<ClothingItem>> watchItems()                          both impls
  Future<void> addItem(ClothingItem item)                          both impls
  Future<void> addItems(List<ClothingItem> items)                  both impls
  Future<void> updateItem(ClothingItem item)                       both impls
  Future<void> removeItem(String id)                               both impls
  Future<void> adjustWears(List<String> ids, int delta)            both impls

class InMemoryWardrobeRepository implements WardrobeRepository       guest mode
class FirestoreWardrobeRepository implements WardrobeRepository      signed-in mode

Future<String> StorageRepository.uploadWardrobePhoto(
    {required String itemId, required XFile file})                lib/shared/backend/storage_repository.dart

Deno.serve handler at supabase/functions/storage-upload-url/index.ts
  POST (Authorization: Bearer <firebase-id-token>) -> 200 {uploadUrl, path}
  POST (missing/invalid token)                      -> 401

async function verifyFirebaseToken(req: Request): Promise<string | null>
  supabase/functions/_shared/firebase-auth.ts                      shared, reused by Task 10
```

`WardrobeCubit`'s own public method names/signatures are unchanged in shape
(`addItems`, `updateItem`, `removeItem`, `adjustWears`, `itemOrFallback`);
only what is behind them changes from direct state mutation to
"await the repository Future, then optimistically update local state"
(architecture D6). `ImportCubit.confirmCurrent`'s synchronous validation
return (`String?` for a blank name) is unchanged; see §13 for the open
question on how the *async* upload-failure signal is surfaced, since that is
new.

## 7. Domain model usage

`ClothingItem` gains `imageUrl: String?` (schema doc §2). All other
`ClothingItem` fields (`id`, `name`, `category`, `color`, `occasion`,
`season`, `wears`, `sourceId`) are read/written unchanged. `imageId` (the
existing getter `sourceId ?? id`) is unchanged — this task does not make
`imageUrl` part of that resolution chain inside the model or any widget (see
§13). `docs/foundation/03-domain-model.md` is updated to add the `imageUrl`
field to the `ClothingItem` entry as part of this task, per the plan's rule
that the foundation doc is updated by the task that changes the reality it
describes.

## 8. Data changes

- Firestore: `users/{uid}/wardrobeItems/{itemId}` collection, fields per
  schema doc §2 (`id`, `name`, `category`, `color`, `occasion`, `season`,
  `wears`, `sourceId`, `imageUrl`). No `firestore.rules` change this task
  (Task 9 owns that file; today's `users/{uid}/{document=**}` owner-only
  default-deny already covers this path at the auth-isolation level, just
  without field-level validation yet).
- Supabase Storage: `user-photos` bucket (already created, private),
  `{firebaseUid}/{itemId}.jpg` paths, written only via the signed URL the
  Edge Function issues — no direct client write with the anon key, ever
  (storage doc §1). Bucket RLS stays deny-all for anon/authenticated roles;
  reads rely on the returned URL being opaque/unguessable, not a policy.
- No migration: existing Firestore wardrobeItems documents do not exist yet
  (this is the task that first creates them); no backfill is needed.

## 9. Background work and events

- The photo upload is a one-shot `Future`, not a retried/queued background
  job — if it fails, the task does not schedule a retry; the item is saved
  with `imageUrl: null` permanently until some future edit flow re-uploads
  (later scope, §3).
- No Cloud Function, no scheduled job triggered by this task. The
  `storage-upload-url` Edge Function is synchronous request/response, not a
  background worker.
- `watchItems()`'s Firestore `snapshots()` listener is long-lived for the
  life of the signed-in `WardrobeCubit` instance; it is torn down (per F14
  D3) on every sign-out/sign-in transition along with the rest of the
  subtree, never left subscribed past its Cubit's `close()`.

## 10. Degradation and failure

- Upload failure (network, expired signed URL, Edge Function down, invalid
  token) never blocks or fails the item save — the save proceeds with
  `imageUrl: null`, matching the existing "never crash" failure philosophy
  (`02-architecture.md` §5) and Review Focus item 3.
- `storage-upload-url` called with a missing or invalid/expired Firebase ID
  token returns `401` and issues no signed URL — never a silently-scoped
  URL for an unverified caller.
- A signed URL's expiry (Supabase's fixed ~2 hour window for upload URLs,
  not the originally-planned caller-configurable 60 seconds — see §13a)
  lapsing before the client `PUT`s (extremely slow network): the `PUT`
  fails, treated identically to any other upload failure — `imageUrl: null`,
  save proceeds, toast surfaced.
- Guest mode (`InMemoryWardrobeRepository`) makes zero Firestore or Supabase
  calls — structurally, not "falls back after a failed call," the same
  guarantee F14 established for the shared infra layer.
- `FirestoreWardrobeRepository.watchItems()` losing its network connection
  mid-session: Firestore's SDK-level offline cache/reconnect behavior
  applies (not a behavior this task adds or suppresses); whether writes
  made while offline are queued by the SDK's default persistence or fail
  outright is **not decided by this document** — see §13.
- An item whose Firestore document has no `imageUrl` field at all (a shape
  predating this task, or any document the bootstrap seed writer produces
  without ever setting it) is treated identically to one with
  `imageUrl: null` explicitly stored — both fall back to the existing
  `sourceId`/`imageId` bundled-art resolution. An `imageUrl` stored as an
  empty string (`''`) is **not** treated as a usable URL either — it also
  falls back, rather than being handed to a widget as if it were a valid
  network image reference (missing vs. empty vs. "small but present" are
  three different stored shapes and only a non-empty string counts as set).
- Removing an item that had a real `imageUrl`: this task does not delete
  the Supabase Storage object (no storage-side cleanup job is built) — the
  file is orphaned in the bucket. Flagged, not silently decided; see §13.

## 11. Validation assertions

```
F15-A01  [U]  FirestoreWardrobeRepository.addItem followed by watchItems() first emission includes that item with every field round-tripped unchanged (name, category, color, occasion, season, wears, sourceId, imageUrl)
F15-A02  [U]  FirestoreWardrobeRepository's document ID for an added item equals item.id verbatim (a String, e.g. 'new-<ts>-<i>') — never re-derived, re-hashed, or type-converted
F15-A03  [U]  The stored document also carries id as a plain field equal to the doc ID (schema doc §2's "duplicate id on document" convention), consistent with F14-A12's shared converter behavior
F15-A04  [U]  FirestoreWardrobeRepository.updateItem replaces exactly the fields of the matching document; a second watchItems() emission reflects the update, no other document in the collection changes
F15-A05  [U]  FirestoreWardrobeRepository.removeItem removes exactly that document; watchItems() no longer includes it, every other item is unaffected
F15-A06  [U]  FirestoreWardrobeRepository.adjustWears never drives an item's wears below 0, mirroring WardrobeCubit's existing clamp(0, ...) invariant, now verified at the repository-write layer
F15-A07  [U]  InMemoryWardrobeRepository's watchItems()/addItems/updateItem/removeItem/adjustWears behavior is unchanged from today's WardrobeCubit-held logic — the full pre-existing F06 test suite (F06-A01 through F06-A31) passes unmodified against WardrobeCubit constructed with InMemoryWardrobeRepository, with zero existing assertion edited to accommodate this task
F15-A08  [U]  InMemoryWardrobeRepository never imports or constructs a Firestore/Supabase client — guest mode makes zero network calls, structurally (same guarantee style as F14-A14)
F15-A09  [I]  lib/app.dart: with uid == null, WardrobeCubit is constructed with InMemoryWardrobeRepository; with uid == 'uid-1', it is constructed with FirestoreWardrobeRepository — object type differs across the F14 sign-in/out transition, not just its data
F15-A10  [U]  ImportCubit: confirming the last draft of a batch where that draft carries a picked file calls uploadWardrobePhoto(itemId: draft.id, file: <that file>) before the resulting ClothingItem reaches WardrobeRepository, and the saved item's imageUrl equals the URL uploadWardrobePhoto resolved with
F15-A11  [U]  ImportCubit: confirming a batch where no draft carries a picked file (today's simulated/pool-art path) never calls uploadWardrobePhoto; every saved item's imageUrl is null and sourceId-based art resolution is exactly as in F06-A28 — no regression
F15-A12  [U]  ImportCubit: confirming a batch where a draft's picked file is set but uploadWardrobePhoto's Future completes with an error still results in that item being saved (addItem/addItems is still called) with imageUrl: null — the save is never skipped, delayed indefinitely, or thrown past the caller
F15-A13  [U]  F15-A12's failure path surfaces a distinguishable error/toast signal (exact mechanism per §13) — a test asserts some observable signal exists (e.g. an emitted state field, or a returned/exposed error value) distinct from the no-picked-file path, so a failed upload is not silently indistinguishable from "user chose no photo"
F15-A14  [U]  Two consecutive imports in the same signed-in session, one with a picked-file upload and one without, produce items with distinct ids and each item's imageUrl set/null exactly per its own draft — no cross-contamination between drafts in the same batch
F15-A15  [U]  An item whose Firestore document has no imageUrl field at all, and one with imageUrl: null explicitly stored, both resolve to the same bundled-art fallback outcome when read back into a ClothingItem (missing vs. explicit-null are not distinguished)
F15-A16  [U]  An item whose imageUrl is stored as '' (empty string) does not resolve as a usable photo URL — treated the same as null/missing, not passed through as if it were a real link (missing/empty/set-to-a-real-url are three distinct cases and only the third counts as "has a photo")
F15-A17  [U]  storage-upload-url: a request with a valid, well-formed Firebase ID token in the Authorization header returns 200 with a signed URL whose path is exactly {uid-from-token}/{itemId}.jpg; the unit test asserts this wrapper's own call shape (not a caller-supplied 60-second expiry, which Supabase's upload-URL API does not support — see §13a: the live service uses its own fixed ~2 hour window)
F15-A18  [U]  storage-upload-url: a request with a missing Authorization header returns 401 and generates no signed URL
F15-A19  [U]  storage-upload-url: a request with a malformed or expired Firebase ID token returns 401 and generates no signed URL
F15-A20  [U]  storage-upload-url: the signed URL's path is derived only from the token's own uid — a request cannot specify a different uid than the one encoded in its own valid token (the itemId is caller-supplied; the uid segment is never caller-supplied)
F15-A21  [U]  verifyFirebaseToken rejects a token signed with a key not present in Firebase's published JWKS (a forged/unrelated token), independent of any other field in the token being well-formed
F15-A22  [U]  FirestoreWardrobeRepository.watchItems() performs zero writes on subscription — constructing WardrobeCubit for a brand-new signed-in user with an empty wardrobeItems collection never itself calls any seed-writing method; only an external bootstrap caller (F14's runBootstrapIfNeeded mechanism) is permitted to write seed documents
F15-A23  [I]  Simulating two concurrent WardrobeCubit constructions for the same brand-new uid (e.g. a reconnect re-triggering app.dart's StreamBuilder rebuild) against a fake Firestore double never results in more than the bootstrap-seeded set of wardrobeItems documents — no duplicate items from the wardrobe path itself, re-verifying Review Focus item 4 at the wardrobe layer
F15-A24  [I]  A full sign-in -> add an item with a picked photo -> sign-out -> sign-in-again cycle (F14's reconstruction pattern) leaves no stale picked-file/draft state in the newly-constructed ImportCubit — the picker draft from the previous signed-in session does not reappear
F15-A25  [L]  Against the deployed storage-upload-url function (supabase functions deploy storage-upload-url --project-ref dbaeaqyoyilxcuwplvuw), a request carrying a real Firebase ID token for a live test user returns a real signed URL and a PUT of real image bytes to that URL succeeds — deferred to the live-verification pass, documented in the task report rather than a CI-run test, per the plan's Task 2 Step 2-4 instruction
F15-A26  [L]  One real end-to-end run on a device/emulator: sign in, import an item using the real camera or gallery picker, confirm the saved item's imageUrl holds the expected storage path (not yet a reachable URL — bucket is private this task) and the item persists (with that path) after killing and relaunching the app — deferred to the live-verification pass
F15-A27  [L]  Against the live Firebase + Supabase projects, a request to storage-upload-url with no Authorization header returns a real 401 from the deployed function (not just the local/unit double) — deferred to the live-verification pass
```

## 12. Edge cases

- Import count of 6 (the pool's cap) with every draft carrying a picked
  file: 6 sequential `uploadWardrobePhoto` calls, each independent — one
  failing does not abort the others' saves.
- A picked file whose bytes fail to decode/are corrupt on the client side
  before any network call: treated as an upload failure (same `imageUrl:
  null` + toast path), not a distinct crash path.
- User backs out of the picker after starting it (no file ever picked):
  identical to the existing no-photo simulated path — not a failure, just
  "no picked file for this draft."
- `itemId` collision: since `itemId` is the client-generated
  `'new-<clock>-<index>'` id (unchanged from F06), the signed URL's storage
  path for two different drafts in the same batch never collides as long as
  the existing id-generation scheme holds (not re-verified here — it is
  F06's existing guarantee, F06-A29).
- A device clock far in the past/future affecting the generated `itemId`:
  out of scope, inherited unchanged from F06.

## 13a. Resolved decisions (dated amendments)

- 2026-10-20 — `addItem` vs `addItems`: resolved per the controller's ruling —
  `WardrobeCubit`/`ImportCubit` continue to call the batch `addItems` once per
  confirmed batch (the per-draft upload loop happens *inside* that single
  call site in `ImportCubit.confirmCurrent`, looping uploads before the one
  `_wardrobe.addItems(finalized)` call); `addItem` (singular) exists on the
  interface per §6 and is exercised directly by
  `FirestoreWardrobeRepository`'s own tests, but `ImportCubit` never calls it.
- 2026-10-20 — Async upload-failure signal: option (a) chosen —
  `confirmCurrent` is `Future<String?>`, `review_view.dart` gained exactly
  one `await` at its call site (plus a `context.mounted` guard required for
  `flutter analyze`). The failure signal itself is
  `ImportState.lastImportHadUploadFailure`, reset on every `makeDrafts()`.
  No view yet consumes this field to show a toast — that is a further,
  still-open gap (see below), consistent with "no other view logic changes"
  for this task.
- 2026-10-20 — Offline writes for signed-in users: left at the Flutter SDK
  default (enabled) as this document's own default-unless-told-otherwise
  guidance specified; not overridden.
- 2026-10-20 — Discovered live, not anticipated by this document: the
  60-second upload-URL expiry named in §2/§11 (F15-A17) is not achievable
  via Supabase's current `createSignedUploadUrl` API (only download URLs
  support a caller-supplied expiry) — the deployed function uses the
  service's own fixed expiry window instead (confirmed ~2 hours live). The
  security property (URL scoped only to the token's own uid) is still fully
  enforced; F15-A17's unit test asserts our own wrapper's behavior via an
  injected fake and is unaffected. See Task 2 report for detail.
- 2026-10-20 — Discovered live: `user-photos` is a private bucket, so the
  `imageUrl` this task constructs and stores is not yet fetchable as a plain
  URL. Harmless since nothing reads it back into a widget this task
  (confirmed §13's own ruling), but whoever wires `GarmentImage` to
  `imageUrl` must generate a signed read URL (or make the bucket public)
  first — tracked in the Task 2 handoff, not silently assumed fine.
- 2026-10-20 — Still open: no view in this task calls `ImportCubit.pickPhoto()`
  — the real camera/gallery picker exists and is unit-tested but is not yet
  reachable by an actual user tapping a button, since every current
  import-flow view (`ImportView`/`ImportSourceView`/`BatchView`) still only
  builds the simulated pool-art batch, and this task's rulings forbid any
  further view changes beyond the one line in `review_view.dart`. A future
  (view-touching) task must wire a UI trigger to `pickPhoto()`.

## 13. Open questions

- **`addItem` (singular) vs. the existing `addItems` (plural, batch-only)
  method.** The storage spec (`supabase-storage-and-functions.md` §2) names
  the save call singular (`WardrobeRepository.addItem`), but the only write
  method `WardrobeCubit`/`ImportCubit` actually calls today is `addItems`
  (plural, whole-batch, at the end of `confirmCurrent`). This document adds
  both to the interface rather than silently picking one, but the
  implementer must decide: does the per-draft upload happen *inside* the
  existing single `addItems(drafts)` batch call (looping uploads before one
  batch write), or does the save genuinely become per-draft (`addItem` once
  per confirmed draft, dropping the batch-at-the-end shape)? Either
  satisfies F15-A10-A14 as written (they test observable save+imageUrl
  outcomes, not which repository method fires); resolve before writing the
  Firestore batch-write code, and amend this section with the decision and
  a dated note rather than leaving it implicit in the diff.
- **Async upload-failure toast signal.** `ImportCubit.confirmCurrent` is
  synchronous today (`String?` return, checked by `review_view.dart`
  immediately). A real network upload cannot complete inside that
  synchronous call. Two ways to reconcile without reading as a "widget
  change" under the plan's Global Constraints: (a) `confirmCurrent`'s
  return type becomes `Future<String?>` and `review_view.dart` gains a
  one-line `await`/`.then` at its existing call site — a mechanical
  adaptation to a changed Cubit signature, not a new widget behavior; or
  (b) the upload runs detached (fire-and-forget) after a synchronous save,
  and the failure is surfaced through some new Cubit-level state/stream that
  an *existing* toast-consuming widget pattern would need to pick up —
  but no such generic "cubit pushes a toast without a widget touching it"
  mechanism exists anywhere in this codebase today (checked: every
  `AppToast.show` call site is a view reacting to a value a Cubit method
  already returned). Recommend (a); flagging here rather than deciding
  silently, since it is the first place this plan's "no widget changes"
  constraint and "never block the save" constraint are in genuine tension.
- **`GarmentImage` not rendering `imageUrl` this task.** The firestore
  schema doc (§2) states "`GarmentImage` prefers this [`imageUrl`] over
  `sourceId`/`imageId` resolution when present" — but `GarmentImage`
  (`lib/shared/widgets/garment_image.dart`) is a `widgets/` file, and the
  plan's Global Constraints forbid any `view/`/`widgets/` change in this
  entire backend-wiring plan. This document resolves the conflict by
  **not** doing the `GarmentImage` change this task: `imageUrl` is
  persisted and round-tripped (F15-A01-A16) but nothing yet displays it —
  a user's real uploaded photo is saved but invisible in the running app
  until a future (widget-touching) task wires `GarmentImage` to it. Flagging
  this explicitly since it means Task 2 ships a "write but no read-back
  display" half of the feature; worth a product decision on whether that is
  acceptable to ship as-is or whether the no-widget-changes constraint needs
  a one-time, reviewed exception for this specific widget.
- **Offline writes for signed-in users.** Neither the architecture doc nor
  the storage doc states whether `cloud_firestore`'s default offline
  persistence/write-queueing is left enabled or disabled for this phase. If
  left at its Flutter SDK default (enabled), a signed-in user's add/edit
  while offline queues locally and syncs later — different from F14's
  `runBootstrapIfNeeded` transaction, which explicitly fails outright
  offline. Needs an explicit decision before Gate 2 lands; default to "SDK
  default (enabled), undocumented contrary to F14's bootstrap case" unless
  told otherwise, and note the choice in this section with a dated amendment
  once made.
- **Orphaned Supabase Storage objects on item removal.** Removing a
  `ClothingItem` that had a real uploaded photo does not delete the
  corresponding Storage object in this task (§10). Acceptable for MVP speed
  per the project's stated bias, but flagged as unresolved cleanup, not
  silently assumed fine forever.
- **`lib/app.dart` touched by a task other than Task 1.** F14 §13's own
  open question already anticipated this: "no root Cubit...gets a dual-mode
  repository in this task... that is Task 2's job." This document treats
  that as the resolving authority for why Task 2, not just Task 1, modifies
  `lib/app.dart`'s `WardrobeCubit` construction line, despite the plan's
  Global Constraints bullet listing `lib/app.dart` as "Task 1 only" — the
  two plan documents are in tension; F14's explicit forward-reference wins
  since it was written with the conflict already in view.

---

## Completion block

```
Status: IN PROGRESS

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run (A25, A27 confirmed live this task; A26 device/emulator
            run deferred to Task 11 — no device/emulator in this environment)

Assertions: 26/27 PASS (A01-A24 unit/integration — including A08, A09, A24,
            which a review round found lacked genuine tests and were fixed;
            A25, A27 confirmed live). A26 pending (deferred, not faked).
Regression: flutter test — 463/463 pass; flutter analyze — No issues found!
            deno test (storage-upload-url + firebase-auth) — 12/12 pass;
            deno lint — clean.
```
