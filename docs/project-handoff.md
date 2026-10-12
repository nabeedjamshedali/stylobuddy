# StyloBuddy — Project Handoff

Written 2026-10-13, for whichever Claude Code session picks this project
up next. This repo already has the `flutter-app-dev-agent` kit installed
(`CLAUDE.md` + `.claude/agents/*.md`) — read those first if you haven't;
this doc is the "where we actually are" status report layered on top.

## What exists right now

- **Location**: `C:\workspace\my projects\mobile_applications\stylobuddy`
- **Scaffold**: `flutter create` done, org `com.stylobuddy`, package
  `com.stylobuddy.stylobuddy`. Feature-based folder structure applied
  (`lib/core/`, `lib/shared/`, `lib/features/`) per
  `.claude/agents/tech-stack.md`.
- **State management**: `flutter_bloc` (Cubit) added, one Cubit built so
  far (`OnboardingCubit`).
- **Built screens**: splash screen + a 3-screen onboarding flow +
  a placeholder "onboarding complete" stub screen. That's it — no PRD,
  no auth, no core app features, no backend wiring. This was a
  deliberate scope cut (see "What was explicitly skipped" below).
- **Git**: initialized, 2 commits so far (scaffold, then wiring in the
  real hero photo).
- **Verification done**: `flutter analyze` clean, `flutter test` passing
  (one smoke test), manually verified in Chrome via
  `flutter run -d chrome` — not yet verified on an Android
  emulator/device.

## How this got built (context, not instructions)

The user gave one reference shot (Dribbble: ["Next Generation Fashion
App Design"](https://dribbble.com/shots/27604984-Next-Generation-Fashion-App-Design),
not directly fetchable — it's behind an AWS WAF bot challenge, and this
session had no browser tool, so the user pasted the screenshot
directly) showing 3 app screens: a "Redefine Your Style with AI" hero
screen, an "AI Stylist" 360°-view screen, and a product detail screen.
The user asked to turn that into a Flutter splash + onboarding flow with
"exact same images and UI," explicitly scoped to **not** build out the
rest of the app yet ("I changed a lot of stuff").

The 3 reference screens were mapped onto 3 onboarding pages (not used
as literal in-app screens):

| Onboarding page | File | Reference screen it mirrors |
|---|---|---|
| 1. Hero / value prop | `lib/features/onboarding/widgets/hero_upload_page.dart` | "Redefine Your Style with AI" hero screen |
| 2. AI Stylist | `lib/features/onboarding/widgets/ai_stylist_page.dart` | 360° AI Stylist screen |
| 3. Curated Picks | `lib/features/onboarding/widgets/curated_picks_page.dart` | Product detail screen |

## Design system (already encoded as tokens — don't re-derive, reuse)

Live in `lib/core/theme/`:
- `app_colors.dart` — dark background (`#0E0C0B`), warm coral/amber
  radial-glow gradient (`heroGradient`), accent orange (`#FF6B35`),
  text color scale.
- `app_text_styles.dart` — Manrope (via `google_fonts`), bold/tight
  headlines, accent-colored keyword spans.
- `app_theme.dart` — pulls the above into a single dark `ThemeData`.

Shared visual components in `lib/shared/widgets/`:
- `GradientBackdrop` — the signature warm-glow-fading-to-black backdrop.
- `PrimaryPillButton` — full-width gradient pill CTA with a circular
  white arrow glyph, used for every onboarding "Next"/"Get Started".
- `PlaceholderPhoto` — styled gradient+icon stand-in for a missing real
  photo/illustration asset (see next section).

**Convention**: no inline hex colors or raw `TextStyle`s in screens/
widgets — always pull from these tokens. Keep following this.

## Image assets — status (per `project-hygiene.md`'s "ask, don't assume")

- `assets/images/onboarding_hero_portrait.png` — **real asset**, the
  actual cutout photo from the reference shot (user supplied it
  directly), wired into onboarding page 1 (`hero_upload_page.dart`).
- Onboarding page 2 (AI Stylist 360° view) and page 3 (jacket product
  photo) are **still using `PlaceholderPhoto`/icon stand-ins** — the
  user has not yet supplied those two cutouts. **Ask the user for them
  before treating onboarding as visually "done"**, or ask whether to
  generate AI stand-in images instead (and if so, write prompts into
  `docs/image-prompts.md` and ask before actually generating, per
  `project-hygiene.md`).

## What was explicitly skipped (don't assume these are stale/forgotten — they were never started)

Per the user's explicit scope choice ("scaffold only, no backend
wiring"), none of the following from the kit's normal kickoff flow has
happened yet:
- `docs/PRD.md` (idea, target user, MVP loop, monetization) — not
  written. The app's actual product idea/core loop was never discussed
  beyond "fashion app, AI styling, redesign of StyloBuddy."
- `docs/onboarding-spec.md` — the onboarding flow above was designed
  ad hoc from the reference shot, not through the kit's normal
  "ask depth preference → write spec" flow (`onboarding-builder.md`).
  It's 3 screens (closer to "Minimal"), no personalization questions,
  no paywall screen. Confirm with the user whether this is final or
  whether they want the full onboarding-builder flow run properly
  (deeper personalization, paywall placement, etc).
- `docs/tracker.md` — not created.
- Firebase (Auth/Firestore/Analytics/Crashlytics/Remote Config),
  Supabase (Storage/Edge Functions), RevenueCat — **none wired in**.
  No service account key or Supabase token has been requested yet.
- No real app features (home feed, AI stylist feature, cart/checkout,
  etc.) exist — just the splash/onboarding shell and a stub
  "onboarding complete" screen (`lib/features/home/view/home_placeholder_view.dart`)
  as the landing point.

## Suggested next steps (confirm with user before running, per kit rules)

1. Resolve the 2 missing image assets (ask first).
2. Run `.claude/agents/prd-generator.md`'s ideation questions properly —
   the user said they "changed a lot of stuff" about the idea, so don't
   assume the old `stylobuddy` web/research-paper project's scope still
   applies; ask fresh.
3. Once the idea is confirmed, decide whether the existing 3-screen
   onboarding stands or gets rebuilt via `onboarding-builder.md`'s
   proper depth-preference flow.
4. Only then move to Step 5/6 of `project-kickoff.md` (wire the stack,
   propose a build order, start building real features) — per
   `project-kickoff.md`, stop and confirm build order with the user
   before starting implementation.
5. Firebase/Supabase credentials: ask for them when first needed, don't
   block earlier steps on it.

## Running it

```
cd "C:\workspace\my projects\mobile_applications\stylobuddy"
flutter run -d chrome   # fastest visual loop
flutter run              # Android, once a device/emulator is attached
```
