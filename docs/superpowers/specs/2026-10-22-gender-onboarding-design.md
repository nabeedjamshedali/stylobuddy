# Gender-segregated onboarding — design

## Intent and why

StyloBuddy's onboarding currently shows only male-oriented imagery and
copy (`onboard-00-rack.png` through `onboard-04-outfit.png`, all sourced
from the prototype's male art set). There is no female-equivalent path.
Left as-is, this reads as a men's styling app to half the target
audience — a real business risk (reduced addressable market), not a
cosmetic gap.

The reference prototype (`stylobuddy-prototype/`, mirrored under
`stylobuddy-v23-mobile-icon-final/`) already solved this in an earlier
design pass it never shipped into the Flutter app: `V26-ONBOARDING-HANDOFF.md`
and `V27-FINAL-ASSET-HANDOFF.md` spec a `landing -> gender -> intro (5
slides, branched) -> personalize -> auth -> home` flow, with real
generated artwork for both genders already sitting unused in
`stylobuddy-prototype/assets/onboarding/v26/` and `v27/`. This design
finishes that work inside the current Flutter codebase, adapting (not
blindly copying) the prototype's own plan and assets.

## Goals

- A new gender-choice step early in onboarding (male / female).
- Every image-bearing intro slide after that point shows gender-matched
  artwork; the occasion-picker slide (slide 4) stays shared/neutral, as
  it already is in both this app and the prototype's own plan.
- The female path gets a more confident/aspirational copy tone (not just
  different pictures) per the user's "more interactive and engaging"
  request — see Copy direction below.
- Both paths converge back to the existing `personalize -> auth` flow
  unchanged.
- The choice is remembered: a signed-in user's `Profile` carries it, the
  same way occasion/style choices made during onboarding already survive
  into the post-sign-in Firestore bootstrap (`PendingOnboardingSelections`
  precedent).

## Non-goals (explicitly out of scope for this change)

- No interactive style quiz / extra personalization questions beyond the
  existing occasion-picker slide. That's a separate, gender-agnostic
  feature (ties into the still-pending AI stylist/LLM provider decision)
  and was deliberately deferred during brainstorming — bolting it only
  onto the female path would make the two flows structurally uneven.
- No regeneration of new AI art as a first move. The existing `v27`
  female asset set is already a polished fourth design iteration (per
  the prototype's own QA notes), not a rough sketch — reuse first,
  regenerate only the specific images that don't hold up once placed in
  the real app (see "what's left to the builder").
- No change to the male path's existing images or copy.
- No app-wide, post-onboarding gender theming (colors, fonts, layout).
  Scope stops at the onboarding screens; `Profile.gender` is stored so a
  future feature (e.g. gendered recommendation tuning) can read it later,
  but this change does not add any such consumer itself.
- No forced choice: like every other onboarding step in this app, "Skip
  introduction" on the welcome screen must still work and must not
  require a gender answer first (guest/skip users keep working exactly
  as today — gender stays unset until/unless they go through intro).

## Anti-goals (would count as failure even if technically working)

- A female path that is visually weaker, slower, or more cluttered than
  the male path — the whole point is parity-or-better, not a token
  afterthought bolted on.
- Two onboarding flows that silently drift out of sync over time because
  they're implemented as fully separate slide lists instead of one
  parametrized flow.

## Constraints

- Must slot into the existing dual-mode repository pattern
  (`InMemoryProfileRepository` / `FirestoreProfileRepository`,
  `docs/superpowers/specs/2026-10-19-backend-architecture.md` D2) — no
  new persistence mechanism.
- Must follow this repo's own document-driven workflow
  (`docs/README.md`): this design doc is the brainstorming-stage
  artifact; the actual build still goes through a numbered feature
  document (next available: F24) with its own validation-contract
  assertions, written by `doc-worker`, before any code — per
  `CLAUDE.md`'s "no document, no code" rule and the user's own
  instruction to run the full SDLC through this project's established
  pipeline every time.
- Must not touch `stylobuddy-prototype/` or
  `stylobuddy-v23-mobile-icon-final/` — reference-only, never edited.

## Decisions made (the "how", already settled)

**D1 — Gender lives on `Profile`, not a separate model.**
Add a `gender` field to `ProfileState`/`FirestoreProfileRepository`
(nullable: `'male' | 'female' | null`), following the exact pattern
already used for `climate`/`plan`/`billingCycle` (string field,
`_stringField` read helper, included in `_toFirestore`). `null` means
"never chosen" (guest who skipped, or pre-existing signed-in users from
before this change) — existing profiles must not break.

**D2 — Carried across sign-up the same way occasion/style choices are.**
`OnboardingCubit` gets a `setGender(String)` method mirroring
`toggleOccasion`/`toggleChip`: updates `OnboardingState.gender` and
forwards it into `PendingOnboardingSelections` (extended with a
`gender` slot alongside the existing occasions/chips union), consumed
once at Firestore bootstrap time exactly like occasions are today. This
reuses an already-proven mechanism rather than inventing a new one.

**D3 — New screen, new route, before `/intro`.**
A `GenderChoiceView` (prototype's own naming: "gender") becomes a new
step in `onboardingRoutes`, reachable from `WelcomeView`'s "Get
Started" (replacing today's direct `context.go(AppRoutes.intro)`).
`OnboardingCubit.start()` still resets slide state the same way; the
new screen writes the choice via `setGender` before navigating into
`/intro`.

**D4 — One parametrized slide list, not two copy-pasted ones.**
`intro_slide.dart`'s `introSlides` const list becomes a function of
gender: each image-bearing slide gets a `maleImage`/`femaleImage` pair
(occasion slide unaffected). `IntroView` reads `state.gender` to pick
which asset and which copy variant to render. This satisfies the
anti-goal above — one flow, parametrized, not two drifting lists.

**D5 — Asset source: reuse prototype `v27` set, adapted.**
Pull `female-wardrobe.png` / `female-closet.png` / `female-match.png` /
`female-finale.png` (and the matching `male-*` ones already informally
in use) from `stylobuddy-prototype/assets/onboarding/v27/` into this
app's own asset pipeline (`assets/` + the existing asset-registry
convention from `project-hygiene.md`), re-exported/optimized as needed.
`female-finale.png` was spot-checked during brainstorming and is a
production-quality flat-lay (blouse, trousers, bag, heels, jewelry,
watch) — no regeneration needed there. The remaining three get the same
spot-check before the feature doc locks in asset filenames.

**D7 — The gender screen is not skippable (my call).** The prototype's
own plan already treats this as mandatory ("choose Male or Female before
the 5-step flow"), and it keeps the implementation simpler: every
image-bearing `IntroSlide` can assume `state.gender` is always set by
the time it's read, with no `gender == null` fallback rendering path to
build, test, or maintain. This doesn't conflict with the "no forced
choice" non-goal above, which only guarantees "Skip introduction" (the
whole onboarding flow) keeps working — a guest who skips never reaches
the gender screen at all.

**D8 — `onboarding_back_scope.dart` gets a branch for the new route (my
call).** This widget already special-cases `/intro` and `/personalize`
for Android hardware-back; the new gender-screen route gets the same
treatment, following its existing pattern exactly. Mechanical, not a
product decision — no open question here.

**D6 — Copy direction.**
Male copy stays as-is (functional: "Organize every outfit..."). Female
copy shifts to a more confident/self-expression register per the user's
"more engaging" ask — e.g. leaning on words like "effortless," "your
style, your rules," "dress for how you want to feel" rather than purely
functional wardrobe-management language. Exact strings are drafted in
the feature document, not here, so they can be reviewed as a batch.

## What's left to the builder (feature-doc stage)

- Exact wording for all 4 female-path slide titles/descriptions (D6) —
  drafted in the F24 feature doc, reviewed against the male copy for
  tone parity before lock-in.
- Final filenames/paths for the 4 reused images once pulled into
  `assets/` and spot-checked against D5's quality bar; generate a
  replacement prompt (for the user to run through ChatGPT) for any one
  of the four that doesn't hold up at in-app size/crop — not expected to
  be all four.
- Exact visual design of the new gender-choice screen itself (two
  tappable cards, following `OptionTile`/existing onboarding visual
  language) — the prototype's own `male-card.png`/`female-card.png`
  assets exist as a starting point but the actual layout is an
  implementation-stage call, not a brainstorming-stage one.
- Whether `OnboardingCubit.back()` from slide 0 of `/intro` should return
  to the new gender screen or past it to `/welcome` — small UX call, left
  to the feature doc (the `onboarding_back_scope.dart` branch itself is
  settled by D8 above; only the exact target is open).
