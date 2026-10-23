# 03 — Domain Model

> **The single source of vocabulary.** Every entity, field and state the project talks about is
> defined here, once. Feature documents and code use these names exactly. Depends on
> `02-architecture.md`.

---

## 1. Entities

Models live in `lib/shared/models/`; all are immutable with `copyWith` (except `WearEvent`, `PlannedEntry`).

```
ClothingItem                                   # WardrobeState{List<ClothingItem> items}
    id: String                                 # slug, e.g. 'white-shirt'; imported items 'new-<ts>-<i>'
    name, category, color, occasion: String
    season: String = 'All season'
    wears: int = 0                             # times worn; never negative
    sourceId: String | None                    # image source for imported items
    imageUrl: String | None                    # F15: Supabase Storage URL of a real uploaded photo;
                                                # missing/null/'' are all "no photo" — only a non-empty
                                                # string counts as set. GarmentImage does not render this
                                                # yet (persist-only, F15 §13) — falls back to sourceId/id.
    imageId (getter) = sourceId ?? id

Outfit                                         # OutfitsState{List<Outfit> outfits, List<WearEvent> wearLog}
    id: int                                    # clock-based, unique
    name, occasion, why: String
    items: List<String>                        # ClothingItem ids, order significant
    worn: int = 0

WearEvent
    id: int, outfitId: int, name, occasion: String
    items: List<String>                        # snapshot of Outfit.items at wear time
    timestamp: DateTime

PlannedEntry                                   # PlannerState.planned: Map<String 'yyyy-MM-dd', PlannedEntry>
    outfitId: int, occasion: String

PlannerState: planned, year = 2026, month = 10 (1-based), day = 15,
              editingOutfitId: int | None, editingOccasion: String | None   # scheduling draft, added by F09

ProfileState                                   # defaults mirror prototype app.js:269
    name = 'Alex Morgan', email = 'alex@example.com'
    styles = ['Minimal','Smart casual'], occasions = ['Everyday','Office']
    dailyNotifications = true, plannedNotifications = true, productNotifications = false
    weatherConsent = true, climate = 'Mild', plan = 'Free', billingCycle = 'yearly'
    gender: String | None = None               # F24: 'male' | 'female'; null = never chosen (guest,
                                                 # skipped intro, or pre-F24 user). Written only by the
                                                 # D5 bootstrap seed from the onboarding gender choice.
                                                 # ProfileRepository exposes no setter for it and
                                                 # FirestoreProfileRepository's bootstrap never overwrites
                                                 # an already-present value (F18's absent-keys-only rule) —
                                                 # but this is app-level behaviour, not a rules guarantee:
                                                 # firestore.rules permits an owner to merge-set it directly.
    styleSummary (getter) = styles.join(' • ')
    PreferenceField { styles, occasions }
    # NOTE: the Firestore `users/{uid}` document backing this state (schema doc §1) also carries
    # a `seeded: bool` field once Milestone 2's backend wiring lands. That field is infra-only
    # (set by FirestoreService.runBootstrapIfNeeded on first sign-in, F14) and is deliberately
    # NOT part of ProfileState — ProfileRepository.watchProfile() excludes it from what it emits.

StylistState (F03)   occasion = 'Everyday', results: List<StyleResult>, activeIndex, selected, locked: List<String>,
                     accessories = true, category = 'All', isMatchMode, isGenerating
StyleResult (F03)    id: int, name, occasion, why: String, items: List<String>
Trip (F10, feature-local)        id: String 'trip-<ts>', name, destination, start, end (ISO yyyy-MM-dd), type, notes: String,
                                 days: int, items: List<PackingItem>
PackingItem (F10, feature-local) key: String, label: String, wardrobeId: String | None, packed: bool
ShoppingState (F11)  tab = 'discover', wishlist: List<String>, selectedId: String
```

Seed (`SeedData`): 23 items (`wears = index % 5`), 2 outfits (`Everyday Essential` id 1, `Modern Weekend` id 2), planned `{'2026-10-15': PlannedEntry(outfitId: 1, occasion: 'Everyday')}`; constants `categories`, `colors`, `occasions`, `seasons`.

## 2. States and enums

- Categories: Shirts, Pants, Shoes, Dresses, Skirts, Outerwear, Accessories (plus filter value `All`).
- Season: All season, Spring, Summer, Autumn, Winter.
- Roles: guest / demo user (see `07-security.md`).
- Trip type: Vacation, Business, City break, Beach, Formal event, Other.
- Plan: Free (Milestone 1 never changes it). Billing cycle: monthly, yearly.

## 3. Relationships

- `Outfit.items`, `WearEvent.items`, `PackingItem.wardrobeId`, `StyleResult.items` reference `ClothingItem.id` by value. Deleting a `ClothingItem` leaves these untouched; readers resolve through `WardrobeCubit.itemOrFallback`.
- `PlannedEntry.outfitId` and `WearEvent.outfitId` reference `Outfit.id`. Deleting an `Outfit` keeps its `WearEvent`s (history is retained) and any `PlannedEntry`; readers must tolerate the missing outfit.
- Logging/removing a wear adjusts `Outfit.worn` and each item's `wears` (clamped at 0).

## 4. Missing versus empty

| Value | Missing | Empty / zero |
|-------|---------|--------------|
| Item id in wardrobe | placeholder from `itemOrFallback` (category `Shirts`, color `Unknown`) | wardrobe with 0 items -> empty states (e.g. "Insights start with your wardrobe") |
| `ClothingItem.season` | n/a (default 'All season') | — |
| `ClothingItem.imageUrl` | missing field or explicit `null` -> falls back to `sourceId`/`imageId` bundled art (F15-A15) | `''` (empty string) -> also falls back, never treated as a usable URL (F15-A16); only a non-empty string counts as "has a photo" |
| `ProfileState.name` | Home greets `Hi, there`; avatar initial `A` | non-empty by validation (blank rejected) |
| `ProfileState.gender` | missing field or explicit `null` -> "never chosen" (pre-F24 user, or a guest whose choice was never persisted); no app write path ever produces `''`, but if the document holds `''` anyway (legacy data or a direct write outside the app) it reads back verbatim as `''`, not coerced to `null` (F24-A28) | n/a — see Missing column; the onboarding-side guard that sends `/intro` to `/gender` until a choice is made reads `OnboardingState.gender` (feature-local, not this field), not `ProfileState.gender` |
| `Outfit` referenced by id | "This outfit is no longer saved." / "Original outfit was removed" | zero outfits -> "Your looks start here" |
| Trip destination | falls back to trip type in subtitles | — |
| Trip dates | `Choose dates` | — |
| `wears` 0 | counted as "no recorded wears" | shown as `0`, never hidden |
| Search `''` | shows all (not the "Nothing here yet" state) | no-match search shows "Nothing here yet" |

## 5. Changing the model

A feature that needs a field which is not here does not invent it. It raises it as an open question, the field is added here first, then used.
