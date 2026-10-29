# 06 — Validation Contract

> How correctness is defined, numbered and tracked across the whole project. Depends on
> `05-testing-and-dod.md`. This document also holds the live status ledger.

---

## 1. What a validation contract is

Before any implementation, the project writes down what *done* means as a numbered list of
assertions. Each feature is assigned the assertions it must satisfy, and the features together
must cover every one.

This breaks the circularity of agent-written tests. If the same process writes the code and then
its tests, the tests describe the code rather than the requirement, and both can be wrong together.
Writing assertions first, in the document, makes them independent of the implementation.

---

## 2. Assertion format

Assertions live in section 11 of each feature document:

```
{FEATURE_ID}-A{NN}  [gate]  {statement}
```

- `F07-A03` is feature F07, assertion 3
- IDs are permanent. A retired assertion's number is never reused.
- A statement is **objectively checkable**. "Handles errors gracefully" is not an assertion;
  "returns 404 with code `not_found` for another account's record" is.
- Each names its gate: `[U]` unit, `[I]` integration, `[L]` live run.

Examples:

```
F07-A01  [U]  An expired token is rejected even when its signature is valid
F07-A02  [I]  POST /sessions with a wrong password returns 401 and writes no session row
F07-A03  [L]  Logging in through the running system, then calling a protected endpoint,
              succeeds; the same call with the token removed returns 401
```

---

## 3. Rules

1. **Assertions are written before implementation.** A document with an empty section 11 is not ready to build.
2. **Every assertion has a test whose name contains its ID**: `test_F07_A03_...`. This is how coverage is verified mechanically.
3. **An assertion is never weakened to make a build pass.** If it is genuinely wrong, amend it in the document with a dated note, and re-derive the implementation.
4. **Behavioural assertions are required.** Every feature has at least one `[L]` assertion exercised against the running system.
5. **Validation is adversarial.** Whoever verifies a feature is not whoever implemented it, and does not read the implementation before writing the check. See `08-agent-harness.md`.

---

## 4. Global assertions

Assertions that apply to **every** feature and are not restated in each document. Checked by a
shared test suite where possible. Add the ones true for this project:

| ID | Gate | Statement |
|----|------|-----------|
| `G-A01` | U | No screen throws when a referenced wardrobe item id no longer exists (resolved via `WardrobeCubit.itemOrFallback`) |
| `G-A02` | U | Text inputs that are blank or whitespace-only are rejected with the prototype's toast and leave state unchanged |
| `G-A03` | U | No file under a guarded UI path imports a repository or backend SDK (harness `boundary_guard`) |
| `G-A04` | I | `flutter analyze` reports no issues and `flutter test` is green before and after every feature |

---

## 5. Status ledger

Updated as each document completes. This is the project's single progress view, mirrored in
`.memory/contracts/ledger.json`.

**Legend:** `—` not started · `~` in progress · `✓` done

### Foundation

| Doc | Status |
|-----|--------|
| 00 Product spec | ✓ |
| 01 Tech stack | ✓ |
| 02 Architecture | ✓ |
| 03 Domain model | ✓ |
| 04 Interface standards | ✓ |
| 05 Testing and DoD | ✓ |
| 06 Validation contract | ✓ |
| 07 Security | ✓ |
| 08 Agent harness | ✓ |

### Milestone 1

| Doc | Assertions | Status |
|-----|-----------|--------|
| F01 | 44 | ~ (A44 live run pending) |
| F02 | 28 | — |
| F03 | 34 | — |
| F04 | 23 | — |
| F05 | 13 | — |
| F06 | 32 | — |
| F07 | 19 | — |
| F08 | 27 | — |
| F09 | 22 | — |
| F10 | 27 | — |
| F11 | 17 | — |
| F12 | 21 | — |
| F13 | 28 | — |

### Milestone 3

| Doc | Assertions | Status |
|-----|-----------|--------|
| F24 | 40 | ~ (A39/A40 live run pending) |
| F25 | 46 | ~ (gates 1-3, 43/46; A44-A46 live run pending) |
| F26 | 87 | — (not started; A80-A87 live run waits for the user's Gemini API key) |
