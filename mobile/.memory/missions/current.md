# Current mission

**Goal:** Ship a StyloBuddy MVP to Google Play whose every screen, copy and flow matches the v23 HTML prototype, first on in-memory sample data, then wired to the fixed stack.

**Phase:** Documentation. Foundation documents first, then feature documents, then implementation.

## State

| | |
|---|---|
| Current document | — |
| Last completed | F25 — Firebase Analytics + Remote Config / forced update (gates 1-3, 43/46; A44-A46 [L] deferred), 2026-10-29. Before it: F24 (gates 1-3, 38/40), 2026-10-22 |
| Next up | Independent validator pass on F25 (ADR-005) and F24 (ADR-004); owner publishes `scripts/remoteconfig.template.json` per `docs/runbooks/remote-config.md`; deferred live runs (F18-F25 gate 4). F26 (real AI stylist) doc present in the tree, not yet registered by this session |
| Blockers | none |

## Standing constraints

- Serial execution: one feature document at a time, one worker at a time.
- Assertions are written before implementation, always.
- No feature is DONE until its assertions pass against the running system.
- The full regression suite is green before starting and after finishing each document.

## Notes

Once written, foundation documents are the contract. Amending one is a deliberate act, with
the consequences traced through every feature document that depends on it, never an edit made
in passing to get a build through.
