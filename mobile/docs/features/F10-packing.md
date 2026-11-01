# F10 — Packing Assistant

> Create trips, get a suggested packing list from the owned wardrobe, check items off, add wardrobe pieces or custom essentials, and delete trips. Plan Task 12; prototype `app.js:199-219`. Depends on foundation 03, 04.

**Status:** DONE (gates 1-3; gate 4 open) · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Help users pack for a trip using only clothes they own.

## 2. MVP scope

Routes `/packing /new-trip /packing-preview /packing-list /packing-add` (`packingRoutes`); `PackingCubit` with feature-local `Trip` and `PackingItem` models.

## 3. Later scope

Weather-aware suggestions, outfit-per-day plans, trip persistence in Firestore.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/packing -> "＋ Create a trip →" -> /new-trip -> validate -> save -> /packing-preview -> "Create packing checklist →" -> /packing-list
/packing-list: toggle packed, remove ×, "✎ Edit trip" -> /new-trip (edit) -> save -> /packing-list ; "＋ Add items" -> /packing-add -> Done
"Delete trip" -> modal -> "Delete trip" -> removed -> /packing + toast
```

## 6. Interface surface

Routes as above.

```text
Trip{String id ('trip-<ts>'); name; destination; start; end (yyyy-MM-dd); type; notes; int days; List<PackingItem> items}
PackingItem{String key; String label; String? wardrobeId; bool packed}
PackingCubit: trips, selected trip id, draft; suggestions(trip) = port of pkSuggested; create/edit/save draft, generate checklist, toggle(key), remove(key), addWardrobe(id), addCustom(label), deleteTrip()  (method names left to the builder; behaviour below)
Consumes: WardrobeCubit, AppProgressBar-style bar, AppModal, AppToast, SelectField
```

## 7. Domain model usage

Reads `ClothingItem` (id, name, category, occasion). `PackingItem.wardrobeId` is a `ClothingItem.id` or none (custom essentials).

## 8. Data changes

None.

## 9. Background work and events

None.

## 10. Degradation and failure

Invalid trip form -> toast, stay. Blank custom item -> ignored. Wardrobe item removed after being packed -> list row keeps its stored label and image falls back. No trip selected -> prompt text.

## 11. Validation assertions

```
F10-A01  [U]  First open: 'TRAVEL, WELL STYLED', 'Pack smart.' 'Travel light.', 'Your trips' '0 trips', empty state 'No trips planned yet' / 'Create your first trip to get a personalized packing checklist.', and the feature card 'Your wardrobe goes with you.'
F10-A02  [U]  Trip count label: '0 trips', '1 trip', '2 trips'
F10-A03  [U]  Saving a draft with an empty name toasts 'Add a trip name and both dates' and creates no trip
F10-A04  [U]  Saving with a whitespace-only name '   ' toasts 'Add a trip name and both dates' (trimmed) and creates no trip
F10-A05  [U]  Saving with a name but a missing start date, or a missing end date, toasts 'Add a trip name and both dates'
F10-A06  [U]  Saving with end before start toasts 'End date must be after start date'; end equal to start is accepted (days = 1)
F10-A07  [U]  Days = whole days between start and end inclusive, minimum 1: 2026-11-01..2026-11-03 gives 3
F10-A08  [U]  A valid new trip is inserted at the front with id 'trip-<ts>', empty items, trimmed text fields, and navigates to /packing-preview; saving an edit keeps the id and existing items and navigates to /packing-list
F10-A09  [U]  suggestions for a 3-day Vacation trip on the seed wardrobe (limit max(5, min(12, days*3)) = 9) are, in order, white-shirt, black-shirt, blue-shirt, cream-blouse, navy-chinos, beige-chinos, black-jeans, blue-jeans, white-sneakers, then black-watch, black-bag (2 extras from Outerwear/Accessories) = 11 items, all packed false, label = item name
F10-A10  [U]  A 1-day trip yields 5 base items + 2 extras = 7; a 5-day trip yields 12 + 2 = 14
F10-A11  [U]  For type 'Business' (1 day) the five base items are Office-occasion items first in wardrobe order: white-shirt, cream-blouse, navy-chinos, brown-loafers, black-skirt
F10-A12  [U]  Suggestions use only existing wardrobe items; with an empty wardrobe the list is empty (no crash)
F10-A13  [U]  'Create packing checklist →' fills the trip's items only when it has none; running it again does not duplicate or reset packed flags
F10-A14  [U]  Toggling an item flips packed; progress is round(packed/total*100): 3 of 11 -> '27% packed' with '3 of 11 items ready'; 11 of 11 -> '100% packed' and the mark '✓' (otherwise '✧')
F10-A15  [U]  A trip with zero items shows '0% packed', '0 of 0 items ready' and the empty list state 'Your list is empty' / 'Add clothing from your wardrobe to start packing.' (zero differs from missing)
F10-A16  [U]  Removing a checklist row (×) deletes it and updates the counts
F10-A17  [U]  Adding a wardrobe item from /packing-add appends {key: id, label: name, wardrobeId: id, packed: false}; already-added items show 'Added' and are disabled, others show '＋ Add'; adding the same id twice never duplicates
F10-A18  [U]  Adding a custom item with a blank or whitespace-only name adds nothing and the modal stays open; 'Phone charger' adds a row with no wardrobeId (shown with '✧' thumbnail), closes the modal 'Add a travel essential'
F10-A19  [U]  The custom-item modal shows 'Add items such as socks, toiletries, or chargers.', label 'Item name', placeholder 'e.g. Phone charger' and button 'Add item'
F10-A20  [U]  'Delete trip' opens modal 'Delete this trip?' with 'This removes the trip and its checklist. Your wardrobe items stay safe.'; confirming 'Delete trip' removes it, lands on /packing and toasts 'Trip removed'
F10-A21  [U]  Trip card shows name, '<destination or type> · <Oct 5> – <Oct 8>', 'N of M packed' and a progress bar; with an empty destination it shows the trip type; with missing dates the label is 'Choose dates'
F10-A22  [U]  New-trip renders head 'New Trip' (or 'Edit Trip'), 'TRIP DETAILS', 'Where to next?' (or 'Update your getaway.'), labels 'Trip name *' 'Destination' 'Start date *' 'End date *' 'Type of trip' (Vacation, Business, City break, Beach, Formal event, Other) 'Activities or notes', primary 'Continue to packing plan →' (or 'Save changes →'); name max 60, destination max 70
F10-A23  [U]  Packing-preview renders 'YOUR TRAVEL EDIT', 'A thoughtful starting point.', 'Based on your owned wardrobe and 3-day vacation trip. Suggestions are a demo, not live AI.', 'Suggested pieces' with the item count; with no trip selected it shows 'No trip selected.'
F10-A24  [U]  Packing-list with no trip selected shows 'Choose a trip first.'; with a trip shows 'TRIP CHECKLIST', trip name, '✎ Edit trip', '＋ Add items', '＋ Add clothing or essentials', 'Delete trip'
F10-A25  [U]  A trip item whose wardrobe item was removed still renders its stored label with the fallback image and does not crash
F10-A26  [U]  Header back targets: packing -> /home, new-trip -> /packing (or /packing-list when editing), packing-preview -> /new-trip, packing-list -> /packing, packing-add -> /packing-list
F10-A27  [L]  In the running web build at 390x844: /#/packing empty state; create 'Lisbon' 2026-11-01..2026-11-03 (blank name first -> toast 'Add a trip name and both dates'), see 11 suggestions, create the checklist, tick 3 ('27% packed'), delete the trip (toast 'Trip removed'); screens match the prototype screenshots
```

## 12. Edge cases

Dates are ISO strings compared lexicographically as in the prototype. Trips live in memory only. Prototype ignores a blank custom item silently (no toast).

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

Assertions: 26/27 PASS (A27 is [L], pending the parity pass)
Regression: flutter test -> 313/313 passed; flutter analyze -> No issues found!
```
