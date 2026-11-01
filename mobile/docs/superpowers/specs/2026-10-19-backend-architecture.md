# Backend Architecture — Milestone 2 (Integration)

> Supersedes the "later" framing in `docs/foundation/02-architecture.md` and
> `docs/foundation/07-security.md` for the areas this covers. Those foundation
> docs get updated as part of Task 1 to stop contradicting reality.

StyloBuddy's Milestone 1 (the prototype port) shipped all 13 features against
in-memory sample data. This phase wires real persistence and storage in
**without changing any widget** — per the existing architecture principle
"backends slot in behind repositories later," this is that later.

Firebase project `stylobuddy-b7e46` and Supabase project `stylobuddy`
(`dbaeaqyoyilxcuwplvuw`) already exist (set up 2026-10-16/17). Firebase Auth
(Google sign-in) is already real. This phase adds Firestore for data,
Supabase Storage for user photos, and a deferred-AI Edge Function scaffold.

## 1. Decisions

**D1 — Firestore vs Supabase split (reaffirms tech-stack.md).**
Firestore holds all structured app data. Supabase Storage holds only binary
files (user-uploaded wardrobe photos). No file bytes ever go through
Firestore; no structured queryable data goes through Supabase Postgres (its
Postgres database is unused — Edge Functions are stateless and call out to an
LLM, not a local DB, so there is nothing to put in Supabase's Postgres for
this app).

**D2 — Dual-mode repositories: guest (in-memory) vs signed-in (Firestore).**
The app has no forced login — "Skip for now" is a real, supported mode
(`docs/foundation/07-security.md` role table). Rather than add an "empty
state" to every Firestore repository for signed-out users, each feature gets
**two** repository implementations behind the same interface:
- `<Feature>Repository` (abstract): the method surface the Cubit already
  calls today.
- `InMemory<Feature>Repository`: today's behavior verbatim (seeded from
  `SeedData`/hardcoded defaults where applicable), used for guests.
- `Firestore<Feature>Repository`: real reads/writes under `users/{uid}/...`,
  used once a Firebase user exists.

`lib/app.dart` picks which implementation to construct each root Cubit with,
keyed by `FirebaseAuth.instance.authStateChanges()`. See D3.

**D3 — Auth-gated Cubit reconstruction, not per-call branching.**
`lib/app.dart` wraps the existing `MultiBlocProvider` in a
`StreamBuilder<User?>` on `FirebaseAuth.instance.authStateChanges()`, keyed
by `user?.uid`. On sign-in/sign-out, Flutter tears down and rebuilds the
whole provider subtree (a full `Key` change), so every root Cubit is
reconstructed with the right repository for the new auth state. This is
simpler and more correct than threading an `isSignedIn` flag through every
repository call: no code path can accidentally mix guest and real data in
one Cubit instance, and existing Cubit tests (which construct Cubits
directly, bypassing `app.dart`) are completely unaffected.

Trade-off accepted: a sign-in/out transition remounts every screen (loses
scroll position, closes open sheets). Acceptable — sign-in only happens from
the auth flow (not mid-session elsewhere) and sign-out is a deliberate
settings action, both already full-navigation events in the prototype.

**D4 — IDs stay exactly as they are; Firestore doc IDs reuse them.**
No model's `id` field changes type. `ClothingItem.id` is already a `String`
(slug or `new-<ts>-<i>`) and becomes the Firestore document ID directly.
`Outfit.id`/`WearEvent.id`/`Trip.id` stay `int` (clock-based, as today);
the Firestore document ID is `id.toString()`. This is the minimum-risk
choice — zero call sites change their signature (`OutfitsCubit.byId(int)`,
`WearEvent.outfitId`, `PackingItem.wardrobeId`, etc. are untouched).
`PlannedEntry` keeps using its `'yyyy-MM-dd'` key as the Firestore doc ID too
(already the `Map` key in `PlannerState.planned`).

**D5 — First-login bootstrap seeds from the existing sample data.**
A brand-new Firestore user (empty `wardrobeItems`/`outfits`/`plannedEntries`
subcollections) gets one-time seeded from `SeedData` on first successful
sign-in — same rows a guest sees today, written as their own real,
editable Firestore documents. This avoids a jarring empty-app first run and
matches the product's "clone a proven app, add a flag" MVP spirit. Detected
by an empty `wardrobeItems` read; guarded by a `users/{uid}.seeded: bool`
flag so it only ever runs once even if the read races. `ShoppingCatalog`
and onboarding copy stay bundled app config, never seeded per-user (D1 in
`firestore-schema.md`).

**D6 — Repositories return `Stream`s for collections, `Future`s for writes.**
Every list-shaped repository method (`watchItems()`, `watchOutfits()`, etc.)
returns a `Stream` backed by Firestore's `snapshots()` for the Firestore
implementation, and a `Stream` wrapping a `StreamController` seeded once for
the in-memory implementation (so both implementations satisfy the same
interface without the Cubit knowing which it has). Writes
(`addItem`, `updateItem`, …) are `Future<void>`, awaited by the Cubit before
it optimistically updates local state — optimistic-then-reconcile, not
read-after-write, to keep the UI responsive (matches current UX where
actions apply instantly).

**D7 — Supabase Storage: one bucket, UID-prefixed paths, signed uploads via
anon key + Storage RLS, not a service-role backend.**
`user-photos` bucket (already created, private) holds every user photo at
`{uid}/{itemId}.jpg`. The Flutter app uploads directly using the Supabase
anon key plus a Storage RLS policy restricting each path prefix to its own
`auth.uid()` — see D2 in `supabase-storage-and-functions.md` for why this
needs Supabase Auth to recognize the same user, and how. `clothing-catalog`
(public bucket, already created) is reserved for a future bundled/shared
catalog and is **not used in this phase** — nothing writes to it yet.

**D8 — Edge Functions: scaffold only, LLM call deferred.**
Per explicit user instruction (2026-10-19), no real LLM is wired yet. One
scaffold function (`supabase/functions/ai-stylist`) is deployed to prove the
pipeline (auth check, CORS, deploy, a Flutter-side repository call that hits
it) and returns `501 Not Configured` from a `llmAdapter.ts` stub that will
later dispatch to whichever provider is chosen. See
`supabase-storage-and-functions.md` §3.

*(2026-10-20, Task 10 amendment)* This entry's details are superseded by
`docs/superpowers/specs/2026-10-19-supabase-storage-and-functions.md` §3
and `docs/features/F23-ai-stylist-stub.md`, which are the actual
implemented shape: no Flutter code calls `ai-stylist` (no "repository call
that hits it"), it has no CORS handling (no browser caller exists), the
seam file is `_shared/llm-adapter.ts` (not `llmAdapter.ts`), and the
no-adapter body is the exact JSON `{"error": "AI provider not configured
yet"}` (not the string "501 Not Configured"). This note is left here
rather than rewriting D8 itself (out of Task 10's scope; ruling: §13 Q5 of
F23).

**D9 — Firestore security rules stay default-deny, extended per-collection.**
The existing `firestore.rules` (`users/{uid}/{document=**}` → owner-only) is
extended with field-level `request.resource.data.keys()` checks per
collection in Task 9, not loosened. Still default-deny outside `users/{uid}`.

## 2. What does NOT change

- No widget, view, or `widgets/` file changes. Per architecture principle 2
  ("widgets render state and forward intents"), this phase only touches
  `cubit/` (repository wiring, minor async handling) and new `repository/`
  files.
- Guest mode ("Skip for now") behaves identically to today — same seed data,
  same instant in-memory writes, no network calls, no new failure modes.
- `ShoppingCatalog`, `IntroSlide`/onboarding copy, and all bundled garment
  art stay static Flutter assets/constants — never move to Firestore or
  Storage (confirmed not user data; see inventory in the plan doc).

## 3. Risk notes

- **Biggest net-new surface**: wardrobe photo import currently does zero
  real image I/O (confirmed: no `image_picker` import anywhere in the repo
  today). This phase adds a real picker + upload + URL-on-document flow from
  scratch, not a migration of existing logic — budget it as new feature
  work, not a refactor, in the plan's task sizing.
- **Auth-gated remount (D3)** must not break guest mode — Task 1's tests
  include "no Firebase user, all Cubits behave exactly as the current
  suite expects" as a hard regression gate before any feature task starts.
- **Onboarding → Profile gap**: the inventory found `OnboardingCubit`'s
  `chosenOccasions`/`chosenChips` are never forwarded to `ProfileState`
  today. Task 5 fixes this as part of wiring Profile to Firestore, since a
  new user's bootstrap-seeded profile should reflect what they picked during
  onboarding, not just the hardcoded defaults.
