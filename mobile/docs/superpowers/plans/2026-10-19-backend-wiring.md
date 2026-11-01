# StyloBuddy Backend Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. This project also runs the agent harness (`.claude/harness.json`): every new `lib/` file needs a `docs/features/F<NN>-*.md` feature document with numbered assertions to exist first (`doc-worker` writes these), and every assertion needs a test named with its ID. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire real persistence (Firestore), real photo storage (Supabase
Storage), and a deployed-but-stubbed AI Edge Function behind every existing
repository seam — with zero widget changes and zero behavior change for
guests ("Skip for now" stays exactly as today).

**Architecture:** `docs/superpowers/specs/2026-10-19-backend-architecture.md`
(read first — defines the dual-mode repository pattern, auth-gated Cubit
reconstruction, ID strategy, and bootstrap seeding every task below
depends on).

**Schema:** `docs/superpowers/specs/2026-10-19-firestore-schema.md` (every
collection, field, and security-rule shape a repository task implements).

**Storage/Functions:** `docs/superpowers/specs/2026-10-19-supabase-storage-and-functions.md`
(the signed-upload flow and the Edge Function scaffold — read before Task 2
and Task 10).

**Existing infra (already live, do not recreate):** Firebase project
`stylobuddy-b7e46` (Firestore nam5 native mode, Google Auth enabled,
`android/app/google-services.json` + `lib/firebase_options.dart` committed);
Supabase project `stylobuddy` (`dbaeaqyoyilxcuwplvuw`, buckets `user-photos`
private + `clothing-catalog` public unused). Credentials: Firebase service
account at `~/.secrets/stylobuddy/firebase-service-account.json`, Supabase
access token at `~/.secrets/stylobuddy/supabase-access-token.txt` — both
outside the repo, never read into a commit.

## Global Constraints

- No widget (`view/`, `widgets/`) changes anywhere in this plan. Every task
  touches only `cubit/`, new `repository/` files, `lib/app.dart` (Task 1
  only), new `lib/shared/` infra (Task 1 only), `firestore.rules` (Task 9),
  and `supabase/functions/` (Task 2, Task 10).
- Guest mode (no Firebase user) must behave identically to the current
  `flutter test` suite at every task boundary — the in-memory repository
  implementation is the existing Cubit logic moved behind an interface,
  verbatim, not rewritten.
- Repository interfaces mirror the Cubit method names the inventory found
  (`addItems`, `saveOrFind`, `upsertManual`, `plan`, `togglePreference`,
  etc.) — a Cubit's public API does not change shape, only what's behind it.
- Firestore document IDs reuse existing in-app IDs (architecture doc D4) —
  no model's `id` field changes type.
- Every new repository file gets both an in-memory and a Firestore
  implementation in the same task, plus a factory/switch wired into
  `lib/app.dart`'s auth-gated construction (Task 1's `StreamBuilder`).
- No secrets (service account JSON, Supabase token, any future LLM API key)
  are ever committed, logged, or placed under `lib/`. `supabase secrets set`
  / environment config only.
- No feature task touches another feature's `lib/features/<other>/`. Shared
  infra (`lib/shared/backend/`, `lib/app.dart`) belongs to Task 1; a later
  task reports a needed shared change instead of making it.
- `docs/foundation/{02-architecture,03-domain-model,07-security,01-tech-stack}.md`
  get updated as part of the task that changes the reality they describe
  (not a final cleanup pass) — e.g. Task 1 removes "Milestone 1 has no auth
  backend" from `07-security.md` since Google sign-in is already real;
  Task 2 adds `imageUrl` to `03-domain-model.md`'s `ClothingItem` entry.

## Review Focus

1. **Guest-mode non-regression**: every task's reviewer re-runs the full
   `flutter test` suite and confirms no existing (pre-this-plan) test
   changed its assertions to accommodate the backend wiring — only new
   tests for the Firestore path should be new. Test owner: every task.
2. **Auth-gated reconstruction doesn't leak state** (architecture D3): a
   sign-in-then-sign-out cycle in a widget test must leave every root Cubit
   back in its guest-mode in-memory state, not a stale Firestore snapshot.
   Test owner: Task 1.
3. **Photo upload failure never blocks saving an item** (storage doc §2):
   a failed `uploadWardrobePhoto` call still results in a saved
   `ClothingItem` with a working fallback image, never a stuck/crashed
   import flow. Test owner: Task 2.
4. **Bootstrap seeding runs exactly once** (architecture D5): two concurrent
   first-loads (e.g. a flaky reconnect re-triggering the check) must not
   double-seed a new user's wardrobe. Test owner: Task 1 (the `seeded` flag
   + transaction), re-verified by Task 2's wardrobe-specific test.
5. **Security rules reject cross-user and malformed writes**: every
   collection's rule block (schema doc §8) gets a test that a write to
   another `uid`'s path, and a write with an extra/wrong-typed field, both
   fail. Test owner: Task 9, using the Firestore emulator.

---

### Task 1: Shared backend foundation

**Files:**
- Create: `lib/shared/backend/firestore_service.dart` (thin converter/path
  helpers shared by every repository — `usersCollection`, generic
  `toFirestore`/`fromFirestore` helpers per the schema doc's "duplicate id
  on doc" convention), `lib/shared/backend/auth_session.dart`
  (`Stream<String?> uidChanges()` wrapping `FirebaseAuth.instance.authStateChanges()`)
- Modify: `lib/app.dart` (wrap `MultiBlocProvider` in a
  `StreamBuilder<String?>` keyed by uid per architecture D3; every root
  Cubit's constructor gains the repository it needs, chosen in-memory vs
  Firestore by whether `uid` is null)
- Modify: `docs/foundation/02-architecture.md`, `07-security.md`,
  `01-tech-stack.md` (remove stale "later"/"no backend" framing for the
  pieces this plan makes real; `03-domain-model.md` gets the `seeded`
  infra-field note from the schema doc §1)
- Create: `docs/features/F14-backend-foundation.md` (doc-worker, before any
  code)

- [ ] **Step 1: Failing tests:** a widget test pumping the app with a fake
  `FirebaseAuth` stream emitting a uid, then null, asserts
  `WardrobeCubit.state.items` is the in-memory seed list both before sign-in
  and after sign-out (never stale Firestore data); a unit test for the D5
  bootstrap transaction asserts it only writes once under two concurrent
  calls (use a fake/in-memory Firestore double, not the real emulator, for
  this task — Task 9 is where emulator-backed rule tests live).
- [ ] **Step 2–4:** FAIL → implement → PASS + `flutter analyze` clean.

---

### Task 2: Wardrobe repository + real photo upload

**Depends on:** Task 1.
**Files:** `lib/features/wardrobe/repository/*`, `lib/shared/backend/storage_repository.dart`,
`supabase/functions/storage-upload-url/`, `supabase/functions/_shared/firebase-auth.ts`,
`pubspec.yaml` (`image_picker`, `supabase_flutter` for the client-side `http` call
is not required — plain `package:http` PUT to the signed URL is enough, per
storage doc §2; add `http` if not already present).
**Spec:** `supabase-storage-and-functions.md` §1–2.

- [ ] **Step 1: Failing tests:** `FirestoreWardrobeRepository` CRUD round-trip
  (fake/in-memory Firestore double); `ImportCubit` save with a picked file
  calls `uploadWardrobePhoto` then `addItem` with `imageUrl` set; save with
  no picked file (or upload throwing) still calls `addItem`, with
  `imageUrl: null` and a toast, never blocking. Edge Function:
  `storage-upload-url` returns a signed URL for a valid Firebase token and
  401 for a missing/invalid one (Deno test, run locally via
  `supabase functions serve`, not deployed yet for this step).
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze. Deploy the function
  (`supabase functions deploy storage-upload-url --project-ref dbaeaqyoyilxcuwplvuw`)
  and do one real end-to-end upload (documented in the report, not a
  CI-run test) before marking done.

---

### Task 3: Saved / Outfits repository

**Depends on:** Task 1.
**Files:** `lib/features/saved/repository/*` (new folder — none exists today).
**Schema:** `firestore-schema.md` §3–4.

- [ ] **Step 1: Failing tests:** `FirestoreOutfitsRepository` round-trips
  `Outfit` and `WearEvent`; `wearEvents()` ordering matches the existing
  descending-timestamp contract; `logWear`/`removeWear` never drive
  `worn`/`wears` negative (existing invariant, re-verified against the
  Firestore path).
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 4: Calendar / Planner repository

**Depends on:** Task 1.
**Files:** `lib/features/calendar/repository/*` (new).
**Schema:** `firestore-schema.md` §5.

- [ ] **Step 1: Failing tests:** `FirestorePlannerRepository.watchPlanned()`
  reflects writes keyed by `'yyyy-MM-dd'`; `plan`/`remove` round-trip.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 5: Profile repository + onboarding handoff fix

**Depends on:** Task 1.
**Files:** `lib/features/profile/repository/*` (new); modify
`lib/features/onboarding/cubit/onboarding_cubit.dart` (or wherever
onboarding's finish action lives) to forward `chosenOccasions`/`chosenChips`
into the Profile repository on completion — the gap the inventory flagged.
**Schema:** `firestore-schema.md` §1, architecture D5.

- [ ] **Step 1: Failing tests:** `FirestoreProfileRepository` round-trips
  every `ProfileState` field; the D5 bootstrap write includes `wishlist: []`
  and `seeded: true`; finishing onboarding with chosen occasions/styles
  results in a `ProfileState` reflecting them (new regression test closing
  the gap — this must fail against current `main` first, confirming it's a
  real gap and not a misread).
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 6: Shopping repository (wishlist only)

**Depends on:** Task 1, Task 5 (shares the `users/{uid}.wishlist` field).
**Files:** `lib/features/shopping/repository/*` (new). `ShoppingCatalog`
itself stays a bundled constant — only `wishlist` gets a repository method.
**Schema:** `firestore-schema.md` §1.

- [ ] **Step 1: Failing tests:** toggling wishlist membership persists via
  `ProfileRepository`-shaped `users/{uid}.wishlist` (confirm no duplicate
  write path versus Task 5's profile doc — one source of truth for that
  field, reviewed explicitly for this).
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 7: Packing repository

**Depends on:** Task 1.
**Files:** `lib/features/packing/repository/*` (new).
**Schema:** `firestore-schema.md` §6.

- [ ] **Step 1: Failing tests:** `FirestorePackingRepository` round-trips a
  `Trip` with embedded `PackingItem` list; confirms trips now survive the
  app-restart scenario that F10's original ledger entry flagged as a known
  gap for signed-in users (guest mode keeps the existing in-memory
  behavior, including its own already-fixed survive-navigation test from
  the whole-branch review).
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 8: Real email/password auth

**Depends on:** Task 1.
**Files:** `lib/features/auth/repository/auth_repository.dart` (extend, not
replace — Google path is untouched), `lib/features/auth/cubit/auth_cubit.dart`.

- [ ] **Step 1: Failing tests:** `submitSignup`/`submitLogin`/`submitForgot`
  call real Firebase Auth (`createUserWithEmailAndPassword`,
  `signInWithEmailAndPassword`, `sendPasswordResetEmail`) behind the same
  `AuthResult` return contract; existing validation-only tests (short
  password, mismatch, invalid email) still pass unchanged since those
  checks still run client-side before any network call; a new test covers
  a real `FirebaseAuthException` (e.g. email-already-in-use) surfacing
  through the existing `error`/`errorFor` state shape.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 9: Firestore security rules hardening + emulator tests

**Depends on:** Tasks 2–8 (needs every collection's real field set to write
accurate per-collection rules).
**Files:** `firestore.rules` (extend), `firestore.indexes.json` (add the
`wearEvents` timestamp-descending index if the emulator/production console
flags it as needed), new `test/firestore_rules_test/` using the Firestore
emulator (`firebase emulators:start --only firestore`).
**Schema:** `firestore-schema.md` §8.

- [ ] **Step 1: Failing tests:** for each collection — a same-uid write with
  valid fields succeeds; a same-uid write with an extra/unexpected field
  fails; a different-uid write fails; a signed-out write fails. Run against
  the Firestore emulator, not production.
- [ ] **Step 2–4:** FAIL → implement → PASS. Deploy the final rules to
  production (`firebase deploy --only firestore:rules`) as the task's last
  step, documented with the before/after rule diff in the report.

---

### Task 10: Edge Function scaffold (`ai-stylist`, stub)

**Depends on:** Task 2 (reuses `_shared/firebase-auth.ts`).
**Files:** `supabase/functions/ai-stylist/index.ts`,
`supabase/functions/_shared/llm-adapter.ts`.
**Spec:** `supabase-storage-and-functions.md` §3.

- [ ] **Step 1: Failing tests:** (Deno test) a valid Firebase token with no
  `LLM_PROVIDER` configured gets `501` with the documented JSON body; an
  invalid/missing token gets `401`. **No Flutter code calls this function
  in this task** — it's deployed and independently testable, not wired to
  any UI, per the explicit AI-deferral decision.
- [ ] **Step 2–4:** FAIL → implement → PASS. Deploy
  (`supabase functions deploy ai-stylist --project-ref dbaeaqyoyilxcuwplvuw`).

---

### Task 11: Integration, docs, build verification

**Depends on:** all above.
**Files:** `docs/tracker.md`, `docs/project-handoff.md` (rewrite to the new
state — Integration moves from PENDING to DONE for Firestore/Storage, AI
stays explicitly PENDING pending the provider decision — reference the
saved memory note, don't re-litigate it), `docs/README.md` and every
`docs/features/F<NN>` header touched by this plan (gate statuses).

- [ ] **Step 1:** Full manual walkthrough on a real device/emulator,
  documented in the report: sign up with email, add a real wardrobe item
  with a camera/gallery photo, confirm it persists after a cold restart,
  sign out, confirm guest mode is unaffected (seed data, no network calls),
  sign back in, confirm the same real data reappears.
- [ ] **Step 2:** `flutter test` (full) → all PASS; `flutter analyze` → no
  issues; `flutter build apk --debug` → succeeds.
- [ ] **Step 3:** Docs rewritten per above; commit.
