# F04 — Match My Clothes

> The three-step flow (select candidates, lock must-wear pieces, set preferences) that produces up to three looks containing every locked item, using F03's `StylistCubit` and shared result views. Plan Task 7; prototype `app.js:149-157`. Depends on foundation 03, 04.

**Status:** IMPLEMENTED (gate 4 pending) · **Milestone:** 1 · **Depends on:** F01, F03

---

## 1. Goal

Let the user pick candidate pieces, require some of them, and see complete looks built only from the wardrobe.

## 2. MVP scope

Routes `/matching /match-select /match-review /match-options /matching-progress /matching-results /matching-detail` (`matchingRoutes`). No Cubit of its own; state lives in `StylistCubit`.

## 3. Later scope

Real matching model; saving a selection as a template.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/matching -> "Choose from my wardrobe →" (startMatching: clear selection/locks, category All) -> /match-select
/match-select -> toggle tiles, category chips -> "Continue with N items →" -> /match-review
/match-review -> toggle locks -> "Continue to preferences →" -> /match-options
/match-options -> occasion, "Complete my outfits" -> "✧ Find my best matches" -> generateMatches -> /matching-progress -> 1150 ms -> /matching-results -> /matching-detail
Wardrobe item "Find matching outfits" -> selectAndLock(id) -> /match-review (item selected + locked)
```

## 6. Interface surface

Routes as above. Consumes `StylistCubit` (`startMatching`, `toggleSelect`, `toggleLock`, `setCategory`, `setAccessories`, `setOccasion`, `generateMatches`, `selectAndLock`, state `selected/locked/category/accessories/occasion/results`), `ResultsView(match: true)`, `ResultDetailView(match: true)`, `ItemTileGrid(showLock: true)`, `SelectField`. Produces no new public API.

## 7. Domain model usage

Reads `ClothingItem.id/name/category/color`; reads/writes `StylistState`.

## 8. Data changes

None.

## 9. Background work and events

1150 ms simulated processing on `/matching-progress`; advances only if the user is still on that route.

## 10. Degradation and failure

Nothing selected: Continue disabled and review shows a warning notice. Selected id deleted from wardrobe: tile shown via fallback, `createMatches` ignores it. Results empty: 'No valid combinations yet'. Occasion not in the options list: field falls back to the first option.

## 11. Validation assertions

```
F04-A01  [U]  Matching intro renders head 'Match My Clothes', kicker 'YOUR WARDROBE, BETTER TOGETHER', 'Find the pieces that belong together.', the description 'Choose a few options, lock anything you definitely want to wear, and discover looks made entirely from your wardrobe.', steps '01 Select your candidates', '02 Lock your must-wear pieces', '03 Get your best three matches' with their small captions, and the button 'Choose from my wardrobe →'
F04-A02  [U]  'Choose from my wardrobe →' resets selected and locked to empty and category to 'All' (even if previously non-empty) and opens /match-select
F04-A03  [U]  Match-select renders head 'Select Clothing', 'STEP 1 OF 3', 'What should we match?', 'Select the pieces you want AI to compare. You can choose multiple items in each category.' and chips All, Shirts, Pants, Dresses, Skirts, Outerwear, Shoes, Accessories
F04-A04  [U]  With 0 selected the summary reads '0 selected' and 'Start with a shirt, trousers or dress', the strip is absent, and the continue button reads 'Continue with 0 items →' and is disabled (tapping does not navigate)
F04-A05  [U]  Tapping a tile changes its mark from '+' to '✓' and the summary to '1 selected' / 'Your chosen pieces are shown below'; the button reads 'Continue with 1 item →' (singular), with 2 'Continue with 2 items →'; tapping the tile again deselects it
F04-A06  [U]  Selecting the 'Shoes' chip shows only Shoes tiles (4 in the seed); 'All' shows all 23; the chip choice is stored as StylistState.category
F04-A07  [U]  Deselecting a locked item also removes its lock (locked is always a subset of selected)
F04-A08  [U]  The selection strip shows a mini image per selected id and a '◆' badge on locked ones
F04-A09  [U]  Match-review renders head 'Review Your Selection', 'STEP 2 OF 3', 'Anything you must wear?', legend 'Required' / 'Candidate', and one tile per selected id captioned 'Flexible candidate' with '◇'
F04-A10  [U]  Tapping a tile locks it: caption 'Required in every look', badge '◆'; the note reads '1 required · 2 flexible' for 3 selected; tapping again unlocks it
F04-A11  [U]  Match-review with nothing selected shows the notice 'Choose at least one item before continuing.' instead of the note, and 'Continue to preferences →' is disabled; 'Edit selected items' opens /match-select
F04-A12  [U]  Match-options renders head 'Styling Preferences', 'STEP 3 OF 3', 'Let's finish the look.', occasion select with 7 options (Everyday, Office, Wedding, Date Night, Casual, Party, Vacation), toggle 'Complete my outfits' checked by default, and the note 'Based on N selected items' / 'K must-wear piece(s) will be preserved. We will show up to three different combinations, without inventing new clothes.' (singular 'piece' when K is 1)
F04-A13  [U]  If StylistState.occasion is 'Casual Day Out' (not in the 7 options) the occasion field displays 'Everyday' and the screen does not throw; 'Everyday' is then used when generating
F04-A14  [U]  Unchecking 'Complete my outfits' sets accessories false and the resulting looks contain only selected items
F04-A15  [U]  '✧ Find my best matches' stores the chosen occasion, calls generateMatches, opens /matching-progress with head 'Matching Your Clothes' and 'Discovering your best combinations'; after 1150 ms the app is on /matching-results; leaving earlier prevents the jump
F04-A16  [U]  Matching-results renders head 'Your Best Matches', the context line '1 locked must-wear item · 3 selected candidates' (plural 'items' when locked count != 1), look cards named 'Best Match', 'Polished Alternative', 'Fresh Combination', and 'Edit chosen clothing' opening /match-select
F04-A17  [U]  Selecting only a locked single item with accessories off yields a single result containing that item (headline '1 look from your selection'), never zero and never a crash (Review Focus 2)
F04-A18  [U]  '↻ Refresh combinations' on matching-results re-runs generateMatches and returns through /matching-progress
F04-A19  [U]  Matching-detail renders head 'Outfit Details'; locked pieces carry ' · Locked' and a disabled 'Locked' button; back target is /matching-results
F04-A20  [U]  Header back targets: match-select -> /matching, match-review -> /match-select, match-options -> /match-review, matching-results -> /match-review
F04-A21  [U]  A selected id that was deleted from the wardrobe renders with the fallback name and does not crash match-review or generation
F04-A23  [U]  With zero items selected the flow cannot pass selection (prototype app.js:152-156): 'Continue with 0 items →' on match-select and 'Continue to preferences →' on match-review are both disabled and tapping them does not navigate; match-review shows 'Choose at least one item before continuing.'; so generateMatches is unreachable from the UI with an empty selection
F04-A22  [L]  In the running web build at 390x844, /#/matching -> Choose from my wardrobe -> select White Oxford Shirt, Navy Chinos, Blue Jeans -> lock White Oxford Shirt -> Find my best matches shows the loading screen then three looks all containing the shirt; screens match the prototype screenshots
```

## 12. Edge cases

Deleting items between steps leaves stale ids in `selected`; `createMatches` filters them (F03-A12). The `STEP` labels and `Let's` straight apostrophe are verbatim from the prototype.

## 13. Open questions

None.

---

## Completion block

```
Status: IMPLEMENTED (gate 4 pending)

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 22/23 PASS (A01-A21, A23; A22 [L] pending parity pass)
Regression: flutter test 162/162, flutter analyze clean
```
