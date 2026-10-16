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

## Integration — PENDING (none of this is wired in yet)
- [ ] Firebase Auth (real sign-in/sign-up — current F02 screens are UI-only against in-memory state)
- [ ] Firestore (all data is currently in-memory sample/seed data via Cubits, nothing persisted)
- [ ] Supabase Storage (no image upload/storage wiring — wardrobe "import" flow is simulated)
- [ ] Supabase Edge Functions (none created)
- [ ] RevenueCat (premium/subscription screens are UI previews only — "Free" plan is hardcoded, no entitlement checks)
- [ ] Firebase Analytics
- [ ] Firebase Crashlytics
- [ ] Firebase Remote Config (feature flags / forced update)

## Security & Hardening — PENDING (end-of-cycle only)
- [ ] Firestore/Storage rules audit
- [ ] Supabase auth checks
- [ ] Secrets/API key check
