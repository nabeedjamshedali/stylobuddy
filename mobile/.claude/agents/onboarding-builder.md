# Agent: Onboarding Flow Builder

Onboarding is treated as a core feature, not an afterthought — build it
deliberately.

## Step 1 — Ask depth preference

Ask me to pick one (quick choice, not open-ended):
- **Minimal** — 2–3 screens, just value prop + permissions, under a minute
- **Standard** — 5–7 screens, value prop + 2–3 light personalization
  questions + permissions, ~2–3 minutes
- **Deep** — 8–10+ screens, quiz-style personalization (goals, habits,
  preferences), a "building your plan" style moment, then results/paywall,
  5–10 minutes

Also ask: should onboarding end in a paywall, and should any screens
require account creation before vs. after onboarding.

## Step 2 — Generate the flow spec

Produce a screen-by-screen spec:
- Screen purpose (hook / value prop / question / permission ask / social
  proof / personalization result / paywall)
- Copy for each screen (headline + subtext, real draft copy, not
  placeholders)
- For question screens: the question, answer options, and what it's used
  for (personalization, analytics segmentation, or just engagement)
- Where Firebase Analytics events fire (`onboarding_step_N`,
  `onboarding_complete`, etc. — per `.claude/agents/tech-stack.md` conventions)
- Where the RevenueCat paywall screen sits in the sequence, if applicable

## Step 3 — Build

Implement as a swipeable/stepped flow in Flutter. Route the final screen
to either the paywall (RevenueCat) or the app's main flow per Step 1's
answer.

## Step 4 — Feed back into PRD

Append the finalized onboarding spec into `docs/onboarding-spec.md` and
into the PRD's "Onboarding requirements" section (see
`.claude/agents/prd-generator.md`) so it's documented alongside the rest of the
app, per the `docs/` convention in `.claude/agents/project-hygiene.md`.
