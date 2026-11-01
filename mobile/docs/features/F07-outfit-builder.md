# F07 — Manual Outfit Builder

> Pick wardrobe pieces with a live preview, then name, classify and save the outfit (create or edit). Plan Task 9; prototype `app.js:158-169`. Depends on foundation 03, 04.

**Status:** DONE (gates 1-3; gate 4 open) · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Let users compose their own look from owned clothes and save it to My Looks.

## 2. MVP scope

Routes `/builder /manual-preview` (`builderRoutes`); `BuilderCubit` provided at the app root (controller adds it to `app.dart`).

## 3. Later scope

Drag-and-drop layout; occasion suggestions; outfit photos.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
Saved "Edit look" -> BuilderCubit.start(editId: id) -> /builder (title "Edit Your Outfit")
Stylist/Wardrobe/Saved "Create a look" -> /builder (fresh draft)
/builder: toggle tiles / remove chips / category chips -> "Preview N items →" -> /manual-preview
/manual-preview: name + occasion -> "Save to My Looks" -> OutfitsCubit.upsertManual -> /saved-detail + toast "Outfit saved" ; "Change Items" -> /builder (name/occasion kept)
```

## 6. Interface surface

Routes `/builder /manual-preview`.

```text
BuilderCubit{List<String> picked; String category; int? editingId; String name; String occasion; void start({int? editId})}
(toggle/remove/set-category/set-name/set-occasion/save methods: names left to the builder; behaviour below)
Consumes: OutfitsCubit.upsertManual/byId, WardrobeCubit, ItemTileGrid-style tiles, SelectField, AppToast
```

## 7. Domain model usage

Reads `ClothingItem`; writes `Outfit` (`name`, `items`, `occasion`, `why` set by `upsertManual`).

## 8. Data changes

None.

## 9. Background work and events

None.

## 10. Degradation and failure

Blank/whitespace name -> toast, stay. No items -> toast, stay. `start(editId)` with an id that no longer exists -> treated as a new outfit. Picked ids deleted from the wardrobe -> fallback tiles.

## 11. Validation assertions

```
F07-A01  [U]  Saving with an empty name toasts 'Give your outfit a name' and creates no outfit
F07-A02  [U]  Saving with a whitespace-only name ('   ') toasts 'Give your outfit a name' (trimmed)
F07-A03  [U]  Saving with a valid name and no picked items toasts 'Choose at least one item' and creates no outfit
F07-A04  [U]  With a blank name and no items, the name message wins ('Give your outfit a name')
F07-A05  [U]  A valid save (name 'Friday look', 2 items) inserts an outfit at index 0 of OutfitsCubit with the trimmed name, picked items in order, the chosen occasion and why 'A look you put together from your own wardrobe.'; navigates to /saved-detail?id=<new id>; toasts 'Outfit saved'; picked is cleared, editingId null, name ''
F07-A06  [U]  start(editId: 2) loads that outfit's items, name and occasion, sets editingId 2 and category 'All'; saving keeps id 2, outfit count unchanged, updated name/items/occasion
F07-A07  [U]  start() with no editId clears picked, name, occasion ('Everyday'), editingId and category
F07-A08  [U]  start(editId: 999) (nonexistent) followed by a valid save creates a new outfit and does not throw
F07-A09  [U]  Builder renders head 'Build Your Outfit' (or 'Edit Your Outfit' when editing), 'YOUR PERSONAL LOOK', 'Put your pieces together.', 'Choose items from your wardrobe. Watch your look come together as you select.', 'Live outfit preview', 'Choose from your wardrobe' and '23 pieces'
F07-A10  [U]  With nothing picked the preview shows '0 items', 'Your look starts here', 'Select clothing below to build an outfit.' and 'Preview 0 items →' is disabled; with one picked it reads '1 item' / 'Preview 1 item →'; with 2 '2 items' / 'Preview 2 items →'
F07-A11  [U]  Tapping a tile toggles its mark between '+' and '✓'; chips 'All, Shirts, Pants, Dresses, Skirts, Outerwear, Shoes, Accessories' filter the grid (Shoes -> 4)
F07-A12  [U]  The live preview shows at most the first 6 picked garments, each with a '×' remove control; tag buttons '<name> ×' remove the piece (all picked pieces appear as tags even beyond 6)
F07-A13  [U]  Manual-preview renders head 'Your Custom Outfit' (or 'Edit Custom Outfit'), 'YOUR OWN STYLE', 'Looks good together.', 'Review your selections, name your outfit and save it to your collection.', 'Pieces in this outfit' with a row and 'Change' per piece, 'Outfit name' prefilled 'My custom look' when no name entered, placeholder 'e.g. Friday smart casual', 'Best for' with 7 options (Everyday, Office, Casual, Party, Wedding, Date Night, Vacation)
F07-A14  [U]  Primary button reads 'Save to My Looks' (or 'Save Changes' when editing); 'Change Items' returns to /builder keeping the typed name and occasion
F07-A15  [U]  With no pieces, manual-preview shows 'No garments chosen yet'
F07-A16  [U]  The name field accepts at most 60 characters
F07-A17  [U]  Editing an outfit that contains a deleted item id shows that piece through the fallback and can still be saved without a crash
F07-A18  [U]  Header back targets: builder -> /wardrobe (pop when history), manual-preview -> /builder
F07-A19  [L]  In the running web build at 390x844: /#/builder, pick 3 items, Preview, clear the name and tap Save (toast 'Give your outfit a name'), enter 'Friday look', save: lands on the saved detail with toast 'Outfit saved' and the look appears first in My Looks; screens match the prototype screenshots
```

## 12. Edge cases

The default name 'My custom look' is only a default value; clearing it is allowed and then rejected on save. Ids are clock based (F01-A17).

## 13. Open questions

None.

---

## Completion block

```
Status: DONE (gates 1-3; gate 4 open)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 18/19 PASS (F07-A19 is [L], pending the parity pass)
Regression: flutter test — 228/228 passed; flutter analyze — No issues found!
```
