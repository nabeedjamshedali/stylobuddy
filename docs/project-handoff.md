# StyloBuddy — Project Handoff

Rewritten 2026-10-20, after Task 11 (integration/docs pass) of the
`docs/superpowers/plans/2026-10-19-backend-wiring.md` plan. This repo has
the `flutter-app-dev-agent` kit installed (`CLAUDE.md` + `.claude/agents/
*.md`) — read those first if you haven't. This doc replaces the
2026-10-17 version, which described the app as "not yet a backend-
integrated product" — that is no longer true. Don't rely on the old
version for anything.

## What this app actually is right now

A **complete 64-screen prototype port with real backend wiring behind
every data-owning feature**: Firebase Auth (Google sign-in), Firestore
(wardrobe, outfits/wear events, planner, profile, shopping wishlist,
packing), and Supabase Storage (wardrobe photo uploads) are all real and
dual-mode — **guest mode is byte-identical to the pre-backend-wiring
in-memory behavior** (nothing changed for a user who never signs in),
and signing in with Google switches every Cubit onto a Firestore-backed
repository behind the exact same public API. Firestore security rules
are hardened and proven against the emulator, though the production
deploy is intentionally held back (see "What's explicitly NOT done"
below). An Edge Function stub (`ai-stylist`) exists but is not wired to
any screen — the AI/LLM provider choice is still an open, deliberately
deferred decision.

Every screen from the HTML/JS prototype
(`stylobuddy-v23-mobile-icon-final/stylobuddy-prototype/` at the repo
root — untracked, the user's reference copy, never edit or delete it) was
rebuilt as a real Flutter screen, wired to Cubit state management and
`go_router` navigation; a representative sample was visually verified
side-by-side against the prototype during the original prototype-port
plan (see "Visual parity pass" below) — that was a sample, not an
inspection of all 63 routes, and nothing in the backend-wiring plan
re-ran it (no screen's UI changed, only what's behind each Cubit).

### What's done

- **13 feature slices (F01–F13), all built, reviewed, and tested**:
  F01 design foundation (theme/router/asset registry/app shell), F02
  onboarding + auth UI, F03 AI stylist, F04 Match My Clothes, F05 home
  dashboard, F06 wardrobe, F07 outfit builder, F08 saved looks, F09
  calendar, F10 packing assistant, F11 shopping assistant, F12 style
  insights, F13 profile/settings/premium preview.
- **State management**: `flutter_bloc` Cubits only (`WardrobeCubit`,
  `OutfitsCubit`, `PlannerCubit`, `ProfileCubit`, `StylistCubit`,
  `WardrobeBrowseCubit`, `ImportCubit`, `BuilderCubit`, `ShoppingCubit`,
  `PackingCubit`), provided at the app root in `lib/app.dart` — not *all*
  Cubits are root-provided: `AuthCubit`, `OnboardingCubit` and
  `SavedViewCubit` are intentionally route-scoped feature-local Cubits
  (they hold per-flow UI state, not durable user data, so recreating them
  on re-entry is correct). Plain state classes with `copyWith`, no
  Provider/Riverpod/GetX/Freezed.
- **Navigation**: `go_router`, hash-based on web (`/#/<route>`), one path
  per prototype route (`lib/core/router/app_routes.dart` — 63 route
  constants, matching the prototype's `pages.*` keys). Bottom-nav tabs use
  `context.go`; drill-down screens use `context.push` so system/browser
  back works like the prototype's own history stack.
- **Cross-feature wiring unified (Task 14)**: F03's AI-stylist
  result-detail "Plan Outfit" action now goes through
  `PlannerCubit.startScheduling(outfitId, occasion)` /
  `.clearEditing()`, the same draft-scheduling API F08 (saved looks) and
  F09 (calendar) use, instead of calling `plan()`/`select()` in isolation
  (`lib/features/stylist/view/result_detail_view.dart`).
- **Tests**: full suite green (`flutter test`). `flutter
  analyze` reports "No issues found!". Most feature document assertions
  (`docs/features/F01..F13-*.md`) have a covering test named after its
  assertion ID (`F03_A28`, etc.) — the exceptions are F01's 44 assertions
  written before that ID convention existed (no per-ID test names, though
  the behavior they describe is covered by other tests under
  `test/core`, `test/shared` and `test/features/*`), and every `[L]`
  live-run assertion across all 13 features (12 total), which has no test
  by design — it's verified by actually running the app, not by
  automated tests.
- **Visual parity pass**: screenshots of all ~63 routes captured for both
  the HTML prototype (served on :8801) and this Flutter web build (served
  on :8802) at 390x844 via `scripts/parity/shoot.js` (Playwright). A
  representative sample across every feature was inspected; see
  `.superpowers/sdd/2026-10-16-prototype-port/task-14-report.md` for the
  full log of what was checked, what was fixed, and what's an accepted
  Flutter-vs-browser rendering limitation (e.g. no native dashed border,
  headless-Chromium emoji-glyph tofu in the screenshot tool itself, not a
  real-device issue).
- **Android build**: `flutter build apk --debug` succeeds
  (`build/app/outputs/flutter-apk/app-debug.apk`).
- **Backend wiring (`2026-10-19-backend-wiring` plan, Tasks 1-7, 9, 10 —
  9 of 11 tasks, Task 8 skipped by user decision, Task 11 is this doc
  pass)**:
  - **Firebase Auth**: real Google sign-in (`AuthRepository
    .signInWithGoogle`/`.signOut`). Email/password forms stay demo-only
    client-side validation with no backend call — **by explicit user
    decision** (2026-10-20: "google auth is fine for now, don't do
    manually email password login"). `lib/app.dart`'s uid-keyed
    `StreamBuilder` reconstructs every data-owning Cubit against a
    Firestore-backed repository on sign-in, an in-memory one on
    sign-out — same public Cubit API either way.
  - **Firestore**: every feature that owns durable data has a dual-mode
    repository (interface + `InMemory*`/`Firestore*` implementation):
    wardrobe (F15), outfits/wear events (F16), planner (F17), profile +
    wishlist (F18/F19), packing (F20). Guest mode is the pre-existing
    in-memory logic moved behind an interface, verbatim — same
    synchronous timing, same tests, byte-identical behavior. A new
    user's first sign-in runs one combined bootstrap transaction (F18)
    seeding wardrobe/outfits/planner/profile under a single `seeded`
    flag. Every optimistic-update rollback is targeted (reverts only the
    one field/item that failed, against current state) — this bug class
    (a whole-object/whole-list rollback clobbering an unrelated
    concurrent change) hit three different features during review and
    was fixed the same way each time.
  - **Supabase Storage**: `storage-upload-url` Edge Function issues a
    real signed upload URL scoped to the caller's own Firebase uid
    (F15); the service-role key never reaches the Flutter client.
  - **Supabase Edge Functions**: `storage-upload-url` (real, F15).
    `ai-stylist` (stub only, F23) — see "AI is explicitly deferred"
    below.
  - **Firestore security rules**: hardened from a blanket owner-only
    wildcard to six per-collection blocks with field-level `hasOnly`
    validation and type/invariant checks, proven against the Firestore
    emulator (55/55, F22). **The production deploy has NOT run** — see
    below.
  - **Tests**: full suite green, 595/595 (`flutter test`). `flutter
    analyze` reports "No issues found!". `flutter build apk --debug`
    succeeds. Most feature document assertions have a covering test
    named after its assertion ID. Every feature's `[L]` live-device-run
    assertion is honestly deferred (no test fakes it) — it needs an
    actual Android device/emulator, which was not available in the
    environment this plan was executed in (see "Where to pick up next").

### What's explicitly NOT done — don't assume otherwise

- **AI / LLM provider — a deliberately deferred decision, not an
  oversight.** `ai-stylist` is a real, deployable-but-not-deployed Edge
  Function: it verifies the caller's Firebase token, then returns 501
  "AI provider not configured yet" via a `getLlmAdapter()` seam that has
  zero providers registered (by design — `llm-adapter.ts` has no
  imports, no `fetch`, no implementation). **No Flutter screen calls
  it.** `StylistCubit`'s existing algorithmic generation (templates,
  `createMatches`) is completely untouched. **The user has not chosen a
  provider (Claude/OpenAI/other) yet — this is a standing reminder to
  raise with them, not something to decide unilaterally.**
- **Firestore rules production deploy** — the hardened rules exist in
  `firestore.rules` and pass 55/55 against the emulator, but
  `firebase deploy --only firestore:rules` has never been run. A rule
  stricter than the real app silently rolls back optimistic UI writes
  and can permanently block a new user's bootstrap — this needs a clean
  pre-deploy production-data audit and an explicit go-ahead, not an
  automatic step at the end of a task.
- **`ai-stylist` Edge Function deploy** — DONE 2026-10-29 with the user's
  go-ahead: live on Supabase project `dbaeaqyoyilxcuwplvuw` (v1), live
  probes A23/A24 pass (401 `Unauthorized` without a valid Firebase token;
  501 `{"error":"AI provider not configured yet"}` with one). Still a stub
  — nothing in the app calls it and no LLM provider is configured.
- **Real email/password Firebase Auth** — skipped by explicit user
  decision (see above). The demo-only login/signup/forgot forms are
  unchanged from before this plan. `docs/features/F21-email-password-
  auth.md` is kept as a drafted-but-not-implemented doc for future
  reference, including the real scope conflict it found in the original
  plan (the UI must change once these calls become async — "no widget
  changes" and "real backend calls" can't both be true).
- **RevenueCat** — F13's premium/plan/purchase/subscription screens are
  static previews; "Free" is hardcoded, no entitlement checks, no real
  purchase flow. Not in scope of the backend-wiring plan.
- **Firebase Analytics / Crashlytics / Remote Config** — not added. Not
  in scope of the backend-wiring plan.
- **Full manual device walkthrough** — the backend-wiring plan's Task
  11 calls for a full sign-up → add-photo → cold-restart → sign-out →
  sign-back-in walkthrough on a real device/emulator. **No Android
  device or emulator was available in the environment this plan was
  executed in** (`flutter emulators` found no AVD images, `flutter
  devices` found none connected). This has NOT been performed —
  everything above is verified by automated tests against
  `fake_cloud_firestore` and the Firestore emulator, which is real
  verification of the rules/repository logic but is not the same as
  confirming the real app, on a real device, against the real
  `stylobuddy-b7e46` Firestore project, behaves correctly end-to-end.
  **This is the next concrete step** — see below.

See `docs/tracker.md` for the itemized status.

## Where to pick up next

1. **Run the deferred manual device walkthrough** (backend-wiring plan
   Task 11, Step 1): on a real Android device or a configured AVD —
   sign in with Google, add a real wardrobe item with a camera/gallery
   photo, confirm it persists after a cold restart, sign out, confirm
   guest mode is unaffected (seed data, no network calls), sign back in,
   confirm the same real data reappears. This needs either a physical
   device plugged in or an Android SDK with at least one AVD image —
   neither was available in the environment this plan ran in.
2. **Decide the production Firestore rules deploy timing.** The rules
   are written and emulator-proven (F22); deploying them
   (`firebase deploy --only firestore:rules --project stylobuddy-b7e46`)
   needs a pre-deploy production-data audit (checking no existing
   document already violates the new field-level rules) and an explicit
   go-ahead, since a bad deploy silently breaks real users' writes.
3. **Decide the `ai-stylist` Edge Function deploy timing** (lower risk
   than the rules deploy, but still a real production action —
   `supabase functions deploy ai-stylist --project-ref
   dbaeaqyoyilxcuwplvuw`).
4. **Choose an LLM/AI provider** when ready — this unblocks wiring a
   real `generateOutfitSuggestion` implementation behind
   `getLlmAdapter()` and, eventually, a Flutter screen calling
   `ai-stylist`. Standing deferred decision — raise with the user, don't
   decide for them.
5. **Wire RevenueCat** for the premium/subscription screens once
   there's a real backend user to attach entitlements to.
6. **Add Firebase Analytics/Crashlytics/Remote Config** per the standard
   kit wiring.
7. iOS: this port has only been built/verified for Android + web (for
   the parity screenshots). No iOS-specific work has been done; expect
   the usual iOS packaging/signing setup when that becomes a priority.

## Running it

```
cd "C:\workspace\my projects\mobile_applications\stylobuddy"
flutter run -d chrome        # fastest visual loop
flutter run                  # Android, once a device/emulator is attached
flutter build apk --debug    # confirmed working
```

Parity screenshot tooling (regenerate anytime the UI changes):

```
cd "C:\Users\DELL\Downloads\stylobuddy-v23-mobile-icon-final\stylobuddy-prototype"
python -m http.server 8801   # serves the reference HTML prototype

cd "C:\workspace\my projects\mobile_applications\stylobuddy"
flutter build web
cd build\web && python -m http.server 8802   # serves this app

cd "C:\workspace\my projects\mobile_applications\stylobuddy\scripts\parity"
npm install                  # first time only
npx playwright install chromium   # first time only
node shoot.js                # all routes, or `node shoot.js <slug-filter>` for one
```

Screenshot pairs land in `scripts/parity/out/<route-slug>-{proto,app}.png`.
