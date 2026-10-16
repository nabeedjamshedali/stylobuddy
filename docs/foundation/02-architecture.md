# 02 — Architecture

> The layers, the boundaries between them, and what may depend on what. Depends on
> `01-tech-stack.md`.

---

## 1. Principles

1. The prototype is the spec: copy, layout and flow are ported 1:1 (CSS px = Flutter logical px at 390 wide).
2. Widgets render state and forward intents; every state change goes through a Cubit.
3. Cross-feature data (wardrobe, outfits + wear log, planner, profile, stylist session, builder draft) lives in Cubits provided at the app root; feature-local UI state lives in that feature's Cubit.
4. Backends slot in behind repositories later; widgets never change.
5. A feature may only touch its own `lib/features/<f>/` and `test/features/<f>/`; shared files belong to F01.

## 2. Layers

Dependencies point **one way only**.

```
   ┌──────────────────────────────────────────┐
   │  view/ and widgets/ (screens, shared/widgets) │  UI only
   └──────────────────────────────────────────┘
   ┌──────────────────────────────────────────┐
   │  cubit/ (state + intents)                │  may use other root Cubits
   └──────────────────────────────────────────┘
   ┌──────────────────────────────────────────┐
   │  repository/ + shared/models + SeedData  │  in-memory now, Firestore later
   └──────────────────────────────────────────┘
```

`lib/core` (theme, assets, router) is usable by all layers.

## 3. Request lifecycle

"Mark as Worn Today" on `/saved-detail?id=1`: the view calls `OutfitsCubit.logWear(1)` -> the Cubit appends a `WearEvent`, increments `Outfit.worn`, calls `WardrobeCubit.adjustWears(items, 1)` -> state emits -> the view rebuilds with "You have worn this look 1 time." and the view shows toast "Outfit wear recorded".

## 4. Boundaries

Mirrored in `.claude/harness.json` (`boundary_guard` hook blocks violations).

| Rule | Guarded layer | Forbidden | Fix when tempted |
|------|---------------|-----------|------------------|
| UI has no data access | `lib/features/*/view`, `*/widgets`, `lib/shared/widgets` | imports of firebase/supabase/purchases SDKs; imports from `/repository/` | expose through the feature Cubit |
| No Firebase Storage | `lib` | `package:firebase_storage` | Supabase Storage + URL on Firestore |
| Cubit-only state | `lib` | provider/riverpod/get/freezed_annotation, `extends Bloc<` | Cubit + plain state + `copyWith` |

Additional conventions (reviewed, not hook-enforced): no Material `Icons.*` in feature UI; no inline hex colors or raw `TextStyle` in feature widgets (use `AppColors`, `AppTextStyles`, or `<feature>_tokens.dart`); demo disclaimers render via `DemoNote`.

## 5. Failure and degradation

- A referenced wardrobe item that no longer exists resolves through `WardrobeCubit.itemOrFallback` (name = id with `-` as space, category `Shirts`, color `Unknown`, occasion `Everyday`) — never a crash.
- An image that fails to load falls back to the garment SVG; an unknown route renders `GenericPreviewView` ("Design preview only").
- Simulated waits are `Duration(milliseconds: 1150)` and only advance if the user is still on the waiting route.
- Navigation: drill-down uses `context.push` (back pops); tabs and flow resets use `context.go`; `ScreenHead` back = `canPop() ? pop() : go(fallbackRoute)`; system back on a non-home tab root goes to `/home`, on `/home` it exits.
