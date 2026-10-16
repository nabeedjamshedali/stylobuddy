# StyloBuddy — Project Handoff

Rewritten 2026-10-17, after Task 14 (final integration pass) of the
`2026-10-16-prototype-port` plan. This repo has the `flutter-app-dev-agent`
kit installed (`CLAUDE.md` + `.claude/agents/*.md`) — read those first if
you haven't. This doc replaces the 2026-10-13 version, which described an
early 3-screen onboarding scaffold; that scope has since been superseded
entirely by a full screen-for-screen port of the StyloBuddy HTML
prototype. Don't rely on the old version for anything.

## What this app actually is right now

A **complete 64-screen prototype port**, not yet a backend-integrated
product. Every screen from the HTML/JS prototype
(`stylobuddy-v23-mobile-icon-final/stylobuddy-prototype/` at the repo
root — untracked, the user's reference copy, never edit or delete it) has
been rebuilt as a real Flutter screen, wired to Cubit state management and
`go_router` navigation, and verified side-by-side against the prototype.
**All data is in-memory sample data** (`lib/shared/data/seed_data.dart` +
Cubits holding state in RAM) — nothing is persisted, there is no real
authentication, and no backend service has been wired in. Closing the app
loses all changes.

### What's done

- **13 feature slices (F01–F13), all built, reviewed, and tested**:
  F01 design foundation (theme/router/asset registry/app shell), F02
  onboarding + auth UI, F03 AI stylist, F04 Match My Clothes, F05 home
  dashboard, F06 wardrobe, F07 outfit builder, F08 saved looks, F09
  calendar, F10 packing assistant, F11 shopping assistant, F12 style
  insights, F13 profile/settings/premium preview.
- **State management**: `flutter_bloc` Cubits only (`WardrobeCubit`,
  `OutfitsCubit`, `PlannerCubit`, `ProfileCubit`, `StylistCubit`,
  `WardrobeBrowseCubit`, `ImportCubit`, `BuilderCubit`, `ShoppingCubit`),
  all provided at the app root in `lib/app.dart`. Plain state classes with
  `copyWith`, no Provider/Riverpod/GetX/Freezed.
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
- **Tests**: 388 tests, full suite green (`flutter test`). `flutter
  analyze` reports "No issues found!". Every feature document's assertions
  (`docs/features/F01..F13-*.md`) have a covering test named after its
  assertion ID (`F03_A28`, etc.).
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

### What's explicitly NOT done — don't assume otherwise

This is the single most important thing for the next session to
internalize: **zero backend integration exists**. Specifically, none of
the following from `.claude/agents/tech-stack.md` has been wired in yet:

- **Firebase Auth** — F02's login/signup/forgot/verify screens are UI
  only, backed by in-memory `S.auth`-style state (no `firebase_auth`
  package calls, no real session).
- **Firestore** — no persistence at all. Wardrobe items, outfits, planned
  calendar entries, trips, wishlist, profile — all of it lives only in
  Cubit state for the lifetime of the app process, seeded from
  `lib/shared/data/seed_data.dart` on launch.
- **Supabase Storage** — the wardrobe "import"/"add item" flow is fully
  simulated (`lib/features/wardrobe/cubit/import_cubit.dart`); no real
  image upload.
- **Supabase Edge Functions** — none exist.
- **RevenueCat** — F13's premium/plan/purchase/subscription screens are
  static previews; "Free" is hardcoded, no entitlement checks, no real
  purchase flow.
- **Firebase Analytics / Crashlytics / Remote Config** — not added.
- **Security rules / hardening** — nothing to audit yet since there's no
  backend; Firestore/Storage rules, Supabase auth checks, and a
  secrets/API-key check are all still open once the above exists.

See `docs/tracker.md` for the itemized status (Design/Onboarding/Core
Features are done; Integration and Security are PENDING).

## Where to pick up next

1. **Wire Firebase**: ask the user for a service-account key, create/
   configure the Firebase project per `.claude/agents/tech-stack.md`,
   add `firebase_auth` + `cloud_firestore`, replace F02's simulated auth
   state with real Firebase Auth, and replace the in-memory Cubit seed
   data with Firestore-backed repositories (the wardrobe feature already
   has a `WardrobeRepository` seam in `lib/features/wardrobe/repository/`
   — extend that pattern to the other features' Cubits rather than
   putting Firestore calls directly in Cubits/widgets).
2. **Wire Supabase Storage** for wardrobe item photos (ask for an access
   token), replacing the simulated import flow.
3. **Wire RevenueCat** for the premium/subscription screens once there's
   a real backend user to attach entitlements to.
4. **Add Firebase Analytics/Crashlytics/Remote Config** per the standard
   kit wiring.
5. Once backend wiring exists, run a security/hardening pass (Firestore
   + Storage rules, secrets check) before shipping.
6. iOS: this port has only been built/verified for Android + web (for
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
