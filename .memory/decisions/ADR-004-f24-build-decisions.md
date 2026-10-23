# ADR-004 — F24 build decisions (gender onboarding)

**Date:** 2026-10-22 · **Status:** Accepted · **Affects:** F24, F02 test harness

## Context

F24 left a few calls to the builder (card layout, how `Continue` reports
`enabled: false`, how the null-gender guard runs), and the build session had no
sub-agent dispatch tool, so worker/validator separation could not be run as
separate agents.

## Decision

1. **Process.** The orchestrator implemented F24 itself, layer by layer and in
   order: shared, then core, then feature (onboarding, profile), then
   `lib/app.dart` and `firestore.rules`. Validation was a self-run scrutiny pass:
   analyze, the full suite and the emulator rules suite. The contract audit was a
   grep of `F24_Axx` across `test/`. An independent validator pass is still owed
   (see the F24 handoff).
2. **`ObPrimaryButton.enabled`** is semantics-only (default `true`). Visuals do
   not change and taps still fire `onPressed`, so `/gender` can show the "choose
   first" toast (F24 §6).
3. **Gender card layout** follows prototype v26 / V26.1. The copy column (47%)
   holds the title, subtitle and radio. The art column (53%) shows the image with
   `BoxFit.contain` at 90% height. Both cards use the one `GenderCard` widget at
   equal `Expanded` size, so they cannot differ in size or treatment.
4. **Null-gender guard.** `IntroView` renders the private `_RedirectToGender`
   (a blank white `Scaffold`). It calls `context.go('/gender')` once, from a
   post-frame callback in `initState`.
5. **Test harness.** `pumpApp(..., fresh: true)` is opt-in. It tears down the
   previous tree before pumping. It is not the default because F08 saved tests
   rely on cubit state surviving a re-pump. `pumpIntro` / `pumpPersonalize` reach
   `/intro` through `/gender`.

## Alternatives rejected

| Option | Why not |
|--------|---------|
| Spawn `claude -p` worker subprocesses from Bash | Would need permission-mode changes not granted to this session |
| Grey out Continue visually when disabled | Not specified by F24; prototype `disabled` styling was not ported elsewhere |
| Always reset the tree in `pumpApp` | Broke F08_A14/A21-A25, which depend on state across re-pumps |

## Consequences

An independent scrutiny/contract/behaviour validator pass should be run on F24
when a dispatch-capable session is available. If it finds nothing, the record
stands.
