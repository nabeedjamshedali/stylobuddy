# F05 — Home

> The dashboard: greeting, quick actions, today's suggestion, AI banner, recently added grid and explore rows. Plan Task 5; prototype `app.js:40-62`. Depends on foundation 03, 04.

**Status:** IMPLEMENTED · **Milestone:** 1 · **Depends on:** F01, F03

---

## 1. Goal

A single screen that routes the user into every main flow with prototype-identical copy.

## 2. MVP scope

Route `/home` (`homeRoutes`); inline SVG icons from `app.js:43-49` via `SvgPicture.string`; `home_tokens.dart` for feature-only CSS values.

## 3. Later scope

Real "Today's suggestion" driven by weather and the planner; unread-notification dot logic.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
tap quick action -> /occasion | /matching | /import | /calendar ; bell -> /notifications
"View outfits →" -> StylistCubit.setOccasion('Everyday') + generateAutomatic() -> /generating -> /results
banner -> /matching ; "See all →" -> /wardrobe ; recent tile -> /clothing?id=<id>
explore rows -> /packing | /insights | /shopping | /saved
```

## 6. Interface surface

Route `/home`. No public Cubit. Consumes `WardrobeCubit` (first 4 items), `ProfileCubit.state.name`, `StylistCubit.setOccasion/generateAutomatic`, `AppRoutes`.

## 7. Domain model usage

Reads `ClothingItem` (first 4 of `WardrobeState.items`: id, name), `ProfileState.name`.

## 8. Data changes

None.

## 9. Background work and events

None directly (the generation delay belongs to F03).

## 10. Degradation and failure

Empty `ProfileState.name` -> greeting `Hi, there`. Fewer than 4 wardrobe items -> that many tiles; empty wardrobe -> no tiles, no crash. Names are plain `Text` (no markup injection).

## 11. Validation assertions

```
F05-A01  [U]  With default ProfileState Home shows 'Good morning', 'Hi, Alex Morgan' and 'Make the most of your wardrobe today.' (ledger ruling: not 'Hi, there')
F05-A02  [U]  With ProfileState.name '' Home shows 'Hi, there' (missing name differs from a set name)
F05-A03  [U]  A name containing '<b>x</b>' renders literally as text
F05-A04  [U]  Home shows 'QUICK ACTIONS' and exactly 4 shortcuts in order 'AI Outfits', 'Match Items', 'Add Item', 'Calendar'; they open /occasion, /matching, /import, /calendar
F05-A05  [U]  The bell (label 'View notifications') opens /notifications
F05-A06  [U]  Today's suggestion renders 'Today's suggestion', '✧ AI selected', '☀ Everyday · Smart casual', 'From your wardrobe', 'Clean & effortless', 'A crisp shirt, tailored chinos and everyday essentials.' with 4 garment images (white-shirt, navy-chinos, white-sneakers, black-watch)
F05-A07  [U]  'View outfits →' sets the stylist occasion to 'Everyday' and calls generateAutomatic, ending on /generating (and later /results)
F05-A08  [U]  The banner shows 'Have a few items in mind?' and 'Let AI find the best matching combination.' and opens /matching
F05-A09  [U]  'Recently added' shows exactly 4 tiles named 'White Oxford Shirt', 'Black Shirt', 'Blue Denim Shirt', 'Cream Blouse'; tapping the first opens '/clothing?id=white-shirt'; 'See all →' opens /wardrobe
F05-A10  [U]  After the wardrobe's first item is removed the tiles shift (first tile 'Black Shirt'); with 2 items there are 2 tiles; with 0 items the section renders no tiles and no exception
F05-A11  [U]  'Explore more' has 4 rows 'Packing assistant' / 'Pack smarter for trips', 'Style insights' / 'Discover wardrobe trends', 'Shopping assistant' / 'Find your wardrobe gaps', 'Saved outfits' / 'Your favorite looks' opening /packing, /insights, /shopping, /saved
F05-A12  [U]  Home renders inside the shell with the bottom nav and the Home tab highlighted
F05-A13  [L]  In the running web build at 390x844, /#/home matches the prototype screenshot (greeting, 4 shortcuts, suggestion card, recent grid, explore rows) and tapping 'AI Outfits' reaches the Select Occasion screen
```

## 12. Edge cases

The `☀`/`👋` glyphs are text; "Today's suggestion" uses a straight apostrophe as in the prototype.

## 13. Open questions

None.

---

## Completion block

```
Status: IMPLEMENTED

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 12/13 PASS (A13 is [L], pending the parity pass)
Regression: full `flutter test` suite green (174/174); `flutter analyze` clean
```
