# StyloBuddy — Tracker

## Design
- [x] Design prompt / design system tokens built (`lib/core/theme/`: colors, DM Sans/Manrope text styles, bundled fonts)
- [x] All 64 prototype routes ported screen-for-screen, verified against the HTML prototype (parity pass, Task 14)
- [x] Asset registry (`lib/core/assets/app_assets.dart`) wired to bundled SVG/garment imagery

## Onboarding
- [x] Flow spec: welcome -> 5 onboarding slides -> personalize -> auth (login/signup/forgot/reset-sent/verify-email)
- [x] Screens implemented (F02)

## Core Features — all 13 feature slices built, reviewed, tests passing
- [x] F01 Design foundation (theme, router, asset registry, app shell/bottom nav)
- [x] F02 Onboarding and auth (UI only — no real Firebase Auth yet)
- [x] F03 AI stylist (occasion -> styling options -> generate -> results -> result detail; save/plan/swap/share)
- [x] F04 Match My Clothes
- [x] F05 Home dashboard
- [x] F06 Wardrobe (browse, search, filter, import, edit, delete)
- [x] F07 Outfit builder (manual outfit creation)
- [x] F08 Saved looks (saved outfits, wear history)
- [x] F09 Calendar (outfit planning)
- [x] F10 Packing assistant (trips, checklists)
- [x] F11 Shopping assistant (discover, wishlist)
- [x] F12 Style insights
- [x] F13 Profile, settings, premium preview screens
- [x] Cross-feature wiring unified (Task 14): F03's "Plan Outfit" now goes through `PlannerCubit.startScheduling`/`clearEditing`, same as F08/F09
- [x] Full test suite passing (`flutter test`), `flutter analyze` clean
- [x] `flutter build apk --debug` succeeds

## Integration — DONE for Firestore/Storage; AI explicitly PENDING
`2026-10-19-backend-wiring` plan, 11 tasks: 9 complete, 1 skipped by
explicit user decision, 1 (this integration/docs pass) in progress.
- [x] Firebase Auth — real Google sign-in wired (F14); email/password
      stays demo-only, **by explicit user decision** (2026-10-20: "google
      auth is fine for now, don't do manually email password login" —
      Task 8/F21 skipped, kept as a drafted-but-deferred doc)
- [x] Firestore — every feature's data (wardrobe, outfits/wear events,
      planner, profile, shopping wishlist, packing) is dual-mode: guest
      stays in-memory (byte-identical to pre-backend-wiring behavior),
      signed-in reads/writes real Firestore (F14-F20)
- [x] Supabase Storage — real signed upload URLs for wardrobe photos via
      the `storage-upload-url` Edge Function (F15)
- [x] Supabase Edge Functions — `storage-upload-url` (real, deployed,
      F15); `ai-stylist` (stub only, F23 — see AI note below)
- [x] Firestore security rules — hardened, per-collection field
      validation, proven against the emulator (55/55, F22). **Production
      deploy is deferred pending an explicit go-ahead** (a rule stricter
      than the real app silently rolls back optimistic UI writes and can
      permanently block new-user bootstraps — not something to ship
      without a dedicated pre-deploy data audit)
- [ ] RevenueCat (premium/subscription screens are UI previews only —
      "Free" plan is hardcoded, no entitlement checks) — not in scope of
      the backend-wiring plan, still open
- [ ] Firebase Analytics — not in scope of the backend-wiring plan, still
      open
- [ ] Firebase Crashlytics — not in scope of the backend-wiring plan,
      still open
- [ ] Firebase Remote Config (feature flags / forced update) — not in
      scope of the backend-wiring plan, still open
- [ ] **AI / LLM provider — explicitly PENDING, deferred decision.** The
      `ai-stylist` Edge Function is scaffolded as a stub (F23): real
      token verification, a swappable `getLlmAdapter()` seam that returns
      `null` with zero providers registered, 501 "not configured yet"
      response. No Flutter screen calls it. `StylistCubit`'s existing
      algorithmic generation is untouched. **The user has not chosen an
      LLM provider yet** — this is saved as a standing reminder, to be
      raised once this integration pass is reviewed, not re-litigated
      here.

## Security & Hardening
- [x] Firestore rules audit — done, emulator-proven (F22); production
      deploy gated on an explicit go-ahead (see above)
- [ ] Supabase auth checks — `firebase-auth.ts`'s JWT verification is
      covered by both Edge Functions' tests; a dedicated audit pass
      beyond that hasn't been run
- [ ] Secrets/API key check — not run as a dedicated pass this cycle;
      no secret is committed to the repo (service-account keys and
      Supabase tokens are supplied out-of-band, never placed under `lib/`
      or `supabase/functions/`, per standing project convention)
