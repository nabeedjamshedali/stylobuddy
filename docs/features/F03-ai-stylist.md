# F03 — AI Stylist

> The stylist hub, occasion picker, styling preferences, simulated generation, results and result detail (save, plan, swap, share), plus the shared results engine `StylistCubit` used by F04 and F05. Plan Task 6; prototype `app.js:102-148`. Depends on foundation 03, 04.

**Status:** DONE (gates 1-3; gate 4 open) · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Give three coordinated looks from owned clothes for an occasion, let the user save, plan, swap and share them, and expose the same engine for Match My Clothes.

## 2. MVP scope

Routes `/stylist /occasion /styling-options /generating /results /result-detail`; `StylistCubit` provided at the app root; exported `ResultsView(match)` and `ResultDetailView(match)`; `createMatches` exact port of `app.js:112-136`.

## 3. Later scope

Real AI model behind the same Cubit; scoring; persisted result history.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/stylist -> "Style me for today" -> /occasion -> Next -> /styling-options -> "Generate 3 looks ✧"
  -> generateAutomatic: isGenerating true -> /generating -> 1150 ms -> results set -> /results (only if still on /generating)
/results -> look card -> /result-detail
  heart/Save -> OutfitsCubit.saveOrFind -> toast + /saved-detail
  Plan -> modal day grid 15..31 -> PlannerCubit.plan('2026-10-<dd>') + select(dd) -> /calendar + toast
  Swap -> modal of same-category alternatives -> swapItem -> toast 'Garment replaced'
  Share -> modal with summary text
```

## 6. Interface surface

Routes: `/stylist /occasion /styling-options /generating /results /result-detail` (`stylistRoutes`).

```text
StylistCubit (app root) state StylistState{occasion='Everyday'; results: List<StyleResult>; activeIndex; selected: List<String>; locked: List<String>; accessories=true; category='All'; isMatchMode; isGenerating}
StyleResult{int id; String name; List<String> items; String occasion; String why}
setOccasion(String) ; Future<void> generateAutomatic() ; Future<void> generateMatches() ; List<List<String>> createMatches()
toggleSelect(id) ; toggleLock(id) ; setCategory(String) ; setAccessories(bool) ; startMatching() ; selectAndLock(String id)
swapItem(String oldId, String newId) ; String shareSummary()
ResultsView({bool match}) ; ResultDetailView({bool match})
Consumes: WardrobeCubit, OutfitsCubit.saveOrFind, PlannerCubit.plan/select/keyFor, LookBoard, AppModal, AppToast, LoadingView, SelectField, DemoNote
```
(`isGenerating` is named in the plan's behaviour text but not its state list; recorded here.)

## 7. Domain model usage

Reads `ClothingItem` (category, id, name, color), writes `Outfit` via `saveOrFind`, writes `PlannedEntry` (outfitId = saved outfit id, occasion = outfit occasion) keyed `2026-10-<dd>`.

## 8. Data changes

None (in memory).

## 9. Background work and events

Simulated delay `Duration(milliseconds: 1150)`; the follow-up navigation happens only if the user is still on the waiting route.

## 10. Degradation and failure

Template item not in wardrobe: filtered out of the look. Empty wardrobe: generation completes, results render without crash. No `results` on result-detail: stylist hub renders. No alternatives: toast. Locked item swap in match mode: toast. Selection empty: no matches.

## 11. Validation assertions

```
F03-A01  [U]  generateAutomatic with the seed wardrobe yields 3 results named 'Refined Everyday', 'Modern Classic', 'Effortless Edge' whose items are [white-shirt, navy-chinos, white-sneakers, black-watch], [black-shirt, beige-chinos, brown-loafers, tan-belt], [blue-shirt, black-jeans, black-boots, sunglasses]
F03-A02  [U]  After removing 'white-shirt' from the wardrobe, look 1 is [navy-chinos, white-sneakers, black-watch] (ids not in wardrobe filtered out, no placeholder item added)
F03-A03  [U]  With an empty wardrobe generateAutomatic completes without throwing and sets 3 results whose items are empty (missing, not a crash); the results screen renders
F03-A04  [U]  Result why copy for index 0,1,2: 'Considered proportions and a cohesive level of formality make these pieces feel intentional.' / 'The contrast and garment textures work together for a balanced, refined look.' / 'A relaxed combination with complementary shapes, tones and accessories.'; each result.occasion equals the current occasion
F03-A05  [U]  generateAutomatic sets isGenerating true immediately and, after 1150 ms (fake async), sets results and isGenerating false; before 1150 ms results are unchanged
F03-A06  [U]  createMatches with selected [white-shirt, navy-chinos, blue-jeans], locked [white-shirt], accessories on returns exactly [[white-shirt, navy-chinos, white-sneakers, black-watch], [white-shirt, blue-jeans, brown-loafers, black-bag], [white-shirt, navy-chinos, black-boots, tan-belt]]
F03-A07  [U]  In A06 every look contains white-shirt, every look has exactly one Shoes item and one Accessories item that is not in selected, no two looks have the same sorted item set, and at most 3 looks are returned
F03-A08  [U]  Same selection with accessories off returns exactly [[white-shirt, navy-chinos], [white-shirt, blue-jeans]] (duplicates skipped, no shoes or accessories added)
F03-A09  [U]  createMatches with selected [black-skirt], locked [black-skirt], accessories off returns exactly [['black-skirt']] (locked items are never dropped, never zero looks)
F03-A10  [U]  createMatches with selected [black-skirt], locked [black-skirt], accessories on returns [[black-skirt, white-sneakers, black-watch], [black-skirt, brown-loafers, black-bag], [black-skirt, black-boots, tan-belt]] (up to 3 looks, each containing black-skirt plus one Shoes item and one Accessories item not selected)
> Amended 2026-10-16: replaces the plan's "exactly one look" with the true prototype behaviour.
F03-A11  [U]  Whenever StylistState.results is empty the results view shows 'No valid combinations yet' and 'Try including another garment category or adjusting mandatory selections.' (and headline '0 looks from your selection'); createMatches with nothing selected and accessories off returns [] (no guard is added: it is an exact port)
> Amended 2026-10-16: the empty-selection guard was removed; createMatches is an exact port of app.js:112-136. Preventing a zero-selection run is asserted in F04-A23.
F03-A12  [U]  createMatches ignores selected ids that are not in the wardrobe, and ignores locked ids that are not selected
F03-A13  [U]  generateMatches names results 'Best Match', 'Polished Alternative', 'Fresh Combination' (a 4th would be 'Look 4') and sets isMatchMode true; generateAutomatic sets it false
F03-A14  [U]  toggleSelect adds then removes an id; deselecting a locked id also removes it from locked; toggleLock adds/removes in locked; startMatching clears selected and locked and sets category 'All'; selectAndLock('x') sets selected [x] and locked [x]
F03-A15  [U]  setOccasion changes occasion; setAccessories(false) is reflected in createMatches (A08)
F03-A16  [U]  swapItem(oldId, newId) replaces old by new at the same position in the active result and sets why to 'This preview pairs <new name> with the other selected wardrobe pieces. Review the complete styling before wearing.'
F03-A17  [U]  In match mode swapItem for a locked oldId changes nothing and surfaces toast text 'Mandatory items cannot be swapped'
F03-A18  [U]  shareSummary() == '<name> — StyloBuddy\n• <item name>\n• ...\n\n<why>' for the active result
F03-A19  [U]  Stylist hub renders 'STYLOBUDDY / PERSONAL STYLING', 'Your personal' 'style studio.', 'Thoughtful outfits from pieces already in your closet.', 'Style me for today', 'Match my clothes', 'Build an outfit myself', 'Only clothes you own. No imaginary items.', 'What makes a good match?', factors '01 Shape & silhouette' .. '04 Color & personality', and the simulated-recommendations disclaimer; the three buttons open /occasion, /matching, /builder
F03-A20  [U]  Occasion screen: head 'Select Occasion', 8 options (Everyday, Office, Wedding, Date Night, Casual Day Out, Party, Interview, Vacation) with Everyday selected by default; tapping another selects it exclusively; 'Next →' opens /styling-options
F03-A21  [U]  Styling-options renders 'Your Styling Preferences', selects 'Style direction' (Smart casual default) and 'Weather' (Mild / all season default), the notice 'Your owned wardrobe items are the only garments used in results.' and 'Generate 3 looks ✧'
F03-A22  [U]  Generating renders head 'Finding Your Style', 'Putting looks together...' and the loading message; after 1150 ms the app is on /results; if the user left the route earlier no navigation occurs
F03-A23  [U]  Results with 3 results: 'YOUR PERSONAL STYLE EDIT', 'Three looks, made for you', 'Real pieces in your wardrobe, thoughtfully put together for everyday.' (lower-cased occasion), cards 'LOOK 01 / 03', look name, 'Explore this outfit →'; with 1 result the headline is '1 look from your selection', with 0 '0 looks from your selection'
F03-A24  [U]  Results buttons: 'Change occasion' opens /occasion, '↻ Refresh combinations' regenerates (back to /generating), disclaimer 'Styling examples are simulated. No real AI evaluation or percentage scores are claimed.' renders; tapping a card sets activeIndex and opens /result-detail
F03-A25  [U]  Result detail renders 'STYLOBUDDY / THE STYLE EDIT', 'LOOK 01 OF 03', look name, 'A complete look, styled from your own wardrobe.', 'Every item is from your wardrobe', 'Why this outfit works', criteria 'Visual harmony' 'Balanced proportions' '<Occasion> ready', 'Your pieces' with '<n> items', and the four actions '♡ Save Outfit' '▦ Plan Outfit' '↗ Share look' '↻ New suggestions'
> Note 2026-10-16 (implementation): the prototype renders the index padded but the total unpadded, so the shipped copy is 'LOOK 01 OF 3' (app.js resultDetails). Tests assert the prototype copy; the results card keeps 'LOOK 01 / 03'.
F03-A26  [U]  Result detail with no results renders the stylist hub ('Your personal' 'style studio.') instead of crashing (missing vs empty)
F03-A27  [U]  Save Outfit calls OutfitsCubit.saveOrFind: a result identical in items order to an existing outfit reuses it (list length unchanged); otherwise a new outfit is inserted at index 0; toast 'Saved to your outfits' and navigation to /saved-detail
F03-A28  [U]  (Plan modal does not use the scheduling draft; it calls plan directly.) Plan Outfit opens modal 'Plan this outfit' with body 'Choose a date in October 2026 for <name>.' and 17 day buttons 15..31; tapping 20 calls PlannerCubit.plan('2026-10-20', ...) (not a numeric key), selects day 20, closes the modal, lands on /calendar and toasts 'Outfit scheduled for October 20'
F03-A29  [U]  Swap on a piece with alternatives opens modal 'Swap <name>' with 'Choose another <category lower-case> from your wardrobe. Your other pieces will stay the same.' listing only same-category items not already in the look; choosing one replaces it, closes the modal and toasts 'Garment replaced'
F03-A30  [U]  Swap when no same-category alternative exists toasts 'No alternative in your wardrobe for this category' and opens no modal
F03-A31  [U]  In match mode, locked pieces show the suffix ' · Locked' and a disabled button labelled 'Locked' (tooltip 'Unlock this piece in Match My Clothes first'); unlocked pieces show 'Swap'
F03-A32  [U]  Share look opens modal 'Share this look' with 'Copy the outfit details below and share them with someone.', a read-only text area equal to shareSummary(), and 'Copy look details'; copy success toasts 'Outfit details copied', clipboard failure toasts 'Select and copy the text above'
F03-A33  [U]  A look item deleted from the wardrobe after generation renders via the fallback name (e.g. 'white shirt') on result detail without throwing
F03-A34  [L]  In the running web build at 390x844: /#/stylist -> Style me for today -> Next -> Generate 3 looks ✧ shows the loading screen then three looks after ~1.15 s; opening look 1 and tapping Plan Outfit -> 20 lands on the calendar with day 20 marked and the toast 'Outfit scheduled for October 20'; screens match the prototype screenshots
```

## 12. Edge cases

Plan modal day grid is fixed 15-31 (October 2026) as in the prototype. Result ids come from the clock. A result renamed by swap keeps its name. The prototype stores `S.planned[d]` with a numeric key (bug); the port uses the date key (Review Focus 3).

## 13. Open questions

None. Resolved 2026-10-16: `createMatches` is an exact port (A09-A11 amended); `generateAutomatic()` takes no argument, callers use `setOccasion` first.

---

## Completion block

```
Status: DONE (gates 1-3); gate 4 open

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 33/34 PASS (A34 [L] pending parity pass)
Regression: flutter test 137 passed; flutter analyze clean
```
