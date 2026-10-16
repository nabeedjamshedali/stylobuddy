# .memory

Durable state for the StyloBuddy build harness. It survives across sessions; see
`docs/foundation/08-agent-harness.md` for how it is used.

| Directory | Holds |
|-----------|-------|
| `missions/` | The active mission: current document, progress, blockers |
| `handoffs/` | One structured handoff per completed feature, kept permanently |
| `decisions/` | Architecture decision records: what was decided, what was rejected, and why |
| `contracts/` | `ledger.json`, the machine-readable assertion status |

## Why decisions are written down

A decision that is not recorded gets silently re-decided the other way by a later agent with
no memory of the first one. That is how architecture drifts across a long build. Record it
when you make it, not afterwards.

## Handoffs

A worker never finishes by saying "done". The `## Not completed` and `## Issues discovered`
sections are the ones that matter: they let the orchestrator catch a problem at a milestone
boundary instead of at the end. Start from `handoffs/_TEMPLATE.md`.
