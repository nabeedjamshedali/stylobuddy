# 05 — Testing and Definition of Done

> The bar every feature must clear before the next document is started. Depends on
> `06-validation-contract.md`.

---

## 1. The rule

> **A feature document is DONE when every assertion in it passes against the running system.**

Not when the code is written. Not when the unit tests are green. When the assertions pass against
a real, booted system.

Nothing else is started while the current document has a failing assertion.

---

## 2. Why assertions come first

The failure mode this prevents: an agent builds a feature, writes some tests, the tests pass, and
coverage is full. But the tests were shaped by the code, not by what the code was meant to do.
**Tests written after implementation do not catch bugs. They confirm decisions.**

So assertions are written **during documentation, before any implementation**, and define
correctness independently of how the code turns out. An implementation that cannot satisfy an
assertion is wrong; the assertion is not renegotiated to fit the code. If an assertion is genuinely
mistaken, it is amended **in the document, with a dated note explaining why**, never silently
deleted or weakened.

---

## 3. The four gates

Every feature passes all four. No exceptions, no "we'll add tests later".

### Gate 1 — Interface documented

- Every endpoint, command or public function the feature adds is documented where its users look
  (generated API docs, CLI help, or docstrings), with typed inputs and outputs
- Every error it can return is documented
- **Verify:** open the documentation and confirm it renders and is accurate

### Gate 2 — Unit tests

External systems, the network and the database are faked. Fast and deterministic.

- Happy path
- Validation and boundary conditions
- Permission rules
- The invariants stated in the document's own assertions
- **"Missing" versus "empty/zero"**, wherever the feature reads an optional value
- **Verify:** unit suite green

### Gate 3 — Integration tests

Real database, real request stack, fixture-backed external systems.

- Full request-to-response journey for the feature
- Real side effects confirmed by reading them back (rows written, files created, events emitted)
- Authorization: unauthenticated, wrong role, another account's data
- **Verify:** integration suite green

### Gate 4 — Live run

**The gate with teeth.** The other three can all pass against a system that does not work.

- Boot the real system: `flutter run (Android device/emulator); flutter run -d chrome for the fastest visual loop`
- For this project the `[L]` gate is: run `flutter run -d chrome` (or `flutter build web` and serve `build/web`), set the viewport to 390x844, open `/#/<route>` and drive the screen; compare against the prototype (`python -m http.server` on the prototype folder, call `go('<route>')`)
- Exercise the feature the way a user would
- Confirm against the document: outputs, status codes, stored data, side effects
- **Fix what breaks and re-run.** Boot failures, wiring errors, missing environment variables and port collisions are all in scope
- **Verify:** every `[L]` assertion marked `PASS` with the command that proved it

Never report red output as passing. Never mark an assertion `PASS` without running it.

---

## 4. Commands

| Purpose | Command |
|---------|---------|
| Unit tests | `flutter test` |
| Full suite | `flutter test` |
| Lint / format / types | `flutter analyze` |
| Boot the system | `flutter run (Android device/emulator); flutter run -d chrome for the fastest visual loop` |

## 5. Test naming

Dart `test(...)`/`testWidgets(...)` descriptions start with the assertion ID using an underscore,
for example `F07_A03 rejects blank outfit name`.
(The generic form is `test_<assertion id>_<short description>`.)
The assertion ID in the name is how coverage is checked mechanically: the `assertion_coverage`
hook reports gaps as tests are written, and the `contract-auditor` enforces them.

---

## 6. Mandatory test categories

Required in every feature they apply to, whatever the feature does:

- **Isolation.** If the system holds data for more than one user or account, create the same record
  for two of them and prove one can never see or change the other's. (Not applicable in Milestone 1: single in-memory user.)
- **Missing versus empty.** Wherever a value may be unavailable, prove that "not available" and
  "zero/empty" behave differently and are described differently to the user.

---

## 7. Fixtures

One shared fixture dataset, used by every test and by the demo: `SeedData` (23 items, 2 outfits, 1 planned entry) plus tests that remove items, empty the wardrobe and reference missing ids. Make it **deliberately messy**:
real data is messy, and a clean fixture hides exactly the bugs that matter. Include missing values,
duplicates, near-duplicates, empty collections, extreme sizes and inactive records.

Because the demo and the tests share data, a passing suite means a working demo.

---

## 8. Regression bar

Before starting a document: full suite green. After finishing it: full suite green, including every
assertion from every earlier document. A feature that breaks an earlier assertion is not done,
however well its own assertions pass.
