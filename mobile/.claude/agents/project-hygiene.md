# Agent: Project Hygiene — Docs, Tracker, Images, Code Style

Applies throughout the whole build, across every phase in
`.claude/agents/project-kickoff.md`. This is the "keep it clean" layer.

## Docs folder — single source of truth

All non-code project documents go in `docs/` at the project root. Never
scatter markdown files elsewhere. This includes:
- `docs/PRD.md` (from `.claude/agents/prd-generator.md`)
- `docs/design-prompt.md` (from `.claude/agents/design-system.md`)
- `docs/onboarding-spec.md` (from `.claude/agents/onboarding-builder.md`)
- `docs/tracker.md` (see below)
- `docs/image-prompts.md` (see below)
- Anything else generated along the way (research notes, decisions) —
  add it to `docs/`, don't leave it loose in the repo root or in chat only.

## Tracker.md — always on

Create `docs/tracker.md` at project kickoff, before implementation
starts. Structure it by phase/feature, using checkboxes and status tags:

```
# [App Name] — Tracker

## Design
- [x] Design prompt written
- [x] Home screen UI built + Playwright verified
- [ ] Settings screen UI — BLOCKED: waiting on reference screenshot

## Onboarding
- [x] Flow spec written
- [ ] Screens implemented — PENDING

## Core Features
- [x] Auth (Firebase) wired
- [ ] Feature X — IN PROGRESS
- [ ] Feature Y — PENDING

## Integration
- [ ] RevenueCat entitlements
- [ ] Remote Config defaults

## Security & Hardening (end-of-cycle only)
- [ ] Firestore/Storage rules audit
- [ ] Supabase auth checks
- [ ] Secrets/API key check
```

Status vocabulary: `[x]` done, `[ ]` pending, and inline tags
`IN PROGRESS`, `BLOCKED: <reason>` where relevant. Keep item granularity
at "meaningful task," not every file touched.

**Update it immediately after finishing any big task**, then show me the
current state of `docs/tracker.md` (paste the relevant section or the
whole file) so I can see progress at a glance without asking. Don't wait
for me to ask for a status update.

## Image assets — ask, don't assume

Whenever a screen would clearly benefit from a custom image, illustration,
icon set, or graphic (the kind of thing that makes an MVP look 5x more
polished — onboarding illustrations, empty states, app icon, feature
graphics) — **stop and ask me** rather than shipping a placeholder or a
generic stock icon silently.

When you ask, tell me:
- Where it's needed (screen + purpose)
- Whether it's the kind of image an AI image generator could plausibly
  produce well (illustration/icon style) vs. something that needs a real
  photo or professional asset

If it's AI-generatable: write a clear, specific image-generation prompt
(style, subject, color palette matching the design system, aspect ratio)
into `docs/image-prompts.md` under a heading for that screen, and let me
know it's there — don't generate the image yourself unless I ask you to.

## Code style — senior Flutter developer standard

- **UI widgets contain UI only.** No business logic, no direct
  Firebase/Supabase calls, no data transformation inside a `build()`
  method or a screen widget. All of that lives in the Cubit/repository
  layer per `.claude/agents/tech-stack.md`.
- **Every feature gets its own widgets**, broken down properly — don't
  write one giant `build()` method for a screen. Extract repeated or
  logically distinct pieces into named widgets under
  `features/<feature>/widgets/`, even if only used once, when it
  meaningfully improves readability (e.g. `HomeHeader`,
  `HomeItemCard`, `HomeEmptyState`).
- Screens (`view/`) compose widgets and connect to the Cubit via
  `BlocBuilder`/`BlocListener`/`BlocConsumer` — they don't contain
  layout logic beyond arranging those widgets.
- No magic numbers/colors inline — pull from the app's theme/design
  tokens (established in `.claude/agents/design-system.md`'s output).
- Keep widgets small, named clearly by what they render, and free of
  side effects. This is non-negotiable even under MVP speed pressure —
  fast doesn't mean sloppy.
