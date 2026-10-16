# ADR-002 — PackingCubit scoped to a nested ShellRoute

**Date:** 2026-10-17 · **Status:** Accepted · **Affects:** F10

## Context

F10's brief requires `PackingCubit` to be feature-local (provided "at the
packing route's top", not in `lib/app.dart`), but all five packing routes
(`/packing`, `/new-trip`, `/packing-preview`, `/packing-list`,
`/packing-add`) must share one cubit instance so a trip created on one
screen is visible on the next. A plain `BlocProvider` inside each
`GoRoute.builder` would create a fresh cubit per navigation, losing state
immediately.

## Decision

`packingRoutes` wraps its five `GoRoute`s in their own nested `ShellRoute`
(inside the app's existing top-level `ShellRoute`/`AppShell`), with the
nested shell's `builder` providing `BlocProvider(create: (_) =>
PackingCubit())`. Go_router preserves a `ShellRoute`'s subtree identity
across navigations within it, so the cubit instance (and its in-memory
trips) persists while the user stays inside `/packing*` routes, and is
freshly recreated (trips reset to empty) the next time the flow is
entered — matching the prototype's `S.trips` starting empty on load and
F10-A01's "first open: 0 trips" assertion.

One consequence for tests: because the `BlocProvider` sits *below*
`AppShell`'s `Scaffold`, the common `cubitOf<T>` test helper (which reads
from `find.byType(Scaffold).first`) cannot see `PackingCubit`. F10's tests
instead read it from `find.byType(ScreenHead).first`, which is always
rendered inside the packing views.

## Alternatives rejected

| Option | Why not |
|--------|---------|
| Provide `PackingCubit` in `lib/app.dart` like other feature cubits | Brief explicitly rules this out; also would make trips persist across unrelated navigation (e.g. visiting Home and back), which is not asserted and adds unneeded scope |
| `BlocProvider` per `GoRoute.builder` | Recreates the cubit (and loses trips) on every navigation between the five packing routes |

## Consequences

Trips are lost if the app is backgrounded mid-flow and go_router disposes
the shell; acceptable per F10 §3 ("trip persistence in Firestore" is
explicitly later scope). Any later task adding Firestore-backed trips
should keep the same provider scope or explicitly move it to the app
root.
