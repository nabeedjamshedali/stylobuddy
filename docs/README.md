# StyloBuddy — Documentation Index

StyloBuddy is an AI-powered personal stylist and digital wardrobe app (Flutter, Android first, iOS later): users catalogue their own clothes and get outfit suggestions, matching, planning and packing built only from what they own. Stack: Firebase Auth/Firestore/Analytics/Crashlytics/Remote Config, Supabase Storage + Edge Functions, RevenueCat.

This folder is the **contract**. Code follows these documents, never the other way around.

---

## How this repo is built

**Document-driven development.** Every feature exists as one Markdown file in `features/`
before any code is written for it. Each feature document carries its own slice of the
**validation contract**: numbered assertions that define what "correct" means, written *before*
implementation so the tests cannot simply confirm whatever the code happened to do.

The build loop is strictly **one document at a time, in order**:

```
pick next doc  ->  implement it  ->  unit tests  ->  integration tests
      ^                                                     |
      |                                                     v
      +------  mark assertions PASS  <-  live run against the real system
```

A document is not finished until every assertion in it passes against the running system.
See `foundation/05-testing-and-dod.md` for the four gates and `foundation/06-validation-contract.md`
for how assertions are numbered and tracked.

Rules that hold across every document:

- **No document, no code.** About to build something with no document? Stop and write the document. A hook enforces this.
- **One document is one unit of work.** Do not start the next while the current one has failing assertions.
- **Serial, not parallel.** One feature at a time. Only read-only work (search, research, review) runs in parallel.

---

## Foundation documents

The vocabulary and rules every feature document depends on. Written and reviewed **before** any
feature document, because an error here propagates into everything.

| # | Document | What it fixes |
|---|---|---|
| 00 | [Product specification](foundation/00-product-spec.md) | What the product is, who it is for, what it must do |
| 01 | [Tech stack](foundation/01-tech-stack.md) | Languages, frameworks, services, versions |
| 02 | [Architecture](foundation/02-architecture.md) | Layers, boundaries, and what may depend on what |
| 03 | [Domain model](foundation/03-domain-model.md) | The single source of vocabulary: entities, fields, states |
| 04 | [Interface standards](foundation/04-interface-standards.md) | API/CLI conventions, errors, versioning |
| 05 | [Testing and Definition of Done](foundation/05-testing-and-dod.md) | The four gates every feature must pass |
| 06 | [Validation contract](foundation/06-validation-contract.md) | Assertion IDs, rules, and the status ledger |
| 07 | [Security](foundation/07-security.md) | Authentication, authorization, secrets, data protection |
| 08 | [Agent harness](foundation/08-agent-harness.md) | How the project is built: roles, handoffs, hooks, memory |

---

## Feature documents — build order

Implement top to bottom. The order is a dependency order: nothing depends on a document below it.
Start each one from [`features/_TEMPLATE.md`](features/_TEMPLATE.md).

### Milestone 1 — Prototype parity

All 64 routes of the v23 HTML prototype run in the Flutter app on in-memory sample data, verified side by side against the prototype at a 390x844 viewport, with flutter test and flutter analyze clean.

| # | Document | Depends on | Assertions | Status |
|---|---|---|---|---|
| F01 | [Design foundation](features/F01-design-foundation.md) | — | 44 | IN PROGRESS (Gates 1-3 done; live run pending) |
| F02 | [Onboarding and auth](features/F02-onboarding-auth.md) | F01 | 28 | NOT STARTED |
| F03 | [AI stylist](features/F03-ai-stylist.md) | F01 | 34 | NOT STARTED |
| F04 | [Match My Clothes](features/F04-match-my-clothes.md) | F01, F03 | 23 | NOT STARTED |
| F05 | [Home](features/F05-home.md) | F01, F03 | 13 | NOT STARTED |
| F06 | [Wardrobe](features/F06-wardrobe.md) | F01, F03 | 32 | NOT STARTED |
| F07 | [Outfit builder](features/F07-outfit-builder.md) | F01 | 19 | NOT STARTED |
| F08 | [Saved looks](features/F08-saved-looks.md) | F01, F07, F09 | 27 | NOT STARTED |
| F09 | [Calendar](features/F09-calendar.md) | F01 | 22 | NOT STARTED |
| F10 | [Packing](features/F10-packing.md) | F01 | 27 | NOT STARTED |
| F11 | [Shopping](features/F11-shopping.md) | F01 | 17 | NOT STARTED |
| F12 | [Insights](features/F12-insights.md) | F01 | 21 | NOT STARTED |
| F13 | [Profile, settings, premium](features/F13-profile-settings-premium.md) | F01 | 28 | NOT STARTED |

Build order used by the plan ledger: F01, F02, F03, F04, F05, F06, F07, F09, F08, F10, F11, F12, F13 (F09 before F08 because F08 uses `PlannerCubit.startScheduling`), then plan Task 14 (integration and parity pass, no feature document yet).

---

## Document status

Tracked in [`foundation/06-validation-contract.md`](foundation/06-validation-contract.md). A feature is one of:

- `NOT STARTED`: document written, no code
- `IN PROGRESS`: code being written, assertions not all passing
- `DONE`: every assertion passes against the running system

No feature reaches `DONE` on unit tests alone. The live run is required.
