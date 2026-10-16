# F12 — Style Insights

> A read-only wardrobe report: counts, category mix, wear activity, most-worn and underused pieces, occasion labels. Plan Task 13 (insights part, 13b); prototype `app.js:325-344`. Depends on foundation 03, 04.

**Status:** NOT STARTED · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Show the user a clear picture of what they own and wear.

## 2. MVP scope

Route `/insights` (`insightsRoutes`); pure `InsightStats.from(List<ClothingItem>)` (port of `insightStats`); donut and bars drawn with palette `['#0b8060','#67a68c','#a5c7af','#d5e3d9','#e6ceb0','#9c9da1','#c0cfc3','#718d7a']` (in `insights_tokens.dart`).

## 3. Later scope

Wear trends over time, cost per wear, exports.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/insights -> InsightStats.from(wardrobe items) (+ OutfitsCubit.wearLog.length for "LOGGED WEARS") -> sections
garment row -> /clothing?id ; "View wear history →" -> /saved (History tab) ; "Match My Clothes →" -> /matching
empty wardrobe -> empty state -> "Add clothing" -> /import
```

## 6. Interface surface

Route `/insights`.

```text
InsightStats.from(List<ClothingItem>) -> {items, count, wears, cats: [(category, n)] sorted desc stable by first appearance, worn, top (by wears desc, stable), least (first 5 with wears 0), occasions: [(occasion, n)] sorted desc stable}
Event count comes from OutfitsCubit.state.wearLog.length (how it is passed in is left to the builder)
```

## 7. Domain model usage

Reads `ClothingItem` (category, occasion, wears, name, id) and `Outfit`-side `WearEvent` count.

## 8. Data changes

None.

## 9. Background work and events

None.

## 10. Degradation and failure

Empty wardrobe -> empty state (not zeros). All items worn -> underused list falls back to the 4 lowest-wear items. Empty occasion string -> counted as 'Everyday'.

## 11. Validation assertions

Expected values for the seed were derived by hand from `app.js:2-3` (wears = index % 5); re-verify with `node` when implementing.

```
F12-A01  [U]  InsightStats.from(seed): count 23, wears 43, worn 18, unused 5
F12-A02  [U]  InsightStats.from(seed).cats in order: Shirts 5, Accessories 5, Pants 4, Shoes 4, Dresses 2, Outerwear 2, Skirts 1 (7 categories)
F12-A03  [U]  InsightStats.from(seed).occasions in order: Casual 8, Office 7, Party 3, Everyday 2, Wedding 2, Date Night 1
F12-A04  [U]  InsightStats.from(seed).top first four are navy-chinos, brown-loafers, sage-dress, cream-cardigan (wears 4, ties keep wardrobe order); least is white-shirt, beige-chinos, black-boots, black-skirt, black-heels
F12-A05  [U]  An item with wears 0 is counted as unworn (zero is a value, not missing); an item whose occasion is an empty string is counted under 'Everyday'
F12-A06  [U]  InsightStats.from([]) reports count 0 (empty, not a crash) and the screen shows the empty state
F12-A07  [U]  Empty wardrobe renders head 'Style Insights', '▦', 'Insights start with your wardrobe', 'Add your first clothing pieces to see category breakdowns, style patterns and wearing habits.' and 'Add clothing' (-> /import)
F12-A08  [U]  Seed report renders 'YOUR PERSONAL STYLE REPORT', 'Style Insights.', 'A clearer picture of what you own and wear.', stat cards WARDROBE '23' 'clothing pieces', LOGGED WEARS '0' 'outfit wear entries', EVER WORN '18' 'tracked pieces'
F12-A09  [U]  After OutfitsCubit.logWear(1) the LOGGED WEARS card reads '1' (zero logged wears shows '0', not blank)
F12-A10  [U]  'Your wardrobe mix' reads '7 categories'; the donut centre shows '23' 'items'; the legend lists percentages Shirts 22%, Accessories 22%, Pants 17%, Shoes 17%, Dresses 9%, Outerwear 9%, Skirts 4% (rounded)
F12-A11  [U]  'Category breakdown' / 'Items owned' lists one bar per category with its count; the widest bar is 100% for the largest count and others are count/max (Pants 80%)
F12-A12  [U]  'Wear activity' / 'Recorded manually' shows '18' ' / 23' 'pieces with recorded wears', a progress bar at 78%, and '5 items have no recorded wears. This uses the demo’s item wear counters; it is not a prediction of how often you actually dress in each piece.'; with exactly 1 unused it reads '1 item has no recorded wears. ...'
F12-A13  [U]  'View wear history →' opens /saved with the Wear History tab active
F12-A14  [U]  'Most-worn pieces' / 'Top items' shows 4 rows with subtitles like '4 recorded wears · Pants' (navy-chinos first); tapping a row opens '/clothing?id=<id>'
F12-A15  [U]  'Rediscover your wardrobe' / 'Underused pieces' shows 5 rows '0 recorded wears · Try styling this piece' (white-shirt first)
F12-A16  [U]  When every item has wears >= 1, the underused list shows the 4 lowest-wear items instead (reversed top order)
F12-A17  [U]  'Occasion readiness' / 'Wardrobe labels' rows render '<name>' '<n> pieces' verbatim, including '1 pieces' for Date Night
F12-A18  [U]  The callout shows 'Put your wardrobe to work', 'Find new combinations for clothes you already own.' and 'Match My Clothes →' (-> /matching); the disclaimer 'Insights are based on wardrobe details and manually recorded wears. No external fashion model is connected in this demo.' renders
F12-A19  [U]  Section caption with a single category reads '1 categories' (verbatim, no pluralisation)
F12-A20  [U]  Insights rows for items deleted from the wardrobe are never produced (stats derive only from current items)
F12-A21  [L]  In the running web build at 390x844: /#/insights matches the prototype screenshot (seed numbers 23 / 0 / 18, donut, bars); mark a look as worn, return and see LOGGED WEARS 1; the Profile tab is not highlighted (insights is under Home per tabFor)
```

## 12. Edge cases

Donut is a conic gradient in CSS; Flutter equivalent is a custom painter (closest-look rule). Percent rounding uses round-half-up on `n/total*100`.

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

Assertions: 0/21 PASS
Regression: —
```
