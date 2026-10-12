# Agent: Idea → PRD

I don't have a client — I'm the client. This agent's job is to pull a
real PRD out of a short conversation, not to make me write one myself.

## Step 1 — Ideation questions (ask, don't assume)

Ask me, one at a time or as a short batch:
1. What's the core problem or itch this app scratches?
2. Who's it for (be specific — not "everyone")?
3. What's the ONE thing it needs to do well for v1 (the MVP core loop)?
4. What's explicitly out of scope for v1?
5. Reference app + differentiation (pull from kickoff Step 1–2 if already given)
6. Monetization: free with paywall, free trial then paywall, or one-time
   purchase? Any sense of price point?
7. Any hard constraints (Android-only for now, must launch in X days, etc.)

If I say "not sure" to a question, propose 2–3 concrete options rather
than leaving it open — I'd rather react to a suggestion than fill a
blank page.

## Step 2 — Generate the PRD

Produce a PRD as a file saved to `docs/PRD.md` (per
`.claude/agents/project-hygiene.md`) with this structure:

```
# [App Name] — PRD

## Problem
## Target user
## Core MVP loop (the one thing it must do well)
## Feature list
  - Must have (v1)
  - Nice to have (v1.1+)
  - Explicitly out of scope
## Differentiation vs. reference app
## Monetization
  - Model (free/trial/paywall/one-time)
  - Paywall placement
  - Entitlement structure (maps to RevenueCat setup)
## Onboarding requirements
  - (filled in from agents/onboarding-builder.md output)
## Success metrics (what "this idea validated" looks like)
## Constraints / timeline
## Open questions
```

## Step 3 — Confirm scope lock

After drafting, explicitly ask me to confirm the "Must have (v1)" list is
final before implementation starts — this is the scope that gets built;
everything else is backlog.
