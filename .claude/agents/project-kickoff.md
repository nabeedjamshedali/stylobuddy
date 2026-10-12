# Agent: Project Kickoff

Trigger: I just say **"start"**. That's it — no need for me to say
"let's begin a new project" or anything more formal. When I say "start,"
run the full sequence below end-to-end, only stopping when a step
genuinely requires input from me (marked below). Don't pause between
steps to ask "should I continue?" — keep going automatically.

The specific points where you must stop and ask me something:
- App name / package identifier (Step 0a)
- Reference screenshot(s) (Step 1)
- Idea one-liner + differentiation, if not already given (Step 2)
- Onboarding depth preference (Step 3)
- Firebase service account key / Supabase access token, when first
  needed (per `.claude/agents/tech-stack.md`)
- Image asset calls, when they come up (per `.claude/agents/project-hygiene.md`)
- Build order confirmation before implementation starts (Step 6)
- My click-through feedback (Step 7)

Everything else — scaffolding, hygiene setup, writing the design prompt,
generating the PRD, wiring the stack, updating the tracker — just do it,
then move to the next step. Batch your questions where possible (e.g.
ask for app name + screenshot together) instead of one message per
question, so I'm not stopping every 30 seconds.

## Phase order — MVP speed over repeated hardening

The whole point of this workflow is to get a working MVP into the store
fast to validate the idea. That means:

**Idea → Design → Implementation → Integration → User check → Security & polish (once, at the end)**

- Do **not** run security reviews, hardening, or heavy testing loops
  after every change during Steps 1–5 below. That's what slows down
  MVP validation.
- "User check" (Step 6) means *I* click through the built app and flag
  what's broken or wrong — that's the fast feedback loop, not a formal
  test suite.
- Only after I've signed off on the app working end-to-end do you run
  the full security/testing pass (Step 7) — Firestore/Storage rules
  audit, Supabase function auth checks, API key exposure check, RevenueCat
  entitlement checks, basic input validation, crash-free sanity pass.
  Do this once, thoroughly, right before store submission — not
  incrementally throughout the build.

## Step 0a — Create the Flutter project yourself

Don't ask me to run `flutter create` manually. Do it yourself:

1. Ask me for the app name (and package/bundle identifier if I have a
   preference — otherwise propose one, e.g. `com.<mystudio>.<appname>`,
   and confirm with me).
2. Run `flutter create` with that name/org in the appropriate working
   directory. Android is the active target; iOS scaffolding stays at
   Flutter's default, no extra iOS setup work yet, per the Android-first
   rule at the end of this file.
3. Immediately apply the feature-based folder structure from
   `.claude/agents/tech-stack.md` on top of the generated skeleton (create
   `lib/core/`, `lib/shared/`, `lib/features/`), add `flutter_bloc` to
   `pubspec.yaml`, and remove the default counter-app boilerplate.
4. Init git and make an initial commit of the clean scaffold, unless I
   say otherwise.

Only move to Step 0b once the project exists and is scaffolded.

## Step 0b — Set up hygiene

Create the `docs/` folder and `docs/tracker.md` per
`.claude/agents/project-hygiene.md` — log "Project scaffolded" as the first
completed tracker item. Every subsequent step's outputs get filed into
`docs/`, and the tracker gets updated as work completes.

## Step 1 — Reference screenshot(s)

Ask me for one or more screenshots of an existing app whose UI/flow is
close to what I want. Don't proceed to design work without at least one
screenshot or an explicit "no reference, design from scratch."

## Step 2 — Quick idea capture

Ask me, briefly, for:
- One-line description of the app idea
- What differentiation I want vs. the reference app (if any yet — it's
  OK if I say "not sure, suggest some")

Then hand off to `.claude/agents/prd-generator.md` to turn this into a full PRD
through conversation. Don't block design work waiting on the full PRD —
they can happen in parallel, but the PRD should be finished before I
consider the MVP scope "locked."

## Step 3 — Onboarding preference

Ask me (this can be a quick multiple-choice, not open-ended):
- Onboarding depth: minimal (2–3 screens) / standard (5–7) / deep
  (8–10 min, personalization-quiz style)
- Whether onboarding should end in a paywall

Hand off to `.claude/agents/onboarding-builder.md` to generate the actual flow.

## Step 4 — Design

Hand off to `.claude/agents/design-system.md` using the screenshot(s) from Step 1
and the differentiation notes from Step 2. This produces the design
prompt, the built UI, and the Playwright-verified visual iteration loop.

## Step 5 — Wire the stack

Apply `.claude/agents/tech-stack.md` to the scaffolded project.

## Step 6 — Implementation & integration

Once PRD, design, onboarding, and stack are in place, propose a build
order (core flow first, then onboarding, then paywall, then
analytics/crashlytics/remote config wiring) and confirm with me before
starting. Build feature-by-feature per the Cubit + feature-based
structure and code style in `.claude/agents/tech-stack.md` and
`.claude/agents/project-hygiene.md`. Integrate all services (Firebase, Supabase,
RevenueCat) as each feature needs them — don't defer wiring to the end.
**RevenueCat at this stage is Phase 1 only** (SDK + paywall UI against
placeholder entitlement checks) per `.claude/agents/tech-stack.md` — do not try
to create real products/entitlements yet. Watch for image-asset needs
per `.claude/agents/project-hygiene.md` and ask rather than placeholder silently.
Update `docs/tracker.md` after each big task and show me its current
state.

## Step 7 — User check

Hand the running app to me to click through. Fix what I flag. Iterate
quickly here — this is still the fast loop, not the hardening pass.

## Step 8 — Security & hardening (once, at the end)

Only after Step 7 sign-off, run a single thorough pass:
- Firestore security rules audit
- Supabase Storage bucket access policies + Edge Function auth checks
- No API keys/secrets/service account keys committed or exposed client-side
- RevenueCat entitlement checks can't be bypassed
- Basic input validation on any user-submitted data
- Crash-free sanity check (Crashlytics wired and clean)

Report findings and fix before store submission. This is the only point
in the flow where testing/security work happens — don't reintroduce it
earlier in future runs of this workflow.

## Step 9 — RevenueCat Phase 2 (separate branch, after closed testing)

This is a later, separate trigger — not part of the initial "start" run.
When I say the app has cleared its 14-day Google Play closed testing
period and I'm ready to set up real payments:

1. Create a new git branch off the current state (not `main`/the MVP
   branch) dedicated to this work.
2. Create the real products in Google Play Console.
3. Create matching products/offerings/entitlements in RevenueCat.
4. Wire the paywall (built in Step 6) to the real entitlement checks,
   replacing the Phase 1 placeholder logic.
5. Update `docs/tracker.md` to reflect RevenueCat Phase 2 completion.

Don't run this step during the initial MVP build — only when I
explicitly say testing has cleared and I'm ready for real products.
