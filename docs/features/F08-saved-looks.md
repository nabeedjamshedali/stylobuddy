# F08 — Saved Looks and Wear History

> My Looks (saved outfits and wear history tabs with search), saved outfit detail (mark as worn, plan, edit, share, delete) and wear journal detail. Plan Task 10; prototype `app.js:170-184`. Depends on foundation 03, 04.

**Status:** NOT STARTED · **Milestone:** 1 · **Depends on:** F01, F07, F09

---

## 1. Goal

Let users revisit saved looks, record when they wore them, and manage them.

## 2. MVP scope

Routes `/saved /saved-detail /wear-detail` (`savedRoutes`). `OutfitsCubit` (F01) stays; adds `SavedViewCubit`.

## 3. Later scope

Cloud sync of outfits and wear log; favourites; sharing as image.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/saved -> tab Saved Looks | Wear History -> search -> card -> /saved-detail?id | /wear-detail?id
/saved-detail: "✓ Mark as Worn Today" -> OutfitsCubit.logWear -> toast, counters update
  "Plan outfit" -> planner draft (outfit, its occasion) -> /calendar-date ; "Edit look" -> BuilderCubit.start(editId) -> /builder ; "Share" -> clipboard or modal
  "Remove from saved looks" -> modal -> "Remove outfit" -> OutfitsCubit.delete -> /saved + toast
/wear-detail: "Remove this wear entry" -> modal -> OutfitsCubit.removeWear -> toast
```

## 6. Interface surface

Routes `/saved /saved-detail /wear-detail`.

```text
SavedViewCubit{String tab = 'Saved' ('Saved'|'History'); String search = ''} (setTab clears search; setSearch)
Consumes: OutfitsCubit (byId, logWear, removeWear, delete, wearEvents), PlannerCubit.startScheduling (F09), BuilderCubit.start(editId:), LookBoard, AppModal, AppToast
```

## 7. Domain model usage

`Outfit`, `WearEvent` (name, occasion, items, timestamp), `ClothingItem` names via fallback.

## 8. Data changes

None.

## 9. Background work and events

None.

## 10. Degradation and failure

Outfit id not found -> 'This outfit is no longer saved.'; wear entry not found -> falls back to the first event of that outfit, else 'Wear entry unavailable'; wear's outfit deleted -> toast 'Original outfit was removed'; clipboard unavailable -> share modal.

## 11. Validation assertions

```
F08-A01  [U]  Saved renders 'YOUR STYLE ARCHIVE', 'My Looks.', 'Everything you love wearing, in one place.', total '2' 'saved looks', stats '2' 'Saved outfits', '0' 'Wears logged', '0' 'Worn looks' for the seed
F08-A02  [U]  Tabs 'Saved Looks' and 'Wear History': Saved Looks is active by default; tapping 'Wear History' switches the list and the search placeholder from 'Search your looks' to 'Search wear history'
F08-A03  [U]  Switching tabs clears the search text
F08-A04  [U]  Saved list shows 'Saved collection' '2 looks'; each card shows '<occasion> · <n> pieces', name, '<worn> times worn' and 'View look →' (e.g. 'Everyday · 4 pieces', 'Everyday Essential', '0 times worn') and opens '/saved-detail?id=<id>'
F08-A05  [U]  Searching 'weekend' shows only 'Modern Weekend' with count label '1 looks' (verbatim, no singular form); searching 'everyday' matches by occasion; searching an item name such as 'loafers' matches Modern Weekend; search is case-insensitive and trimmed ('  OFFICE  ' behaves like 'office')
F08-A06  [U]  Search '' shows all outfits (not the empty state); search 'zzzz' shows 'No matching outfits' and 'Try a different search.'
F08-A07  [U]  With zero outfits and no search, Saved Looks shows 'Your looks start here', 'Save an AI recommendation or build your own outfit to begin your collection.' and 'Explore AI Stylist' (-> /stylist)
F08-A08  [U]  Wear History with zero events shows 'Your outfit diary starts here', 'Open a saved look and tap “Mark as Worn” to build your personal style history.' and 'Browse saved looks' (switches to the Saved tab); with a non-matching search it shows 'No matching entries'
F08-A09  [U]  Wear History with events shows 'Outfits you wore' '<n> entries'; each card shows date 'October 15, 2026' style (MMMM d, y), name, '<n> pieces · <occasion>', first item image, newest first; tapping opens '/wear-detail?id=<eventId>'
F08-A10  [U]  Footer buttons '＋ Create a look' (-> /builder) and '✧ Get AI recommendations' (-> /stylist)
F08-A11  [U]  Saved-detail for outfit 1 renders head 'Outfit Details', 'SAVED / EVERYDAY', 'Everyday Essential', 'An outfit made from 4 pieces in your wardrobe.', tags 'Everyday' and '0 wears logged', 'Pieces in this look' '4 ITEMS' with a row per piece (name, '<category> · <color>') opening /clothing?id, and 'THE STYLE NOTE' with the outfit why text
F08-A12  [U]  Style note block is absent when the outfit's why is empty
F08-A13  [U]  Wear note reads 'You haven’t logged a wear for this look yet.' when worn is 0 (not hidden), 'You have worn this look 1 time.' when 1, 'You have worn this look 2 times.' when 2
F08-A14  [U]  '✓ Mark as Worn Today' calls logWear: toast 'Outfit wear recorded', outfit worn +1, each item's wears +1, wear log gains an entry, note and tag update, Wears logged stat becomes 1
F08-A15  [U]  'See all history →' opens /saved with the Wear History tab active
F08-A16  [U]  Action grid '▦ Plan outfit' calls PlannerCubit.startScheduling(outfitId, outfit.occasion) before pushing /calendar-date (draft equals this outfit and its occasion); '✎ Edit look' calls BuilderCubit.start(editId: id) and opens /builder titled 'Edit Your Outfit'
F08-A17  [U]  '↗ Share' with clipboard available copies '<name> (<occasion>) — <item names joined by ", ">. Styled with StyloBuddy.' and toasts 'Outfit description copied'; without clipboard it opens modal 'Share your outfit' with 'Copy this look description and send it to a friend.', the text in a read-only area and a 'Done' button that closes it
F08-A18  [U]  'Remove from saved looks' opens modal 'Remove saved outfit?' with 'This look will be removed from Saved. Recorded wear history will remain for your style insights.', 'Remove outfit' and 'Keep outfit'; 'Keep outfit' closes it without change
F08-A19  [U]  'Remove outfit' deletes the outfit, lands on /saved, toasts 'Look removed'; its WearEvents remain in the Wear History tab
F08-A20  [U]  Saved-detail for an id that is not saved renders head 'Saved Outfit', 'This outfit is no longer saved.' and 'Back to my looks' (-> /saved)
F08-A21  [U]  Wear-detail renders head 'Wear Journal', 'YOUR OUTFIT DIARY', a weekday date such as 'Thursday, October 15', '<name> · <occasion>', 'Worn pieces' '<n> ITEMS' (name, category), 'View saved look' and 'Remove this wear entry'
F08-A22  [U]  Wear-detail with an unknown event id but an existing outfit shows that outfit's first wear event; with neither renders head 'Wear History' and 'Wear entry unavailable'
F08-A23  [U]  'Remove this wear entry' opens modal 'Remove wear entry?' with 'This will update your wear counts.' and 'Remove entry'; confirming calls removeWear, closes the modal, toasts 'Wear entry removed', outfit worn -1 and item wears -1 (never below 0)
F08-A24  [U]  'View saved look' opens that outfit's detail; if the outfit was deleted it toasts 'Original outfit was removed' and stays
F08-A25  [U]  A wear event whose items were deleted from the wardrobe renders fallback names on wear-detail without throwing
F08-A26  [U]  Header back targets: saved-detail -> /saved, wear-detail -> /saved
F08-A27  [L]  In the running web build at 390x844: /#/saved -> open Everyday Essential -> Mark as Worn Today (toast 'Outfit wear recorded', '1 wears logged') -> See all history shows the entry -> open it -> remove the entry (toast 'Wear entry removed'); delete a look (toast 'Look removed'); screens match the prototype screenshots
```

## 12. Edge cases

Count labels are verbatim even when singular: the prototype writes `${outfits.length} looks` and `${log.length} entries` without pluralisation. Dates use the device locale in the prototype; the port fixes `en_US` formats.

## 13. Open questions

None. Resolved 2026-10-16: scheduling draft is `PlannerCubit.startScheduling` (F09).

---

## Completion block

```
Status: NOT STARTED

[ ] Gate 1  Interface documented
[ ] Gate 2  Unit
[ ] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 0/27 PASS
Regression: —
```
