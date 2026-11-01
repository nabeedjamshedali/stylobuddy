# ADR-002 — PackingCubit scoped to a nested ShellRoute

**Date:** 2026-10-17 · **Status:** Superseded (2026-10-17, same day — see
below) · **Affects:** F10

## Superseded

The final whole-branch review flagged a data-loss bug: because
`PackingCubit` held real user data (trips) but was provided by a
feature-local `ShellRoute`, navigating away from `/packing*` to any other
tab and back disposed and recreated the cubit, silently discarding every
trip the user had created. That's a direct violation of this project's
own rule that durable user data lives in a root-provided Cubit (the
contrasting example cited at the time, `ShoppingCubit`'s wishlist, was
always root-provided and does not lose data this way).

`PackingCubit` is now provided in the root `MultiBlocProvider`
(`lib/app.dart`), the same as `ShoppingCubit`/`StylistCubit`/
`BuilderCubit`. `packing_routes.dart` no longer wraps its `GoRoute`s in a
`ShellRoute`; they are plain `GoRoute`s, and the cubit comes from the root
provider. The "trips reset to empty when the flow is re-entered" behavior
this ADR deliberately chose is gone — trips now persist for the lifetime
of the app session, matching F10 §3's "no persistence yet" scope (no
persistence yet means no Firestore-backed persistence across app
restarts; it was never meant to mean "loses data on a tab switch").

The rest of this document is kept for history — it explains why the
original (now-wrong) choice was made.

## Original decision (superseded)

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
