# F01 — Design Foundation

> Prototype design tokens, bundled fonts and assets, shared models and seed data, the four root Cubits (wardrobe, outfits, planner, profile), shared widgets, the router and the app shell. Plan Tasks 1–3, already built and reviewed. Depends on foundation 02, 03, 04.

**Status:** IN PROGRESS (Gates 1–3 done and reviewed; Gate 4 live run outstanding — see completion block) · **Milestone:** 1 · **Depends on:** —

---

## 1. Goal

Give every feature one shared, prototype-faithful base so screens differ only in content: tokens, assets, state that crosses features, and navigation.

## 2. MVP scope

`AppColors`, `AppTextStyles` (DMSans/Manrope), `AppTheme.light`, `AppAssets`; launcher icon and splash; `ClothingItem`, `Outfit`, `WearEvent`, `PlannedEntry`, `SeedData`; `WardrobeCubit`, `OutfitsCubit`, `PlannerCubit`, `ProfileCubit`; shared widgets; `AppRoutes`, router, `AppShell`, `StyloBuddyApp`; per-feature placeholder route files.

## 3. Later scope

Firestore-backed repositories; real product photos for the 7 SVG-fallback garments (`docs/image-prompts.md`); iOS-specific back handling.

## 4. Roles and permissions

guest / demo user (`07-security.md`); nothing gated.

## 5. Main flows

```text
app start -> /welcome (no bottom nav)
tab tap -> context.go(tab) ; drill-down -> context.push(route)
ScreenHead ‹ -> canPop ? pop : go(fallbackRoute)
system back on tab root != /home -> go /home ; on /home -> exit ; on pushed route -> pop
logWear(outfitId) -> append WearEvent, outfit.worn+1, items wears+1
```

## 6. Interface surface

```text
AppRoutes.<name> = '/<route-name>' (one per prototype route) ; clothing(id) savedDetail(int) wearDetail(int) ; clothingPath savedDetailPath wearDetailPath
AppRoutes.noNavRoutes ; AppRoutes.tabFor(location) ; createAppRouter({initialLocation}) ; appRouter ; AppShell(child)
AppAssets.localFashionIds ; garmentPath(id) ; isSvg(path) ; onboarding(file) ; appIcon
WardrobeRepository.loadItems()
WardrobeCubit: itemOrFallback(id) addItems(list) updateItem(item) removeItem(id) adjustWears(ids, delta)
OutfitsCubit(wardrobe, {clock}): byId(id) saveOrFind(draft) upsertManual({editingId, name, items, occasion}) delete(id) logWear(outfitId) removeWear(eventId) wearEvents({outfitId})
PlannerCubit: keyFor(y,m,d) selectedKey select(day) navigate(offset) plan(key, entry) remove(key) label(key)
ProfileCubit: updateDetails(name,email) togglePreference(PreferenceField, value) setDailyNotifications setPlannedNotifications setProductNotifications setWeatherConsent setClimate setPlan setBillingCycle
Widgets: ScreenHead PrimaryButton SecondaryButton DangerButton GarmentImage LookBoard(LookBoardSize) ItemTileGrid OptionTile SelectField SectionTitle
         AppToast.show AppModal.show/close LoadingView AppProgressBar DemoNote(kShowDemoNotes) BrandMark ChipButton GenericPreviewView StyloBuddyApp
```

## 7. Domain model usage

Defines `ClothingItem`, `Outfit`, `WearEvent`, `PlannedEntry`, `PlannerState`, `ProfileState` exactly as in `03-domain-model.md`.

## 8. Data changes

None (in-memory). Assets: `assets/fashion/*.webp` (17), `assets/garments/*.svg` (24), `assets/onboarding`, `assets/branding`, bundled fonts.

## 9. Background work and events

None. Toast lifetime 2200 ms.

## 10. Degradation and failure

Missing item id -> `itemOrFallback` placeholder; image load error -> SVG fallback; unknown route -> `GenericPreviewView`; removing a wear for an unknown event, or logging a wear for an unknown outfit, does nothing.

## 11. Validation assertions

```
F01-A01  [U]  AppAssets.garmentPath('white-shirt') == 'assets/fashion/white-shirt.webp'
F01-A02  [U]  garmentPath('cream-blouse') == 'assets/garments/cream-blouse.svg'; garmentPath('gold-jewelry') ends with '.svg'; isSvg is true for it and false for garmentPath('white-shirt')
F01-A03  [U]  AppAssets.localFashionIds has exactly 17 ids
F01-A04  [U]  assets/garments contains exactly 24 SVGs and every one of those ids plus the 23 seed ids resolves to an existing file via garmentPath
F01-A05  [U]  AppAssets.onboarding('onboard-00-rack.png') == 'assets/onboarding/onboard-00-rack.png' and the file at AppAssets.appIcon exists
F01-A06  [U]  WardrobeCubit seed: 23 items, items[0].id 'white-shirt', items[1].wears 1, items[22].wears 2 (wears = index % 5)
F01-A07  [U]  itemOrFallback('mystery-coat') -> name 'mystery coat', category 'Shirts', color 'Unknown', occasion 'Everyday'; itemOrFallback('white-shirt').name == 'White Oxford Shirt' (missing differs from present)
F01-A08  [U]  adjustWears(['white-shirt'], -5) leaves wears 0 (clamped); a following adjustWears(.., 2) gives 2
F01-A09  [U]  addItems([x]) -> 24 items; updateItem renames the matching item in place (stays first); removeItem('white-shirt') removes it
F01-A10  [U]  ClothingItem.imageId == id, or sourceId when sourceId is set
F01-A11  [U]  After removeItem('white-shirt'), itemOrFallback('white-shirt') still returns a placeholder and does not throw, while an Outfit that lists it is unchanged
F01-A12  [U]  OutfitsCubit seed: 2 outfits; byId(1).name 'Everyday Essential'; byId(99) is null
F01-A13  [U]  logWear(1) adds one WearEvent, sets outfit 1 worn to 1 and increments white-shirt wears by 1; removeWear(eventId) empties the log, restores worn 0 and the original wears
F01-A14  [U]  wearEvents() is newest first (outfit ids [1,2,1] after logging 1,2,1 at increasing clock values); wearEvents(outfitId: 2) has 1 entry; an outfitId with no events returns an empty list, not null
F01-A15  [U]  saveOrFind with items identical (same order) to outfit 1 returns id 1 and leaves 2 outfits
F01-A16  [U]  saveOrFind with new items inserts at index 0 with id from the injected clock (1000), worn reset to 0 (draft worn 4), 3 outfits
F01-A17  [U]  Two upsertManual calls at the same clock value get different ids
F01-A18  [U]  upsertManual(editingId: null, ...) inserts at index 0 with why 'A look you put together from your own wardrobe.' and worn 0
F01-A19  [U]  upsertManual(editingId: 2, ...) edits in place: id 2, still 2 outfits, new name/items, why unchanged (contains 'Earthy')
F01-A20  [U]  delete(1) makes byId(1) null; logWear on an unknown outfit id and removeWear on an unknown event id change nothing
F01-A21  [U]  PlannerCubit initial: selectedKey '2026-10-15' and planned['2026-10-15'].outfitId == 1
F01-A22  [U]  select(31) then navigate(1) gives month 11, day 30 (clamped)
F01-A23  [U]  navigate(3) -> (2027, 1); then navigate(-1) -> (2026, 12)
F01-A24  [U]  keyFor(2026,3,5) == '2026-03-05'; label('2026-10-15') == 'October 15, 2026'
F01-A25  [U]  plan('2026-10-20', entry) stores it; remove('2026-10-20') deletes the key
F01-A26  [U]  ProfileState defaults: name 'Alex Morgan', styleSummary 'Minimal • Smart casual', plan 'Free', productNotifications false
F01-A27  [U]  togglePreference adds 'Bold' to styles, a second call removes it; togglePreference(occasions, 'Travel') adds it
F01-A28  [U]  updateDetails('Sam','s@x.com'), the toggle setters, setClimate('Cold'), setPlan('Plus'), setBillingCycle('monthly') each update only their field
F01-A29  [U]  AppRoutes.tabFor: '/match-select' -> stylist; '/edit-item' and '/wardrobe' -> wardrobe; '/wear-detail' -> saved; '/premium' -> profile; '/calendar' -> home
F01-A30  [U]  tabFor ignores query strings: tabFor(clothing('white-shirt')) -> wardrobe; tabFor(savedDetail(3)) -> saved
F01-A31  [U]  clothing('x') == '/clothing?id=x'; savedDetail(2) == '/saved-detail?id=2'; wearDetail(5) == '/wear-detail?id=5'
F01-A32  [U]  Pumped at /home the app shows the five labels Home, Wardrobe, AI Stylist, Saved, Profile once each; at /welcome it shows none
F01-A33  [U]  Tapping 'Saved' in the nav navigates to '/saved'
F01-A34  [U]  System back on '/wardrobe' navigates to '/home'; on /home PopScope.canPop is true (not intercepted)
F01-A35  [U]  System back after router.push('/edit-item') from '/wardrobe' pops to '/wardrobe'
F01-A36  [U]  An unknown location renders 'Design preview only' inside a Material ancestor; the app boots to the welcome placeholder
F01-A37  [U]  ScreenHead back goes to fallbackRoute when the stack cannot pop, and pops when history exists
F01-A38  [U]  AppToast.show text is visible at 2100 ms and gone at 2250 ms
F01-A39  [U]  LookBoard(ids: [white-shirt, navy-chinos]) renders exactly 2 GarmentImage
F01-A40  [U]  SectionTitle with linkLabel 'View all' renders 'View all →' and fires onLink on tap
F01-A41  [U]  AppModal.show shows title and body; tapping '✕' removes them
F01-A42  [U]  OptionTile renders its description, uses border colour 0xFF086B52 when selected, and calls onTap
F01-A43  [U]  ItemTileGrid with selected {white-shirt}, locked {navy-chinos}, showLock true shows one '✓' and one '🔒'; with showLock false and nothing selected it shows neither
F01-A44  [L]  In the running web build at 390x844, /#/welcome shows no bottom nav and /#/home shows it with Home highlighted; tapping each tab changes the route; browser/system back from /#/edit-item returns to the previous screen
```

## 12. Edge cases

Same-millisecond ids are bumped past existing ids (F01-A17). `tabFor('/edit-item')` is wardrobe although the prototype shows Home (ruling, accepted).

## 13. Open questions

None.

---

## Completion block

```
Status: IN PROGRESS

[x] Gate 1  Interface documented
[x] Gate 2  Unit          (tests under test/core, test/shared, test/features/{wardrobe,saved,calendar,profile})
[x] Gate 3  Integration   (router/shell widget tests with the real app)
[ ] Gate 4  Live run      (F01-A44 not yet executed against the web build; do in plan Task 14)

Assertions: A01-A43 covered by existing, reviewed tests (not re-run by the document author); A44 pending
Regression: —
```
> Note 2026-10-16: A11 and the unknown-id halves of A20 describe behaviour present in code and Review Focus 1; confirm a named test exists, add one if not.
