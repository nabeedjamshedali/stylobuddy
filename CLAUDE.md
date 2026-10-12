# Project Config — Fast MVP Flutter Apps

This file is always loaded. It defines the fixed stack and points to the
workflow agents in `.claude/agents/`. Read the relevant agent file before starting
the matching phase of work — don't just work from memory of this file.

## Who I am / how I work

I build small-to-medium Flutter apps fast, to validate ideas. I ship
Android first, iOS later. I mostly clone/adapt an already-proven app UI
(via a reference screenshot) rather than inventing UI from scratch, and
I add a differentiation angle on top. Speed and a working MVP in the
store matter more than architectural purity.

## Fixed tech stack — do not ask, do not suggest alternatives

| Concern | Choice |
|---|---|
| App framework | Flutter (Android first, iOS later) |
| Auth | Firebase Auth |
| Storage (images/files) | Supabase Storage — URL saved to Firestore when it's user-specific |
| Database | Firestore |
| Backend logic / edge functions | Supabase Edge Functions |
| Payments / subscriptions | RevenueCat |
| Analytics | Firebase Analytics |
| Crash reporting | Firebase Crashlytics |
| Remote config / feature flags / forced update | Firebase Remote Config |

Package details, setup steps, and conventions for each of these live in
`.claude/agents/tech-stack.md`. Wire all of them into every new project by
default unless I explicitly say to skip one.

## Credentials & automation

When a new project needs Firebase or Supabase set up (new project,
config, auth providers, storage buckets, Firestore rules, edge
functions, etc.), ask me for:
- **Firebase**: a service account key (JSON)
- **Supabase**: an access token

Once I provide it, do the setup yourself end-to-end — creating the
project, enabling the right services, configuring auth providers,
setting up Storage buckets, writing security rules, deploying edge
functions — via the Firebase/Supabase CLIs or management APIs. Don't
hand me manual console click-through steps unless something genuinely
requires me (e.g. OAuth consent screen branding, App Store/Play Store
listing details).

## Standard project workflow

When I say **"start"**, follow `.claude/agents/project-kickoff.md` — it runs
end-to-end on its own, only stopping at the specific points listed in
that file (app name, screenshot, onboarding preference, credentials,
image calls, build confirmation, my click-through). It sequences:

1. **Design** — reference screenshot → design prompt → build UI → visually
   verify with Playwright. See `.claude/agents/design-system.md`.
2. **PRD** — ideation conversation → written PRD. See `.claude/agents/prd-generator.md`.
3. **Onboarding** — ask my preference, then generate the onboarding flow.
   See `.claude/agents/onboarding-builder.md`.

Throughout all of the above, follow `.claude/agents/project-hygiene.md` — it
covers the `docs/` folder convention, the always-on `docs/tracker.md`,
the image-asset workflow, and the required Flutter code style. Read it
once at project start and keep applying it, don't treat it as optional.

## General ground rules

- Don't ask me which stack to use — it's fixed above.
- Don't stop between steps to check in — only stop at the specific
  input points defined in `.claude/agents/project-kickoff.md`.
- Bias toward shipping a working MVP over polishing infrastructure.
- Flag clearly if something is Android-only vs. needs extra work for iOS,
  since iOS ships later for me.
