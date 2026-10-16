# F09 — Calendar Planner

> A month calendar where saved outfits are planned per day, a chooser for the outfit, and a confirmation screen with date and occasion. Plan Task 11; prototype `app.js:185-198`. Depends on foundation 03, 04.

**Status:** IMPLEMENTED · **Milestone:** 1 · **Depends on:** F01

---

## 1. Goal

Let users decide outfits ahead of time and see them on a calendar.

## 2. MVP scope

Routes `/calendar /calendar-choose /calendar-date` (`calendarRoutes`). `PlannerCubit` (F01) stays; a small feature-local draft holds the outfit being scheduled and its occasion.

## 3. Later scope

Reminders from "Planned outfit reminders", weather overlay, calendar sync, cleaning up plans when an outfit is deleted.

## 4. Roles and permissions

guest / demo user; none gated.

## 5. Main flows

```text
/calendar -> select day / prev-next month -> "+ Plan an outfit →" or "Change planned outfit →" -> /calendar-choose
/calendar-choose -> pick outfit (draft = outfit, occasion = outfit.occasion) -> /calendar-date -> date, occasion -> "Confirm outfit plan →" -> PlannerCubit.plan(key, PlannedEntry) -> /calendar + toast
F08 "Plan outfit" and F03 plan modal enter here
/calendar "Remove" -> modal -> "Remove plan" -> PlannerCubit.remove + toast
```

## 6. Interface surface

Routes `/calendar /calendar-choose /calendar-date`. Uses `PlannerCubit` (`keyFor`, `selectedKey`, `select`, `navigate`, `plan`, `remove`, `label`), `OutfitsCubit.byId/state.outfits`, `LookBoard(size third)`, `AppModal`, `AppToast`. F09 adds to `PlannerCubit`/`PlannerState`: `int? editingOutfitId`, `String? editingOccasion`, `startScheduling(int outfitId, String occasion)`, `clearEditing()` (a shared-file change owned by F09, see F01 domain note in 03).

## 7. Domain model usage

`PlannedEntry{outfitId, occasion}` keyed `yyyy-MM-dd`; `Outfit` name/items/occasion; `PlannerState` year/month/day.

## 8. Data changes

None.

## 9. Background work and events

None.

## 10. Degradation and failure

No outfit planned for the day -> empty card. Planned outfit deleted -> same empty card (day still marked). No saved outfits -> chooser empty state. No draft outfit on `/calendar-date` -> prompt to choose.

## 11. Validation assertions

```
F09-A01  [U]  Calendar opens with head 'Outfit Planner', 'YOUR STYLE CALENDAR', 'Plan your looks ahead.', 'One less thing to decide every morning.', month 'October 2026' (label 'YOUR MONTH'), day names Su Mo Tu We Th Fr Sa, 31 day buttons, 4 leading blanks (Oct 1, 2026 is a Thursday)
F09-A02  [U]  Day 15 is active and carries the planned marker; selected-date label reads 'October 15, 2026' under 'SELECTED DATE'
F09-A03  [U]  Seed plan renders the card 'YOUR PLANNED LOOK' 'Everyday Essential' 'Everyday · 4 pieces' 'View outfit ↗' (opens /saved-detail?id=1), a 'Remove' button and 'Change planned outfit →'
F09-A04  [U]  Summary reads '✧ 1 planned look this month' and '● Planned outfit'; with 0 plans '✧ 0 planned looks this month'; with 2 '2 planned looks this month'
F09-A05  [U]  Selecting day 20 (no plan) shows 'No outfit planned yet', 'Choose one of your saved looks for this day.', '+ Plan an outfit →' and no Remove button
F09-A06  [U]  With day 31 selected, next month (›) shows 'November 2026' with day 30 selected; previous month (‹) from October shows 'September 2026'; a plan made in October is not counted in November's summary
F09-A07  [U]  Secondary actions 'View saved looks ↗' (-> /saved) and '✧ Ask AI for a look' (-> /occasion)
F09-A08  [U]  Calendar-choose renders head 'Choose an Outfit', 'PLANNING FOR OCTOBER 15, 2026', 'Pick your look.', 'Select any saved outfit to add it to your calendar.', one row per saved outfit ('<name>', '<occasion> · <n> pieces'), '+ Build a new outfit' (-> /builder) and '✧ Generate an AI outfit' (-> /occasion)
F09-A09  [U]  Calendar-choose with zero saved outfits shows 'No saved outfits yet' and 'Build or generate an outfit first.' (empty differs from a list)
F09-A10  [U]  Choosing an outfit opens /calendar-date with 'ALMOST THERE', 'Schedule your outfit.', 'A little planning goes a long way.', 'SELECTED LOOK', outfit name, '<n> items in your wardrobe', date input defaulting to the selected key, occasion select defaulting to the outfit's occasion with options Everyday, Office, Casual, Date Night, Wedding, Party, Travel, Other
F09-A11  [U]  Calendar-date with no draft outfit shows head 'Plan an Outfit' and 'Choose a saved outfit first.'
F09-A12  [U]  'Confirm outfit plan →' on Oct 15 stores PlannedEntry(outfitId, chosen occasion) at '2026-10-15', returns to /calendar and toasts 'Outfit planned for October 15, 2026'
F09-A13  [U]  Changing the date field to 2026-11-02 then confirming stores the plan at '2026-11-02', moves the calendar selection to Nov 2 and toasts 'Outfit planned for November 2, 2026'
F09-A14  [U]  Planning a second outfit on a day that already has one replaces it (one entry for the key)
F09-A15  [U]  'Remove' opens modal 'Remove this plan?' with 'This only removes the calendar plan. Your saved outfit stays in My Looks.' and buttons 'Keep plan' and 'Remove plan'; 'Keep plan' closes and keeps the plan
F09-A16  [U]  'Remove plan' deletes the entry, closes the modal, toasts 'Plan removed' and the day shows the empty card; the saved outfit still exists
F09-A17  [U]  A plan whose outfit was deleted renders the 'No outfit planned yet' card without crashing and the day is still counted in the summary (prototype behaviour)
F09-A18  [U]  Header back targets: calendar -> /home, calendar-choose -> /calendar, calendar-date -> /calendar-choose
F09-A20  [U]  PlannerState starts with editingOutfitId null and editingOccasion null (missing, distinct from any value)
F09-A21  [U]  startScheduling(2, 'Casual') sets editingOutfitId 2 and editingOccasion 'Casual'; clearEditing() sets both back to null; neither changes planned, year, month or day
F09-A22  [U]  After /calendar-choose picks an outfit the draft holds that outfit's id and occasion; after a successful confirm the draft is cleared
F09-A19  [L]  In the running web build at 390x844: /#/calendar shows October 2026 with 15 selected; plan 'Modern Weekend' for day 22 via Plan an outfit (toast 'Outfit planned for October 22, 2026'), then remove it (toast 'Plan removed'); screens match the prototype screenshots
```

## 12. Edge cases

Month navigation re-clamps the day each time. Plans are keyed by full ISO date so they survive month changes. Plan removal does not remove the outfit.

## 13. Open questions

None. Resolved 2026-10-16: `PlannerCubit` owns the draft (`editingOutfitId`, `editingOccasion`, `startScheduling`, `clearEditing`); F09 builds it, F08 depends on F09.

---

## Completion block

```
Status: IMPLEMENTED

[x] Gate 1  Interface documented
[x] Gate 2  Unit
[x] Gate 3  Integration
[ ] Gate 4  Live run

Assertions: 21/22 PASS (F09-A19 is [L], pending the parity pass)
Regression: flutter test — 251/251 passed; flutter analyze — No issues found!
```
