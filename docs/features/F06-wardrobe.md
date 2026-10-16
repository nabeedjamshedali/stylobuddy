# F06 — Wardrobe

> Browse, search and filter the wardrobe; view, edit and remove an item; and the simulated import flow (source, batch, analyzing, per-item review, confirmation). Plan Task 8; prototype `app.js:63-101`. Depends on foundation 03, 04.

**Status:** NOT STARTED · **Milestone:** 1 · **Depends on:** F01, F03

---

## 1. Goal

Let the user see and manage everything they own and add sample pieces through the prototype's import walk-through.

## 2. MVP scope

Routes `/wardrobe /clothing /edit-item /filter /import /import-source /batch /analyzing /review /add-confirm` (`wardrobeRoutes`). `WardrobeCubit` (F01) stays; adds `ImportCubit` and `WardrobeBrowseCubit`.

## 3. Later scope

Real camera/gallery picker, real background removal and AI tagging, Supabase Storage upload with URL saved on the Firestore item.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/wardrobe: search + category chips + "Filter" -> grid ; tile -> /clothing?id
/clothing: ⋯ -> "Clothing options" modal -> edit | remove ; "✧ Find matching outfits" -> selectAndLock(id) -> /match-review
remove -> modal "Remove clothing?" -> "Remove item" -> removeItem -> /wardrobe + toast
/import -> camera|gallery -> /import-source (1/3/6) -> "Review N photos →" -> /batch -> "✧ Analyze clothing" -> /analyzing -> 1150 ms -> /review (item by item) -> last "Save to my wardrobe →" -> addItems -> /add-confirm
```

## 6. Interface surface

Routes as above. Cubits: `WardrobeBrowseCubit{String filter = 'All'; String search = ''}` (set filter/search, clear search); `ImportCubit` holding source ('camera'|'gallery'), count (default 3, choices 1/3/6), drafts, upload index, show-original flag (method names left to the builder; behaviour fixed below). Import pool `['cream-blouse','denim-jacket','tan-belt','black-heels','floral-dress','cream-cardigan']`. Consumes `WardrobeCubit.addItems/updateItem/removeItem/itemOrFallback`, `StylistCubit.selectAndLock`, `SelectField`, `AppProgressBar`, `AppModal`, `AppToast`, `DemoNote`, `LoadingView`.

## 7. Domain model usage

`ClothingItem` all fields. Drafts are `ClothingItem` with id `new-<timestamp>-<index>`, `sourceId` = pool id, name/category/color/occasion copied from that pool item, `season` 'All season', `wears` 0.

## 8. Data changes

None.

## 9. Background work and events

1150 ms analysis delay; advance only if still on `/analyzing`.

## 10. Degradation and failure

Unknown clothing id in `/clothing?id=` -> fallback placeholder item; blank name -> toast, stay; no drafts on `/review` -> 'No draft to review.'; search with no match -> empty state; category with no items -> empty state with 'Add clothing'.

## 11. Validation assertions

```
F06-A01  [U]  Wardrobe header renders 'YOUR COLLECTION', 'My Wardrobe', 'Everything you own, beautifully organized.'; stats show '23' 'Pieces', '7' 'Categories', '18' 'Worn pieces' for the seed
F06-A02  [U]  After removing one never-worn item the stats show '22' 'Pieces'; after adding one item of a new category value the category count increases; Worn pieces counts items with wears > 0 only
F06-A03  [U]  Action buttons '＋ Add clothing' (-> /import) and 'Build outfit ↗' (-> /builder); filter icon and 'Filter ☷' open /filter; AI action 'Find your best matches' / 'Select wardrobe pieces and let AI style them.' opens /matching
F06-A04  [U]  Category chips: All, Shirts, Pants, Shoes, Dresses, Skirts, Outerwear, Accessories; selecting 'Shoes' shows 4 tiles, section title 'Shoes' and '4 items'; 'All' shows title 'All clothing' and '23 items'
F06-A05  [U]  Each tile shows name and '<color> · <category>' (e.g. 'White · Shirts') and opens '/clothing?id=<id>'
F06-A06  [U]  Searching 'jean' (placeholder 'Search by item name...') shows exactly 'Black Jeans' and 'Blue Jeans' and count '2'; search is case-insensitive ('JEAN' same result)
F06-A07  [U]  Empty search '' shows all 23 items and no empty state (empty differs from no-match)
F06-A08  [U]  Searching 'zzz' shows 'Nothing here yet', 'Try a different search, or clear the search field.' and a 'Clear search' button that resets the search to '' and restores the grid
F06-A09  [U]  A category with no items and no search shows 'Nothing here yet', 'This category is waiting for your first item.' and 'Add clothing' (-> /import)
F06-A10  [U]  Filter screen renders head 'Wardrobe Filters', 'Choose a category to narrow down the wardrobe.' and 8 options; choosing 'Pants' sets the filter and returns to /wardrobe showing 4 tiles
F06-A11  [U]  Clothing detail for white-shirt renders head 'Clothing Details', 'IN MY WARDROBE', category 'Shirts', name 'White Oxford Shirt', COLOR 'White', OCCASION 'Office', TIMES WORN '0', SEASON 'All season', 'Style this piece', '✧ Find matching outfits', 'Edit item details', 'Remove from wardrobe'
F06-A12  [U]  Clothing detail for an item with wears 0 shows '0' (zero, not blank); for an unknown id it renders the fallback (name from id, 'Unknown') without throwing
F06-A13  [U]  '✧ Find matching outfits' sets StylistState selected [id] and locked [id] and opens /match-review
F06-A14  [U]  '⋯' opens modal 'Clothing options' with 'Edit clothing details →' (-> /edit-item) and 'Remove this item →' (opens the remove dialog)
F06-A15  [U]  Remove dialog 'Remove clothing?' with 'This item will be removed from your wardrobe. Saved looks that used it may need adjusting.', buttons 'Cancel' (closes, item kept) and 'Remove item'
F06-A16  [U]  'Remove item' removes the item, lands on /wardrobe, shows toast 'Item removed' and the count drops by 1; a saved outfit that referenced it still renders (fallback) on /saved-detail
F06-A17  [U]  Edit-item renders head 'Edit Item', 'EDITING YOUR WARDROBE', fields Clothing name / Category (7) / Color (12) / Best for (7) / Season (5) prefilled from the item, and 'Save changes'
F06-A18  [U]  Saving with an empty name, and with a whitespace-only name, toasts 'Enter an item name', stays on /edit-item and leaves the item unchanged
F06-A19  [U]  Saving valid changes (name trimmed) updates the item via updateItem, returns to /clothing showing the new values and toasts 'Clothing updated'
F06-A20  [U]  Import renders head 'Add Clothing', '✧', 'YOUR DIGITAL CLOSET', 'Every great look starts here.', choices 'Take a photo' / 'Capture one item with your camera' and 'Choose from gallery' / 'Add one or multiple pieces', info line 'AI suggestions are editable before anything is saved.' and the demo note 'Prototype preview uses sample garment photos. No device camera or AI service is connected.'
F06-A21  [U]  Import-source renders 'CAMERA IMPORT' when reached through 'Take a photo' and 'GALLERY IMPORT' through gallery; head 'Choose Photos', 'Select your pieces'; count buttons '1 item', '3 items', '6 items' with 3 active by default; the sample grid shows that many pool images
F06-A22  [U]  The primary button reads 'Review 3 photos →' for 3 and 6, and 'Review 1 photo →' for 1
F06-A23  [U]  Batch renders head 'Review Photos', 'STEP 1 OF 3', 'Ready to organize?', '<n> items' 'Ready for AI analysis', '✧ Analyze clothing' and the demo note 'AI processing is simulated in this prototype.'; drafts equal the first n pool ids in order
F06-A24  [U]  Analyzing renders head 'Analyzing Items', 'Preparing your pieces', 'Removing backgrounds and identifying clothing details...', 'DEMO ANALYSIS'; it auto-advances to /review after 1150 ms and does not advance if the user left the route
F06-A25  [U]  Review of item 1 of 3 renders head 'Review AI Suggestions', 'ITEM 1 OF 3', 'AI suggestion · editable', progress 33%, photo label 'CLEAN BACKGROUND · PREVIEW', 'Compare original image ↗'; toggling shows 'ORIGINAL PHOTO' and 'Show cleaned preview ↗'
F06-A26  [U]  Review button reads 'Confirm & next item →' for items 1-2 and 'Save to my wardrobe →' on the last item; progress after item 2 is 67%
F06-A27  [U]  Confirming with a blank or whitespace-only name toasts 'Name is required' and does not advance
F06-A28  [U]  Importing 3 items then saving the last adds exactly 3 ClothingItems (wardrobe 26), keeps edits made in review (e.g. renamed 'Silk Blouse'), uses sourceId for the image, and navigates to /add-confirm
F06-A29  [U]  Two consecutive imports produce 6 items with all-distinct ids
F06-A30  [U]  Add-confirm renders head 'Import Complete', '✓', 'WARDROBE UPDATED', 'Looking good already.', '3 pieces have been added to your wardrobe. You can edit details or start creating new looks anytime.', '+3' 'New wardrobe items'; for 1 item the text is '1 piece has been added...' and stat '+1'; buttons 'View my wardrobe' (-> /wardrobe) and 'Add more clothing' (-> /import)
F06-A31  [U]  /review with no drafts renders 'No draft to review.' (missing) rather than crashing
F06-A32  [L]  In the running web build at 390x844: /#/wardrobe shows 23 pieces; search 'jean' shows 2 items; open an item, edit its name to blank (toast 'Enter an item name'), then to 'Test Shirt' (toast 'Clothing updated'); import 3 items end to end ending with the wardrobe at 26 pieces; screens match the prototype screenshots
```

## 12. Edge cases

Import 6 is capped by the 6-item pool. Wardrobe search is not trimmed (prototype `includes`). Imported items reuse pool images; tile image uses `imageId`.

## 13. Open questions

None.

---

## Completion block

```
Status: NOT STARTED

[ ] Gate 1  Interface documented
[ ] Gate 2  Unit
[ ] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 0/32 PASS
Regression: —
```
