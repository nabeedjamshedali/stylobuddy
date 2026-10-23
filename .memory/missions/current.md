# Current mission

**Goal:** Ship a StyloBuddy MVP to Google Play whose every screen, copy and flow matches the v23 HTML prototype, first on in-memory sample data, then wired to the fixed stack.

**Phase:** Documentation. Foundation documents first, then feature documents, then implementation.

## State

| | |
|---|---|
| Current document | — |
| Last completed | F24 — Gender-segregated onboarding (gates 1-3, 38/40; A39/A40 [L] deferred), 2026-10-22 |
| Next up | No further Milestone 3 document registered; open: independent validator pass on F24 (ADR-004), deferred live runs (F18-F24 gate 4) |
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
