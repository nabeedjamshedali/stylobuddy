# 08 — Agent Harness

> How StyloBuddy is *built*. This document is about the development process, not the
> product. Depends on `05-testing-and-dod.md` and `06-validation-contract.md`.

---

## 1. Why a harness

Built naively by a single long agent session, quality decays: context fills, earlier decisions are
forgotten, tests get written to match whatever the code did, and by the thirtieth feature the
architecture has drifted from the one in `02-architecture.md`.

The harness makes that drift structurally impossible rather than a matter of diligence.

> **The harness provides the discipline; the models provide the intelligence.**

Deterministic code handles bookkeeping: blocking code without a document, blocking a change that
crosses a boundary, blocking a finish without a handoff. Everything that needs judgement stays in
prompts, so the system improves as models improve instead of being locked into a state machine.

---

## 2. Three roles

| Role | Does | Never |
|------|------|-------|
| **Orchestrator** | Reads the docs index, picks the next document, scopes the work, reviews handoffs, decides whether to advance or create follow-up work | Writes implementation code |
| **Worker** | Implements exactly one feature document, writes its tests, runs them, writes a structured handoff | Decides its own scope; starts a second document |
| **Validator** | Verifies a completed feature against its assertions, adversarially | Reads the implementation before writing its checks |

**Separation is the point.** An agent that wrote the code is biased toward believing it works. A
fresh agent with clean context and the document in front of it, but not the diff, finds what the
author could not. This is the creator-verifier pattern, the same reason humans do code review.

---

## 3. Directory layout

```
.claude/
├── agents/
│   ├── orchestrator/mission-orchestrator.md
│   ├── workers/          doc-worker.md + one worker per layer
│   └── validators/       scrutiny-validator · behaviour-validator · contract-auditor · boundary-auditor
├── hooks/                doc_exists · boundary_guard · assertion_coverage · handoff_guard
├── harness.json          hook configuration: code paths, test paths, boundary rules
└── settings.json         wires the hooks into Claude Code

.memory/
├── missions/             the active mission
├── handoffs/             one structured handoff per completed feature
├── decisions/            architecture decision records
└── contracts/            ledger.json, machine-readable assertion status

docs/
├── README.md             index and build order
├── foundation/           00–08: the contract every feature depends on
└── features/             one document per feature, from _TEMPLATE.md
```

---

## 4. The workers

Specialised by layer, because the constraints differ sharply between layers.

| Worker | Owns | Key constraint |
|---|---|---|
| core-worker | `lib/core/` | Tokens, router and asset registry only; no backend SDKs |
| shared-worker | `lib/shared/` | Cross-feature UI/models only; widgets are UI-only and mirror prototype CSS |
| feature-worker | `lib/features/<feature>/` | Cubit-only state; widgets never touch data; screens match the prototype exactly |
| doc-worker | `docs/`, `.memory/` | Writes feature documents and assertions before any code |

A worker owns its layer and nothing else. Work that spans layers is split by the orchestrator into
one task per worker, done serially.

---

## 5. The validators

Run after each feature is implemented. None has seen the implementation before writing its checks.

- **`scrutiny-validator`**: the conventional pass. Full test suite, type checks, lints, and a
  focused review of each changed module against the document. Fast.
- **`behaviour-validator`**: the pass that matters. Boots the real system and exercises the
  feature the way a user would. Slow, because it waits on real execution, and that is what stops
  drift.
- **`contract-auditor`**: confirms every assertion has a test naming its ID, no assertion was
  weakened, and the ledger matches reality.
- **`boundary-auditor`**: confirms no layer depends on what it must not, across the whole codebase.

---

## 6. Structured handoffs

A worker never finishes by saying "done". It writes `.memory/handoffs/{FEATURE_ID}.md` from
`.memory/handoffs/_TEMPLATE.md`, recording what was completed, **what was not**, the commands run
with their exit codes, issues discovered, and the assertion tally.

The handoff lets the orchestrator catch problems at a milestone boundary and scope corrective work,
rather than hoping an agent remembered something. Forcing it to be written down is the mechanism:
the `handoff_guard` hook blocks the session from ending without one.

---

## 7. Serial execution

**One feature document at a time. One worker at a time.**

Parallel writers conflict, duplicate effort and make inconsistent architectural decisions; the
coordination overhead eats the throughput gain. What *does* run in parallel is read-only work:
searching the codebase, researching an external API, reviewing several modules at once, and
independent validator passes on a feature that is already complete.

---

## 8. Model selection per role

| Role | Wants |
|------|-------|
| Orchestrator | Slow, careful reasoning. Planning and decomposition quality dominate. |
| Worker | Code fluency and speed on high-volume, well-specified work. |
| Validator | Precise instruction following, ideally from a different model than the worker, so it does not share the same blind spots. |

Model choice is set per agent in its frontmatter and revisited deliberately.

---

## 9. Hooks

Hooks are the only part of the harness that is not a prompt. They handle bookkeeping and blocking,
and nothing that requires judgement. All four are configured by `.claude/harness.json`.

| Hook | Fires | Blocks when |
|------|-------|-------------|
| `doc_exists` | Before creating a file under a code path | No feature document with numbered assertions exists |
| `boundary_guard` | After editing a file in a guarded layer | The file breaks a boundary rule in `harness.json` |
| `assertion_coverage` | After editing a test file | Never; it reports which assertions still lack tests |
| `handoff_guard` | When the session tries to stop | Code changed but no complete handoff was written |

Every hook fails open: a malformed config or an unexpected error allows the action rather than
blocking it, and a broken `harness.json` is reported, not silently ignored. Set `"enabled": false`
in `harness.json` to switch all four off.

---

## 10. Memory

`.memory/` is durable state across sessions. An architectural decision made mid-build is recorded
in `decisions/` immediately: the cost of losing one is that a later agent silently re-decides it
the other way.

---

## 11. The loop

```
   ORCHESTRATOR reads docs/README.md, picks the next document
        │
        ▼
   Is the document complete, with assertions written?  ── no ──> doc-worker writes it
        │ yes
        ▼
   WORKER implements it, writes tests, runs them, writes a handoff
        │
        ▼
   VALIDATORS run: scrutiny · behaviour · contract · boundary
        │
        ├── fail ──> orchestrator scopes follow-up work, worker fixes, re-validate
        │
        ▼ pass
   Update the ledger; full regression suite green
        │
        ▼
   Next document
```

No document is skipped, and none is left half-done to start another.
