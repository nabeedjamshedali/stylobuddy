# ADR-001 — Android system back in onboarding

**Date:** 2026-10-16 · **Status:** Accepted · **Affects:** F02

## Context

Onboarding screens are reached with `context.go`, so there is no history to pop; the default system back would exit the app mid-flow. The prototype has no system back.

## Decision

On `/intro`, system back behaves like the on-screen Back: it steps back one slide and, on slide 1, goes to `/welcome` (via `OnboardingCubit.back()`). On `/personalize`, system back goes to `/intro`. `/welcome` and `/auth` (reached by `go`) keep the default (exit).

## Alternatives rejected

| Option | Why not |
|--------|---------|
| Use `push` for every onboarding step | Intro slides are one route; back would skip slides and stack welcome/intro copies |
| Leave default back | Exits the app from slide 3, surprising |

## Consequences

Back always walks the flow backwards. Covered by F02 widget tests (`system back` group). Revisit if onboarding gets a persisted completion flag.
