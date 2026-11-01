# StyloBuddy Prototype Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the StyloBuddy Flutter app so all 64 screens, copy and flows match the v23 HTML prototype exactly.

**Architecture:** go_router with an app shell (bottom nav) around feature routes; per-feature Cubits, with cross-feature Cubits (wardrobe, outfits, planner, profile) provided at the root and seeded from the prototype's sample data; shared design tokens and widgets in `lib/core` and `lib/shared`; every feature owns `lib/features/<f>/` including its `<f>_routes.dart`.

**Tech Stack:** Flutter 3.44 / Dart ^3.12, flutter_bloc (Cubit only, no Freezed), go_router, google_fonts (bundled DM Sans + Manrope), flutter_svg, intl, flutter_launcher_icons, flutter_native_splash.

**Spec:** `docs/superpowers/specs/2026-10-16-prototype-port-design.md`

**Prototype source (`P`):** `C:\Users\DELL\Downloads\stylobuddy-v23-mobile-icon-final\stylobuddy-prototype` — `app.js` (screen markup, copy, behavior) and `styles.css` (styling). Lines in `app.js`/`styles.css` are very long; read the cited line ranges, and for CSS always apply the **last** matching rule in the file (later version sections override earlier ones; V22 forces `.product-image`/`.look-board` background `#eff0ef`, `object-fit: contain`).

## Global Constraints

- Copy is verbatim from `P/app.js` (including punctuation like `’` `“ ”` `→` `↗` `✧`). No rewording, no added/removed screens or controls.
- CSS px → Flutter logical px 1:1 (prototype mobile viewport 390×844). Screen horizontal padding = `.app-content` `20px` (onboarding pages `16px`).
- Fonts: body DM Sans, headings that CSS sets to `Manrope` use Manrope. Bundled assets, `GoogleFonts.config.allowRuntimeFetching = false`.
- Glyph icons are the prototype's unicode glyphs rendered as `Text`; inline SVG icons are the prototype's SVG path strings rendered with `SvgPicture.string`. No Material `Icons.*` in feature UI.
- No inline hex colors or raw `TextStyle` in feature widgets except values that exist only in that feature's CSS section — put those in a `<feature>_tokens.dart` file inside the feature (`abstract final class HomeTokens { static const ... }`).
- Widgets contain UI only; state changes go through Cubits. States are plain classes with hand-written `copyWith`.
- Feature tasks may only create/modify files under their own `lib/features/<feature>/` and `test/features/<feature>/`. Shared files (`lib/core`, `lib/shared`, `pubspec.yaml`, router) belong to Tasks 1–3; if a feature needs a shared change, it reports it instead of making it.
- Demo/simulation disclaimer strings render via `DemoNote` (Task 3).
- Simulated processing delay: `Duration(milliseconds: 1150)`.
- Do **not** commit in parallel waves; the controller commits each task after review.

## Review Focus

1. **Empty wardrobe / deleted items:** removing an item that a saved outfit, plan or trip references must not crash any screen (prototype `get()` falls back to a name derived from the id). Test owner: Task 2 (`WardrobeCubit.itemOrFallback`).
2. **Match My Clothes with only locked items or a single category:** `createMatches` must return the locked items as one look rather than zero/crash. Test owner: Task 6.
3. **Plan outfit from result detail:** the prototype stores `S.planned[d]=o.id` (bug — number key). Port plans to date key `2026-10-<dd>` so it shows on the calendar. Test owner: Task 6 (`planResult` → `PlannerCubit.plan`).
4. **Back navigation from deep links in the shell:** header back pops when possible, otherwise goes to the prototype's explicit back route; Android system back on a tab root must not exit into onboarding. Test owner: Task 3.
5. **Text inputs with whitespace-only values** (outfit name, trip name, item name, profile name, custom packing item) are rejected with the prototype's toast message. Test owners: Tasks 8, 9, 12, 13.

---

### Task 1: Theme, fonts, assets, launcher icon, splash (replace old design)

**Files:**
- Delete: `lib/core/theme/*`, `lib/features/onboarding/**`, `lib/features/splash/**`, `lib/features/home/view/home_placeholder_view.dart`, `lib/shared/widgets/*`, `assets/images/onboarding_hero_portrait.png`
- Create: `lib/core/theme/app_colors.dart`, `lib/core/theme/app_text_styles.dart`, `lib/core/theme/app_theme.dart`, `lib/core/assets/app_assets.dart`
- Create assets: `assets/onboarding/onboard-0{0..4}-*.png`, `assets/fashion/*.webp` (17 ids in `LOCAL_FASHION`, `P/app.js:29`), `assets/garments/*.svg` (all 24 SVGs from `P/assets/*.svg`), `assets/branding/` (icon-1024, icon-512, android-adaptive-foreground.png), `assets/google_fonts/` (DMSans + Manrope static TTFs, weights 400–800)
- Modify: `pubspec.yaml`, `lib/main.dart`, `android/app/src/main/AndroidManifest.xml` (label `StyloBuddy`)
- Create: `docs/image-prompts.md`
- Test: `test/core/app_assets_test.dart`

**Interfaces:**
- Produces:
  - `abstract final class AppColors` — `green 0xFF086B52`, `dark 0xFF0A4537`, `ink 0xFF18221E`, `muted 0xFF777F79`, `line 0xFFE9EBE7`, `soft 0xFFF5F5F1`, `bg 0xFFF7F7F4`, `primaryButton 0xFF08775A`, `productBg 0xFFEFF0EF`, `white`, `brandGreen 0xFF087F62`, `adaptiveIconBg 0xFF006F54` (final `:root` in `P/styles.css:7` + `.primary` line 9 + V22).
  - `abstract final class AppTextStyles` — `static TextStyle dmSans({double size, FontWeight weight, Color? color, double? height, double? letterSpacing})` and `static TextStyle manrope({...same})`.
  - `AppTheme.light` (`ThemeData`, white scaffold, DM Sans text theme, `AppColors.green` primary).
  - `abstract final class AppAssets` — `static const localFashionIds = <String>{...17 ids...}`; `static String garmentPath(String id)` → `assets/fashion/$id.webp` if in set, else `assets/garments/$id.svg`; `static bool isSvg(String path)`; `static String onboarding(String file)`; `static const appIcon = 'assets/branding/stylobuddy-icon-512.png'`.

- [ ] **Step 1: Write failing test** `test/core/app_assets_test.dart`: `garmentPath('white-shirt') == 'assets/fashion/white-shirt.webp'`; `garmentPath('cream-blouse') == 'assets/garments/cream-blouse.svg'`; `garmentPath('gold-jewelry')` ends with `.svg`; `localFashionIds.length == 17`; for every id in the seed list (24 ids from `P/app.js:2` — note 23 seed + all SVG names) `File(garmentPath(id)).existsSync()` is true.
- [ ] **Step 2: Run** `flutter test test/core/app_assets_test.dart` → FAIL (missing file).
- [ ] **Step 3: Copy assets, download font TTFs** (from `https://github.com/google/fonts/raw/main/ofl/dmsans/` and `.../ofl/manrope/` — variable TTFs are acceptable if static ones are not present; name them per google_fonts' asset convention, e.g. `DMSans-Regular.ttf`, `Manrope-ExtraBold.ttf`), **remove** old files listed above, add deps `go_router`, `flutter_svg`, `intl`, dev deps `flutter_launcher_icons`, `flutter_native_splash`; drop `smooth_page_indicator`. Register asset folders in `pubspec.yaml`.
- [ ] **Step 4: Implement** the four core files above; `main.dart` sets `GoogleFonts.config.allowRuntimeFetching = false` and temporarily runs a `MaterialApp` with `AppTheme.light` and an empty `Scaffold` (Task 3 replaces it).
- [ ] **Step 5: Launcher icon + splash:** `flutter_launcher_icons` config (android adaptive foreground `assets/branding/android-adaptive-foreground.png`, background `#006F54`, legacy `stylobuddy-icon-1024.png`, `ios: true`), `flutter_native_splash` (color `#FFFFFF`, image `stylobuddy-icon-512.png`, android_12 same). Run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.
- [ ] **Step 6: Write `docs/image-prompts.md`** listing the 7 SVG-fallback garments (cream-blouse, blue-jeans, sage-dress, black-skirt, gold-jewelry, sunglasses, green-shirt) — each with a product-photo generation prompt: "studio e-commerce product photo of a <garment>, front view, neutral #EFF0EF background, soft shadow, centered, square 1:1, no model" — and note they need replacing before store release.
- [ ] **Step 7: Run** `flutter test test/core/app_assets_test.dart` → PASS; `flutter analyze` → no issues.
- [ ] **Step 8: Commit** `feat: replace dark theme with prototype design tokens, assets and icon`.

### Task 2: Shared models, seed data and root Cubits

**Files:**
- Create: `lib/shared/models/clothing_item.dart`, `lib/shared/models/outfit.dart`, `lib/shared/models/wear_event.dart`, `lib/shared/models/planned_entry.dart`, `lib/shared/data/seed_data.dart`
- Create: `lib/features/wardrobe/cubit/wardrobe_cubit.dart`, `wardrobe_state.dart`, `lib/features/wardrobe/repository/wardrobe_repository.dart`
- Create: `lib/features/saved/cubit/outfits_cubit.dart`, `outfits_state.dart`
- Create: `lib/features/calendar/cubit/planner_cubit.dart`, `planner_state.dart`
- Create: `lib/features/profile/cubit/profile_cubit.dart`, `profile_state.dart`
- Test: `test/features/wardrobe/wardrobe_cubit_test.dart`, `test/features/saved/outfits_cubit_test.dart`, `test/features/calendar/planner_cubit_test.dart`, `test/features/profile/profile_cubit_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `ClothingItem({required String id, name, category, color, occasion, String season = 'All season', int wears = 0, String? sourceId})` + `copyWith`; getter `imageId => sourceId ?? id`.
  - `Outfit({required int id, required String name, required String occasion, required List<String> items, required String why, int worn = 0})` + `copyWith`.
  - `WearEvent({required int id, required int outfitId, required String name, required String occasion, required List<String> items, required DateTime timestamp})`.
  - `PlannedEntry({required int outfitId, required String occasion})`.
  - `SeedData.items` (23 items from `P/app.js:2-3`, `wears: i % 5`), `SeedData.outfits` (2 from line 4), `SeedData.planned` = `{'2026-10-15': PlannedEntry(outfitId: 1, occasion: 'Everyday')}`, constants `categories` (`P/app.js:81`), `colors` (82), `occasions` (83), `seasons` (`['All season','Spring','Summer','Autumn','Winter']`).
  - `WardrobeRepository.loadItems() -> List<ClothingItem>` (returns seed copy; Firestore slot later).
  - `WardrobeCubit(WardrobeRepository)` state `WardrobeState{List<ClothingItem> items}`; methods `ClothingItem itemOrFallback(String id)` (prototype `get()`: name = id with `-`→space, category `Shirts`, color `Unknown`, occasion `Everyday`), `void addItems(List<ClothingItem>)`, `void updateItem(ClothingItem)`, `void removeItem(String id)`, `void adjustWears(List<String> ids, int delta)` (clamped ≥ 0).
  - `OutfitsCubit(WardrobeCubit)` state `OutfitsState{List<Outfit> outfits, List<WearEvent> wearLog}`; methods `Outfit? byId(int)`, `Outfit saveOrFind(Outfit draft)` (match by identical `items` order like `ensureSavedResult`, else insert at front with new id), `Outfit upsertManual({int? editingId, required String name, required List<String> items, required String occasion})` (prototype `manualSave` why-text), `void delete(int id)`, `void logWear(int outfitId)`, `void removeWear(int eventId)`, `List<WearEvent> wearEvents({int? outfitId})` newest first. Ids from `DateTime.now().millisecondsSinceEpoch` via an injectable `int Function() clock`.
  - `PlannerCubit` state `PlannerState{Map<String, PlannedEntry> planned, int year = 2026, int month = 10 /*1-based*/, int day = 15}`; methods `static String keyFor(int y, int m, int d)` → `yyyy-MM-dd`, `String get selectedKey`, `void select(int day)`, `void navigate(int offset)` (clamp day to month length), `void plan(String key, PlannedEntry)`, `void remove(String key)`, `String label(String key)` → `October 15, 2026` (intl `MMMM d, y`).
  - `ProfileCubit` state `ProfileState{String name = '', String email = '', List<String> styles, List<String> occasions, bool dailyNotifications, bool plannedNotifications, bool productNotifications, bool weatherConsent, String climate, String plan = 'Free'}` — read `P/app.js:268-287` for the field defaults and the prototype field names they map to (`S.profileName`, `S.profileStyle`, etc.); methods `updateDetails(name, email)`, `togglePreference(field, value)`, setters for toggles/climate, `setPlan(String)`.

- [ ] **Step 1: Write failing tests:** wardrobe — seed has 23 items, `items[0].id == 'white-shirt'`, `items[1].wears == 1`; `itemOrFallback('mystery-coat').name == 'mystery coat'`; `adjustWears(['white-shirt'], -5)` leaves `wears == 0`. outfits — seed has 2; `logWear(1)` adds event, sets outfit `worn == 1`, increments `white-shirt` wears by 1; `removeWear` reverses both; `saveOrFind` with seed outfit 1's items returns id 1 and doesn't grow list; `upsertManual(editingId: null, …)` inserts at index 0 with why `'A look you put together from your own wardrobe.'`. planner — `selectedKey == '2026-10-15'`; `navigate(1)` from Oct 31 gives Nov 30; `label('2026-10-15') == 'October 15, 2026'`. profile — `togglePreference` adds then removes.
- [ ] **Step 2: Run** `flutter test test/features` → FAIL.
- [ ] **Step 3: Implement** the files above.
- [ ] **Step 4: Run** `flutter test` → PASS, `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat: add shared wardrobe/outfit/planner/profile state seeded from prototype`.

### Task 3: Shared widgets, router, app shell, route placeholders

**Files:**
- Create in `lib/shared/widgets/`: `screen_head.dart`, `app_buttons.dart`, `garment_image.dart`, `look_board.dart`, `item_tile_grid.dart`, `option_tile.dart`, `select_field.dart`, `section_title.dart`, `app_toast.dart`, `app_modal.dart`, `loading_view.dart`, `progress_bar.dart`, `demo_note.dart`, `brand_mark.dart`, `chip_button.dart`, `generic_preview_view.dart`
- Create: `lib/core/router/app_routes.dart`, `lib/core/router/app_router.dart`, `lib/core/router/app_shell.dart`, `lib/app.dart`
- Create placeholder route files (each returns `GoRoute`s whose builder is `GenericPreviewView`): `lib/features/{onboarding,auth,home,wardrobe,stylist,matching,builder,saved,calendar,packing,shopping,insights,profile}/<feature>_routes.dart` exposing `List<RouteBase> <feature>Routes`
- Modify: `lib/main.dart`
- Test: `test/shared/widgets_test.dart`, `test/core/router_test.dart`

**Interfaces:**
- Consumes: Task 1 tokens/assets, Task 2 Cubits.
- Produces:
  - `abstract final class AppRoutes` — one `static const String` per prototype route, value `'/<route-name>'` (e.g. `matchSelect = '/match-select'`, `welcome = '/welcome'`). Helpers: `clothing(String id) => '/clothing?id=$id'`, `savedDetail(int id) => '/saved-detail?id=$id'`, `wearDetail(int id) => '/wear-detail?id=$id'`. `static const noNavRoutes = {welcome, intro, personalize, auth, login, signup, forgot, resetSent, verifyEmail}`. `static String tabFor(String location)` implementing prototype `render()` grouping (`P/app.js:38`).
  - `appRouter` (`GoRouter`, `initialLocation: AppRoutes.welcome`): top-level routes for `noNavRoutes`, a `ShellRoute` with `AppShell` for the rest; unknown → `GenericPreviewView`.
  - `AppShell({required Widget child})` — white scaffold, `SafeArea`, bottom nav per `.bottom-nav` (`P/styles.css:2`: min-height 64, top border `#ECF0EC`, 9px labels, glyph 20px, current = `AppColors.green` bold) with tabs `⌂ Home`, `▦ Wardrobe`, `✧ AI Stylist`, `♡ Saved`, `♙ Profile`; tap → `context.go`. Android back on a tab root that isn't `/home` goes to `/home`; on `/home` it exits.
  - `ScreenHead({required String title, required String fallbackRoute, Widget? action})` — `.screen-head` (31×31 `#F5F7F5` radius 9 `‹` button, centered 13px bold title, 31px trailing slot, bottom margin 19); back = `context.canPop() ? pop() : go(fallbackRoute)`.
  - `PrimaryButton({required String label, required VoidCallback? onPressed, bool fullWidth = true})`, `SecondaryButton(...)`, `DangerButton(...)` — `.primary`/`.secondary`/`.danger` final rules.
  - `GarmentImage({required String id, BoxFit fit = BoxFit.contain})` — `AppAssets.garmentPath`, svg via `SvgPicture.asset`; error → svg fallback.
  - `enum LookBoardSize { normal, large, third }`; `LookBoard({required List<String> ids, LookBoardSize size = LookBoardSize.normal})` — `.look-board` rules.
  - `ItemTileGrid({required List<String> ids, required Set<String> selected, Set<String> locked = const {}, required ValueChanged<String> onTap, bool showLock = false})` — prototype `tiles()` (`P/app.js:35`), names via `WardrobeCubit.itemOrFallback`.
  - `OptionTile({required String label, required bool selected, required VoidCallback onTap, String? description})` — `.option`.
  - `SelectField({required String label, required List<String> options, required String value, required ValueChanged<String> onChanged})` — `.field` + select look (dropdown).
  - `SectionTitle({required String title, String? linkLabel, VoidCallback? onLink})` — `.section-title`, link renders `'$linkLabel →'`.
  - `AppToast.show(BuildContext, String)` — `.toast` (bg `#172A20`, white 12px, radius 12, padding 12×18, bottom 25, 2200 ms).
  - `AppModal.show(BuildContext, {required String title, required Widget body})` + `AppModal.close(BuildContext)` — `.modal` (backdrop `#10271C78`, white radius 20, padding 22, max width 430, ✕ close).
  - `LoadingView({required String title, required String message})` — `.loading` + `.spinner`.
  - `AppProgressBar({required double value})` — `.progress`.
  - `DemoNote(String text, {DemoNoteStyle style})` + `const bool kShowDemoNotes = true;` — renders nothing when false.
  - `BrandMark({double iconSize = 38, double fontSize = 24})` — hanger SVG (`P/app.js:295`) + "StyloBuddy".
  - `ChipButton({required String label, required bool selected, required VoidCallback onTap})` — `.chip`.
  - `GenericPreviewView()` — `pages.generic` (`P/app.js:345`).
  - `StyloBuddyApp` in `lib/app.dart`: `MultiBlocProvider` (WardrobeCubit, OutfitsCubit, PlannerCubit, ProfileCubit) + `MaterialApp.router(theme: AppTheme.light, routerConfig: appRouter, debugShowCheckedModeBanner: false)`.

- [ ] **Step 1: Write failing tests:** router — `AppRoutes.tabFor('/match-select') == AppRoutes.stylist`, `tabFor('/edit-item') == AppRoutes.wardrobe`, `tabFor('/wear-detail') == AppRoutes.saved`, `tabFor('/premium') == AppRoutes.profile`, `tabFor('/calendar') == AppRoutes.home`; pumping the app at `/home` shows 5 nav labels; at `/welcome` shows none. widgets — `ScreenHead` with no history tapping back navigates to fallback; `AppToast.show` displays then disappears after 2200 ms; `LookBoard(ids: ['white-shirt','navy-chinos'])` renders 2 `GarmentImage`.
- [ ] **Step 2: Run** `flutter test test/shared test/core` → FAIL.
- [ ] **Step 3: Implement** widgets, router, shell, placeholder route files, `app.dart`, `main.dart` (`runApp(const StyloBuddyApp())`). Delete `test/widget_test.dart`, replace with `test/app_smoke_test.dart` (app boots to welcome placeholder).
- [ ] **Step 4: Run** `flutter test` → PASS, `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat: add shared prototype widgets, router and app shell`.

---

**Feature tasks 4–13 run in parallel after Task 3** (Task 7 after Task 6). Each one:
1. Reads its `P/app.js` and `P/styles.css` line ranges in full.
2. Replaces its placeholder `<feature>_routes.dart` with real screens, using paths from `AppRoutes`.
3. Builds `view/` screens composed of named widgets in `widgets/`, a feature Cubit where the feature has local state, `<feature>_tokens.dart` for feature-only CSS values.
4. TDD: Cubit logic tests first; then one widget test per screen asserting its headline copy and primary action navigation.
5. Verification: `flutter test test/features/<feature>` PASS and `flutter analyze lib/features/<feature>` clean.
6. Reports files changed; does **not** commit.

### Task 4: Onboarding + Auth (welcome, intro ×5, personalize, auth, login, signup, forgot, reset-sent, verify-email)

**Source:** `P/app.js:288-323`; `P/styles.css:12-289` (V3–V5.1 onboarding/auth sections, last rule wins).
**Files:** `lib/features/onboarding/**`, `lib/features/auth/**`, tests under `test/features/onboarding`, `test/features/auth`.
**Interfaces:** Consumes `BrandMark`, `ScreenHead`, `OptionTile`, `ChipButton`, `PrimaryButton`, `AppToast`, `DemoNote`, `ProfileCubit.updateDetails`. Produces `OnboardingCubit{int slide; Set<String> chosenOccasions; void next(); void back(); void toggleOccasion(String)}`, `AuthCubit{String email; String? error; AuthResult submitLogin/submitSignup/submitForgot(...)}`.
- [ ] **Step 1: Failing tests:** `OnboardingCubit.next()` from slide 4 emits `finished`; signup with password `'short'` → error `'Use at least 8 characters for your password.'`; mismatched confirm → `'Passwords do not match. Please try again.'`; login success navigates to `/home` and toasts `'Signed in to demo account'`; slide 1 button reads `Get Started`, slide 5 `Create My Wardrobe`, others `Continue`; Skip goes to `/personalize`.
- [ ] **Step 2: Run → FAIL. Step 3: Implement** (5 slides as one `/intro` route driven by `OnboardingCubit.slide`; occasions slide 4 list with glyphs from line 307; email validation equivalent to HTML `required`/`type=email`/`minlength`). **Step 4: Run → PASS + analyze clean.**

### Task 5: Home dashboard

**Source:** `P/app.js:40-62`; `P/styles.css:290-293` (HOME V7).
**Files:** `lib/features/home/**`, `test/features/home/**`.
**Interfaces:** Consumes `WardrobeCubit` (first 4 items for "Recently added"), `ProfileCubit.name` (greeting `Hi, there` when empty), `AppRoutes`. "View outfits" calls `StylistCubit.generateAutomatic(occasion: 'Everyday')` from Task 6 — until Task 6 lands, navigate to `AppRoutes.occasion`; controller wires the call at merge (note it in the report).
- [ ] **Step 1: Failing widget tests:** shows `Good morning`, `Hi, there`, `QUICK ACTIONS`, 4 shortcuts (`AI Outfits`, `Match Items`, `Add Item`, `Calendar`) routing to occasion/matching/import/calendar; `Recently added` shows 4 tiles and tapping first opens `/clothing?id=white-shirt`; 4 explore rows route to packing/insights/shopping/saved.
- [ ] **Step 2–4:** FAIL → implement (inline SVG icons from lines 43-49 via `SvgPicture.string`) → PASS + analyze.

### Task 6: AI Stylist core (stylist, occasion, styling-options, generating, results, result-detail) + shared results engine

**Source:** `P/app.js:102-148`; `P/styles.css:299-346` (V10, V12).
**Files:** `lib/features/stylist/**`, `test/features/stylist/**`.
**Interfaces:** Consumes `WardrobeCubit`, `OutfitsCubit.saveOrFind`, `PlannerCubit.plan/keyFor`, `LookBoard`, `AppModal`, `AppToast`. Produces (used by Tasks 5, 7):
  - `StylistCubit` provided at the **app root** (controller adds it to `app.dart` at merge): state `StylistState{String occasion = 'Everyday'; List<StyleResult> results; int activeIndex; List<String> selected; List<String> locked; bool accessories = true; String category = 'All'; bool isMatchMode}`.
  - `StyleResult{int id; String name; List<String> items; String occasion; String why}`.
  - Methods: `setOccasion`, `Future<void> generateAutomatic()`, `Future<void> generateMatches()`, `List<List<String>> createMatches()` (port of `P/app.js:112-136` exactly), `toggleSelect(id)`, `toggleLock(id)`, `setCategory`, `setAccessories(bool)`, `startMatching()` (clears selected/locked, category All), `selectAndLock(String id)` (clothing-detail entry), `swapItem(String oldId, String newId)` (rejects locked in match mode with toast text `'Mandatory items cannot be swapped'`), `String shareSummary()`.
  - Generation emits `isGenerating` true → after 1150 ms results set; screens listen and route `generating`→`results`, `matching-progress`→`matching-results`.
  - Result screens are shared: `ResultsView(match: bool)` and `ResultDetailView(match: bool)` exported for Task 7's routes.
- [ ] **Step 1: Failing tests:** automatic yields names `Refined Everyday`, `Modern Classic`, `Effortless Edge` and filters out ids not in wardrobe; `createMatches` with selected `[white-shirt, navy-chinos, blue-jeans]`, locked `[white-shirt]`, accessories on → ≤3 unique looks, every look contains `white-shirt`, each look has one shoe and one accessory not in selected; with only locked `[black-skirt]` selected → exactly one look `['black-skirt', <shoe>, <accessory>]`; with nothing selected → `[]` and results view shows `No valid combinations yet`; plan modal tapping day 20 calls `PlannerCubit.plan('2026-10-20', …)` and lands on `/calendar` with toast `Outfit scheduled for October 20`; swap shows `No alternative in your wardrobe for this category` when none.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 7: Match My Clothes (matching, match-select, match-review, match-options, matching-progress, matching-results, matching-detail)

**Depends on Task 6.** **Source:** `P/app.js:149-157`; `P/styles.css:341-343` (V11).
**Files:** `lib/features/matching/**`, `test/features/matching/**`.
**Interfaces:** Consumes `StylistCubit` (selection/lock/generateMatches), `ResultsView(match: true)`, `ResultDetailView(match: true)`, `ItemTileGrid(showLock: true)`.
- [ ] **Step 1: Failing tests:** `Choose from my wardrobe →` resets selection and opens `/match-select`; category chips (`P/app.js:150` list) filter tiles; review screen lock toggles show lock badge; continue disabled/blocked with prototype message when nothing selected (read line 152-156 for exact copy); progress → results after 1150 ms.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 8: Wardrobe (wardrobe, clothing, edit-item, filter, import, import-source, batch, analyzing, review, add-confirm)

**Source:** `P/app.js:63-101`; `P/styles.css:294-298` (V8, V9).
**Files:** `lib/features/wardrobe/**` (Cubit from Task 2 stays; add `ImportCubit` + `WardrobeBrowseCubit{filter, search}`), tests.
**Interfaces:** Consumes `WardrobeCubit`, `StylistCubit.selectAndLock` (Find matching outfits → `/match-review`). Import pool `['cream-blouse','denim-jacket','tan-belt','black-heels','floral-dress','cream-cardigan']`, counts 1/3/6.
- [ ] **Step 1: Failing tests:** stats show `23 Pieces`, `7 Categories`, worn count; search "jean" shows Black Jeans + Blue Jeans and count `2`; empty search shows `Nothing here yet` + `Clear search`; edit with empty name toasts `Enter an item name`; remove via dialog toasts `Item removed`; import 3 → review 3 items sequentially → `Save to my wardrobe →` on last → add-confirm `+3` and wardrobe count 26; analyzing auto-advances after 1150 ms.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 9: Manual outfit builder (builder, manual-preview)

**Source:** `P/app.js:158-169`; `P/styles.css:347-349` (V13).
**Files:** `lib/features/builder/**`, tests.
**Interfaces:** Consumes `OutfitsCubit.upsertManual`, `ItemTileGrid`. Produces `BuilderCubit{List<String> picked; String category; int? editingId; String name; String occasion; void start({int? editId})}` — `start` is called by Saved (Task 10) edit action, provided at the app root (controller wires).
- [ ] **Step 1: Failing tests:** saving with blank name toasts `Give your outfit a name`; with no items toasts `Choose at least one item`; valid save lands on saved-detail with toast `Outfit saved`; editing existing outfit keeps its id.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 10: Saved looks & wear history (saved, saved-detail, wear-detail)

**Source:** `P/app.js:170-184`; `P/styles.css:350-427` (V14).
**Files:** `lib/features/saved/**` (OutfitsCubit from Task 2 stays; add `SavedViewCubit{tab, search}`), tests.
**Interfaces:** Consumes `OutfitsCubit`, `PlannerCubit` (schedule-from-outfit → `/calendar-date`), `BuilderCubit.start(editId)`.
- [ ] **Step 1: Failing tests:** tabs `Saved`/wear history switch; search filters by name/occasion; Mark as Worn toasts `Outfit wear recorded` and adds history entry; delete confirm toasts `Look removed` (check line 183 copy); share modal text equals prototype format.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 11: Calendar planner (calendar, calendar-choose, calendar-date)

**Source:** `P/app.js:185-198`; `P/styles.css:428-430` (V15).
**Files:** `lib/features/calendar/**` (PlannerCubit from Task 2 stays), tests.
- [ ] **Step 1: Failing tests:** opens on October 2026 with 15 selected and Everyday Essential planned; month nav; save toasts `Outfit planned for October 15, 2026`; remove dialog `Keep plan`/`Remove plan` toasts `Plan removed`.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 12: Packing assistant (packing, new-trip, packing-preview, packing-list, packing-add)

**Source:** `P/app.js:199-219`; `P/styles.css:431-432` (V16).
**Files:** `lib/features/packing/**` (`PackingCubit` with `Trip`/`PackingItem` models local to the feature), tests.
- [ ] **Step 1: Failing tests:** empty state on first open; save trip with blank name is rejected with the prototype's message (line 205); `pkSuggested` port returns the same items for a Vacation trip as the JS; toggle packed updates progress; custom item blank rejected; delete trip confirm.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

### Task 13: Shopping, Insights, Profile/Settings/Premium

Three independent sub-features in one task because each is small and read-mostly; split across three subagents if running in parallel.

**Source:** shopping `P/app.js:220-267`, `P/styles.css:433-436`; insights `P/app.js:325-344`, `P/styles.css:437-439`; profile `P/app.js:268-287`, `P/styles.css:440-442`.
**Files:** `lib/features/shopping/**`, `lib/features/insights/**`, `lib/features/profile/**`, tests.
**Interfaces:** Consumes `WardrobeCubit`, `OutfitsCubit`, `ProfileCubit`. Produces `ShoppingCubit{tab, wishlist, selectedId}`; insights stats as a pure function `InsightStats.from(List<ClothingItem>)` (port of `insightStats`, line 326).
- [ ] **Step 1: Failing tests:** wishlist toggle; `InsightStats.from(seed)` matches JS values (compute them by running the JS function under node: `node -e` with the seed — record the numbers in the test); empty wardrobe shows `Insights start with your wardrobe`; edit profile with blank name rejected (line 274 copy); toggles persist in `ProfileCubit`; premium → plan → purchase flow; sign out confirm behaves per `P/app.js:283`; whitespace-only trip/name inputs rejected.
- [ ] **Step 2–4:** FAIL → implement → PASS + analyze.

---

### Task 14: Integration, visual parity check, docs

**Files:** `lib/app.dart` (provide `StylistCubit`, `BuilderCubit` at root), `lib/features/home/**` (wire View outfits), `docs/tracker.md`, `docs/project-handoff.md`, `scripts/parity/` (Playwright scripts).

- [ ] **Step 1:** Wire root providers and the cross-feature calls noted by Tasks 5, 6, 9, 10. Run `flutter test` → all PASS; `flutter analyze` → no issues.
- [ ] **Step 2: Parity screenshots.** Serve `P` (`python -m http.server 8801`) and `flutter build web` output (`python -m http.server 8802` from `build/web`). Playwright (Node) at viewport 390×844: for each route, drive the prototype to the route by calling `go('<route>')` in page JS and the Flutter app via `/#/<route>` (set `usePathUrlStrategy` off / hash URLs for web). Save pairs to `scripts/parity/out/<route>-{proto,app}.png`.
- [ ] **Step 3: Compare each pair visually**; fix differences in the owning feature (layout, spacing, copy, color, images). Repeat until each pair matches. Record any web-only rendering differences to flag for on-device check.
- [ ] **Step 4: Android build:** `flutter build apk --debug` → succeeds.
- [ ] **Step 5: Docs:** create `docs/tracker.md` (per `project-hygiene.md`; Design/Onboarding/Core features done, Integration — Firebase/Supabase/RevenueCat PENDING, Security PENDING); rewrite `docs/project-handoff.md` to the new state.
- [ ] **Step 6: Commit** `feat: wire cross-feature flows, parity-verify against prototype, update docs`.
