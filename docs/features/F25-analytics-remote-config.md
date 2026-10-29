# F25 — Firebase Analytics + Remote Config (feature flags, forced update)

> Wires the last two Firebase services of the fixed stack that the app does not use yet.
> **Analytics:** one typed, privacy-bounded `AnalyticsService` (no-op by default, so no test
> needs Firebase), automatic `screen_view` logging for every go_router location, and a small
> deliberate funnel event set (onboarding, sign-in, outfit generated, items added, outfit saved,
> paywall viewed). **Remote Config:** a typed `AppConfig` read through a `RemoteConfigService`
> abstraction with in-app defaults and a startup fetch that never blocks first paint.
> **Forced update:** a blocking `UpdateRequiredView` when the installed version is below
> `min_supported_version`, plus a dismissible soft-update nudge and a maintenance notice. Ships a
> ready-to-publish Remote Config template and a publish runbook; publishes nothing itself.
> Depends on F02 (onboarding + auth cubits and routes), F03/F04 (`StylistCubit`), F06/F15
> (`ImportCubit`), F07/F16 (`OutfitsCubit`), F13 (`/premium`), F14 (`lib/app.dart` uid-keyed
> subtree and the "tests run with no Firebase app" rule), F24 (gender is never logged).
> Foundation: 01, 02, 03 (amendment, §13 P1), 05, 06, 07.

**Status:** DONE (gates 1-3; gate 4 — A44-A46 `[L]` — pending) · **Milestone:** 3 · **Depends on:** F02, F03, F06, F07, F13, F14, F15, F16, F24

---

## 1. Goal

Before a first public Android launch the owner needs three things the app cannot do today: see
where users drop out of the core funnel, switch unfinished features on or off without a store
release, and force users off a broken build. This feature adds all three on the fixed stack
(Firebase Analytics, Firebase Remote Config) without changing any existing screen's behaviour
under default values, without logging any personal data, and without making any existing test
depend on Firebase.

## 2. MVP scope

### 2.1 Analytics

- **`lib/shared/backend/analytics_service.dart`** (pure Dart + Flutter, no Firebase import):
  - `abstract interface class AnalyticsSink { Future<void> logEvent(String name, Map<String, Object> parameters); Future<void> logScreenView(String screenName); }`
  - `class NoopAnalyticsSink implements AnalyticsSink` (const constructor; both methods complete
    immediately and do nothing).
  - `class AnalyticsService` — the **only** API feature code calls. Constructor
    `const AnalyticsService(AnalyticsSink sink)`; `const AnalyticsService.noop()` uses
    `NoopAnalyticsSink`. Every method is `void` (fire-and-forget), never throws, and swallows
    both a synchronous throw and an asynchronous error from the sink (debug-only
    `debugPrint`). Typed methods (no free-form `logEvent` is exposed):

    | Method | Event name | Parameters (exact keys; values) |
    |---|---|---|
    | `screenView(String location)` | `logScreenView(screenName)` | screen name = `screenNameFor(location)` |
    | `onboardingStarted()` | `onboarding_start` | none (`{}`) |
    | `onboardingCompleted({required int occasionCount})` | `onboarding_complete` | `occasion_count`: int |
    | `onboardingSkipped(OnboardingSkipPoint from, {int? slide})` | `onboarding_skip` | `skip_from`: `'welcome'` \| `'intro'`; `slide`: int 1-5, present only for `intro` |
    | `signedIn(SignInMethod method)` | `login` | `method`: `'google'` |
    | `guestStarted()` | `guest_start` | none |
    | `outfitGenerated({required OutfitGenerationMode mode, required int resultCount})` | `outfit_generated` | `mode`: `'automatic'` \| `'match'`; `result_count`: int |
    | `wardrobeItemsAdded({required String source, required int itemCount, required int photoCount})` | `wardrobe_items_added` | `source`: `'camera'` \| `'gallery'` \| `'other'` (any other input string maps to `'other'`); `item_count`: int; `photo_count`: int |
    | `outfitSaved({required OutfitSaveSource source, required int itemCount})` | `outfit_saved` | `source`: `'generated'` \| `'builder'`; `item_count`: int |
    | `paywallViewed()` | `paywall_view` | none |

  - Enums in the same file: `OnboardingSkipPoint { welcome, intro }`,
    `SignInMethod { google }`, `OutfitGenerationMode { automatic, match }`,
    `OutfitSaveSource { generated, builder }`; each wire value is the enum's `name`.
  - `abstract final class AnalyticsEvents` holds the nine event-name constants above;
    `AnalyticsEvents.all` is the set of all nine. `abstract final class AnalyticsParams` holds
    the nine parameter-key constants; `AnalyticsParams.all` is that set.
  - `String screenNameFor(String location)` (top-level): strips any query/fragment; a path
    matching `^/[a-z0-9-]+$` becomes the path without the leading `/` and with every `-`
    replaced by `_` (`/saved-detail?id=3` -> `saved_detail`); anything else -> `'unknown'`.
    Query parameters (ids) are therefore never logged.
  - `AnalyticsService analyticsOf(BuildContext context)` (top-level): the
    `AnalyticsService` provided above `context`, or `const AnalyticsService.noop()` when none
    is provided.
- **`lib/shared/backend/firebase_analytics_sink.dart`**: `FirebaseAnalyticsSink(FirebaseAnalytics analytics)`
  implementing `AnalyticsSink` by `analytics.logEvent(name:, parameters:)` (an empty map is
  passed as `null`) and `analytics.logScreenView(screenName:)`. Imported only by `lib/main.dart`.
- **`lib/shared/backend/screen_view_tracker.dart`**: `ScreenViewTracker(GoRouter router, AnalyticsService analytics)`
  with `attach()` / `detach()`. Listens to `router.routerDelegate`; on each notification reads
  `routerDelegate.currentConfiguration`: an error match (unknown route) -> location
  `'/not-found'`; an empty match list -> nothing; otherwise `last.matchedLocation`. It calls
  `analytics.screenView(location)` only when the resulting screen name differs from the last
  one logged (consecutive duplicates collapse; `a -> b -> a` logs three times). When the screen
  name is `premium` it additionally calls `analytics.paywallViewed()` (the paywall is `/premium`,
  F13; `/plan` and `/purchase` are covered by their `screen_view`s). This is the "NavigatorObserver
  or equivalent": a `NavigatorObserver` on `GoRouter.observers` would not see routes inside
  `ShellRoute` navigators; the delegate listener sees `go`, `push` and `pop` uniformly.
- **Where events fire** (every call goes through the cubit; no view touches the sink):

  | Event | Fired by | Exactly when |
  |---|---|---|
  | `onboarding_start` | `OnboardingCubit.start()` | every call (Welcome "Get Started") |
  | `onboarding_complete` | `OnboardingCubit.next()` | the call on `lastSlide` that emits `OnboardingExit.finished`; `occasion_count` = `state.chosenOccasions.length` |
  | `onboarding_skip` | new `OnboardingCubit.skipFromWelcome()` / `skipFromIntro()` | Welcome "Skip introduction" (`welcome`, no `slide`) and intro "Skip" (`intro`, `slide` = `state.slide + 1`). Neither changes state. The views call them, then navigate exactly as today. *(2026-10-29: two no-arg methods instead of one `skip(OnboardingSkipPoint)`, so no view imports `lib/shared/backend/`, 02 §2.)* |
  | `login` | `AuthCubit.signInWithGoogle()` | only when it returns `AuthResult.success` |
  | `guest_start` | new `AuthCubit.continueAsGuest()` | `/auth` "Skip for now"; changes no state; the view calls it, then `go('/home')` as today |
  | `outfit_generated` | `StylistCubit._generate` | once per generation that emits results (after the 1150 ms wait, not when skipped because already generating or closed); `result_count` = results length |
  | `wardrobe_items_added` | `ImportCubit.confirmCurrent` | once per finished batch, right after `WardrobeCubit.addItems`; `source` = `state.source`; `item_count` = finalized length; `photo_count` = number of finalized items whose `imageUrl` is non-null |
  | `outfit_saved` | `OutfitsCubit.saveOrFind` (`generated`) / `upsertManual` (`builder`) | only when a **new** outfit is created: not when `saveOrFind` returns an existing outfit, not for an edit of an existing id |
  | `paywall_view` | `ScreenViewTracker` | location becomes `/premium` |

- **Injection.** `OnboardingCubit`, `AuthCubit`, `StylistCubit`, `ImportCubit` and `OutfitsCubit`
  each gain an optional named `AnalyticsService? analytics` constructor parameter defaulting to
  `const AnalyticsService.noop()`, so every existing constructor call compiles and stays silent.
  `lib/app.dart` passes the app's service to the three root cubits; `onboarding_routes.dart`
  and `auth_routes.dart` pass `analyticsOf(context)`.
- **`StyloBuddyApp`** gains `final AnalyticsService? analytics` (default
  `const AnalyticsService.noop()`), provided once via
  `RepositoryProvider<AnalyticsService>.value` **above** the uid-keyed `StreamBuilder` (it
  survives sign-in/sign-out). `_RoutedMaterialApp` attaches a `ScreenViewTracker` to its router
  (built or injected) in `initState` and detaches it in `dispose`.
- **Android**: `AndroidManifest.xml` gains
  `<meta-data android:name="google_analytics_automatic_screen_reporting_enabled" android:value="false" />`
  inside `<application>` so the SDK does not log a single `MainActivity` screen alongside ours.
- **Privacy rules (binding).** No event or parameter carries: gender (F24 §3), name, email,
  uid, free text (outfit names, trip names, notes, search), wardrobe item names/ids/categories,
  occasions, or query parameters. Values are only the enum wire strings above and integers.
  `setUserId`, `setUserProperty` and `setDefaultEventParameters` are never called: analytics
  stays keyed on Firebase's own app-instance id only.

### 2.2 Remote Config

- **`lib/shared/models/app_config.dart`** (pure Dart):
  - `abstract final class RemoteConfigKeys` with `minSupportedVersion = 'min_supported_version'`,
    `latestVersion = 'latest_version'`, `aiStylistEnabled = 'ai_stylist_enabled'`,
    `premiumEnabled = 'premium_enabled'`, `maintenanceMessage = 'maintenance_message'`, and
    `all` (exactly those five).
  - `class AppConfig` (immutable, `const` constructor, `copyWith`, value `==`/`hashCode`):
    `String minSupportedVersion`, `String latestVersion`, `bool aiStylistEnabled`,
    `bool premiumEnabled`, `String maintenanceMessage`.
    `static const AppConfig defaults = AppConfig(minSupportedVersion: '', latestVersion: '', aiStylistEnabled: false, premiumEnabled: false, maintenanceMessage: '')`.
    `Map<String, Object> toDefaultsMap()` returns the five keys -> values (for
    `setDefaults`).
- **`lib/shared/backend/remote_config_service.dart`** (no Firebase import):
  - `abstract interface class RemoteConfigService { Future<AppConfig> initialize(); Future<AppConfig?> refresh(); }`.
    `initialize()` applies settings and in-app defaults and returns the currently **activated**
    values (in-app defaults on a first install, the last fetched values afterwards); it never
    throws (on any error it returns `AppConfig.defaults`). `refresh()` fetches and activates
    and returns the new activated values, or `null` on failure; it never throws.
  - `class DefaultsRemoteConfigService implements RemoteConfigService` (const): `initialize()`
    returns `AppConfig.defaults`, `refresh()` returns `null`. Used by tests and as
    `StyloBuddyApp`'s default.
- **`lib/shared/backend/firebase_remote_config_service.dart`**:
  `FirebaseRemoteConfigService(FirebaseRemoteConfig remoteConfig, {bool debug = kDebugMode})`.
  - `static const fetchTimeout = Duration(seconds: 10)`,
    `static const debugMinimumFetchInterval = Duration(minutes: 5)`,
    `static const releaseMinimumFetchInterval = Duration(hours: 1)`.
  - `initialize()`: `setConfigSettings(RemoteConfigSettings(fetchTimeout: fetchTimeout, minimumFetchInterval: debug ? debugMinimumFetchInterval : releaseMinimumFetchInterval))`,
    then `setDefaults(AppConfig.defaults.toDefaultsMap())`, then returns the typed read.
  - `refresh()`: `fetchAndActivate()` then the typed read; any throw -> `null`.
  - Typed read: `getString` for the three strings, `getBool` for the two flags.
  - Imported only by `lib/main.dart`.
- **Startup (never blocks first paint).** `runApp` is not delayed by Remote Config. A new
  `AppConfigCubit` (below) is created in `_StyloBuddyAppState.initState` and its `load()` runs
  in the background: `initialize()` -> emit the activated values -> `refresh()` bounded by
  `AppConfigCubit.fetchTimeout = Duration(seconds: 8)` -> on success emit the fetched values; on
  `null`, timeout or error keep the values already emitted. Until `load()` finishes the state is
  `AppConfig.defaults` with no forced update, so the first frame is always the normal app.
  Because `initialize()` returns the last **activated** values, a `min_supported_version`
  fetched in an earlier session takes effect on the next cold start before any network call.

### 2.3 Forced update, soft nudge, maintenance notice

- **New feature folder `lib/features/app_config/`:**
  - `models/app_version.dart`: `class AppVersion implements Comparable<AppVersion>` with
    `static AppVersion? tryParse(String raw)`: trims; drops anything from the first `+` (build
    number) and then from the first `-` (pre-release); splits on `.`; requires 1-4 segments,
    each `^\d+$`; otherwise `null` (so `''`, `'abc'`, `'1..2'`, `'v1.2'`, `'1.2.3.4.5'` are
    `null`). Missing trailing segments are zero (`1.2` == `1.2.0`). Segments compare as integers
    (`1.2.10` > `1.2.9`, `01.2` == `1.2`).
  - `cubit/app_config_state.dart`: `AppConfigState { AppConfig config = AppConfig.defaults; String? installedVersion; bool loaded = false; bool updateNudgeDismissed = false; bool maintenanceDismissed = false; bool storeLaunchFailed = false; }`
    with `copyWith` and getters:
    - `bool get updateRequired`: `installedVersion` and `config.minSupportedVersion` both parse
      and installed < min. Any unparseable/empty side -> `false` (fail-open, §10).
    - `bool get updateAvailable`: `!updateRequired`, both parse, installed < `config.latestVersion`.
    - `String? get maintenanceMessage`: `config.maintenanceMessage.trim()`, or `null` when that is
      empty.
    - `bool get showUpdateNudge` = `updateAvailable && !updateNudgeDismissed`;
      `bool get showMaintenance` = `maintenanceMessage != null && !maintenanceDismissed`.
  - `cubit/app_config_cubit.dart`:
    `AppConfigCubit({required RemoteConfigService remoteConfig, Future<String?> Function()? installedVersion, Future<bool> Function()? openStore, Duration fetchTimeout = AppConfigCubit.fetchTimeout})`;
    `Future<void> load()` (idempotent: a second call while one is running or after it finished
    returns without fetching again), `Future<void> openStore()` (sets `storeLaunchFailed` to
    `!launched`; a throw counts as `false`), `void dismissUpdateNudge()`,
    `void dismissMaintenance()`. The installed version is read inside `load()`; a throw or
    `null` leaves `installedVersion == null`.
  - `view/update_required_view.dart` `UpdateRequiredView` (`Key('update-required-view')`),
    UI only, reads `AppConfigCubit`:

    | Element | Text |
    |---|---|
    | Brand | `BrandMark` |
    | Title | `Update required` |
    | Body | `This version of StyloBuddy is no longer supported. Update to the latest version to keep using the app.` |
    | Button (`PrimaryButton`) | `Update now` -> `AppConfigCubit.openStore()` |
    | Error line (only when `storeLaunchFailed`) | `Couldn't open Google Play. Please update StyloBuddy from the Play Store.` |

    There is no close, back, skip or "later" control.
  - `widgets/app_config_gate.dart` `AppConfigGate({required Widget child})`, used as
    `MaterialApp.router(builder: (context, child) => AppConfigGate(child: child!))`:
    - `updateRequired` -> `Stack` of `Offstage(offstage: true, child: child)` (router state kept
      but not painted, hit-tested or exposed to semantics) and `UpdateRequiredView`.
    - else if `showMaintenance` or `showUpdateNudge` -> `Column` of the visible banners (maintenance
      first) then `Expanded` child with the top padding removed (the banner owns the status bar
      inset), wrapped in `Semantics(container: true)` so the routes' modal-barrier
      `BlockSemantics` cannot drop the banners from the accessibility tree (found during build,
      2026-10-29).
    - else -> `child` itself, unchanged (byte-identical tree for every existing test).
  - `widgets/app_notice_banner.dart` `AppNoticeBanner` (UI only): message text, optional action
    label/callback, a `✕` dismiss control with a semantics label.
    - Maintenance: `Key('maintenance-banner')`, message = the trimmed `maintenance_message`, no
      action, dismiss semantics `Dismiss notice` -> `dismissMaintenance()`.
    - Nudge: `Key('update-nudge-banner')`, message `A new version of StyloBuddy is available.`,
      action `Update` -> `openStore()`, dismiss semantics `Dismiss update notice` ->
      `dismissUpdateNudge()`.
  - `app_config_tokens.dart` for the banner/view colours and spacing (no inline hex).
- **`lib/shared/backend/app_platform.dart`**: `abstract final class StoreListing { static const androidPackageId = 'com.stylobuddy.stylobuddy'; static final Uri marketUri = Uri.parse('market://details?id=com.stylobuddy.stylobuddy'); static final Uri playStoreWebUri = Uri.parse('https://play.google.com/store/apps/details?id=com.stylobuddy.stylobuddy'); }`;
  `Future<bool> openStoreListing()` — on Android tries `marketUri` then `playStoreWebUri` with
  `LaunchMode.externalApplication`, returns whether one launched, never throws; on any other
  platform returns `false` (iOS needs an App Store id, §3);
  `Future<String?> readInstalledVersion()` — `PackageInfo.fromPlatform().version`, `null` on
  any error. `StyloBuddyApp` gains `remoteConfig` (default `const DefaultsRemoteConfigService()`),
  `installedVersion` (default: a function returning `null`) and `openStore` (default
  `openStoreListing`); `lib/main.dart` passes the Firebase service and `readInstalledVersion`.
- **New dependencies** (01 §5 note): `package_info_plus` ^10.2.2 (installed version) and
  `url_launcher` ^6.3.3 (open the store listing). Neither was a dependency before.
- **Flags without consumers (deliberate).** `ai_stylist_enabled` and `premium_enabled` are
  read, typed and exposed as `AppConfigCubit.state.config.aiStylistEnabled/premiumEnabled`, but
  **nothing in this feature reads them**: the AI provider is not chosen (F23 is a 501 stub and
  no Flutter code calls it) and RevenueCat is not wired. Hiding today's demo screens behind
  them would change F03/F13 behaviour and their assertions; the feature that wires each backend
  consumes its flag (§13 Q1, Q2).

### 2.4 Template and runbook

- `scripts/remoteconfig.template.json`: a Firebase Remote Config REST/CLI template with exactly
  the five parameters, `valueType` `STRING` or `BOOLEAN`, a `description` each, and
  `defaultValue.value` equal to the in-app default (`''`, `''`, `'false'`, `'false'`, `''`),
  no conditions.
- `docs/runbooks/remote-config.md`: how to publish that template (`firebase deploy --only remoteconfig`
  with a `remoteconfig` entry in `firebase.json`, or the REST `PUT` with ETag), how to raise
  `min_supported_version` safely, and how to roll back. **Nothing is published by this
  feature**; `firebase.json` is not changed.

## 3. Later scope

- Consuming `ai_stylist_enabled` (hide/show AI Stylist entry points) — with the LLM-provider
  feature. Consuming `premium_enabled` (hide/show `/premium` and the Profile banner) — with the
  RevenueCat feature.
- Real-time Remote Config (`onConfigUpdated`) and re-fetching on app resume. Today a value
  changes at the next cold start after a successful fetch (and at most every 1 h in release).
- iOS: App Store id for the update button, `FirebaseAutomaticScreenReportingEnabled = NO` in
  `Info.plist`, App Store privacy manifest/nutrition label for Analytics. **Android-only for
  now.**
- An analytics consent toggle in Settings (`setAnalyticsCollectionEnabled`). Not required for
  the first Android launch in the owner's target markets; the Play Data safety form must still
  declare "App activity / App interactions" and "Device or other IDs" (collected, not shared,
  not linked to identity) — the owner's store-listing task, not code.
- `purchase_completed` and other paywall-conversion events — with RevenueCat.
- Logging gender or any profile attribute as a user property (needs its own privacy decision,
  F24 §3).
- A blocking maintenance mode. The maintenance message is a dismissible notice: a typo in a
  blocking flag would take the whole app down.

## 4. Roles and permissions

Uses the guest and authenticated roles from `docs/foundation/07-security.md`. Every role gets
the same analytics, the same config and the same update gate; nothing here depends on `uid`.
Remote Config values are public by design (any client can read them), so no secret is ever
placed in a parameter. Publishing a template needs Firebase project access (the owner's
controller); the app has read-only access to Remote Config. No user can read another user's
analytics; nothing user-identifying is sent (§2.1 privacy rules).

## 5. Main flows

```text
Cold start (release, network OK, nothing published yet):
  main(): Firebase.initializeApp -> Crashlytics wiring (unchanged)
       -> StyloBuddyApp(analytics: AnalyticsService(FirebaseAnalyticsSink(...)),
                         remoteConfig: FirebaseRemoteConfigService(...),
                         installedVersion: readInstalledVersion)
  _StyloBuddyAppState.initState: AppConfigCubit(...)..load()  (not awaited)
  first frame: AppConfigState() -> AppConfigGate returns child unchanged -> /welcome
       ScreenViewTracker: screen_view 'welcome'
  load(): installedVersion '1.0.0'; initialize() -> defaults -> emit;
          refresh() (<= 8 s) -> template values == defaults -> emit; gate unchanged

Forced update:
  owner publishes min_supported_version = '1.1.0'; device on 1.0.0
  launch N (within 1 h of the last fetch): cached activated values (old) -> normal app;
          refresh() is throttled by minimumFetchInterval -> returns the cached values
  launch N+1 after the interval: refresh() fetches '1.1.0' -> emit -> updateRequired
          -> AppConfigGate: Offstage(app) + UpdateRequiredView
  launch N+2: initialize() returns the activated '1.1.0' -> gate shows as soon as load()'s
          first emit lands (before any network)
  "Update now" -> openStore() -> market://details?id=com.stylobuddy.stylobuddy
          -> Play Store opens; if it cannot -> https listing; if neither -> error line shown
  back button / no button -> nothing reveals the app

Soft nudge: latest_version '1.0.3', installed '1.0.1', min '' -> banner
  "A new version of StyloBuddy is available."  [Update] [✕]; ✕ hides it for this process

Maintenance: maintenance_message 'Sync is paused until 14:00 UTC.' -> banner with that text and ✕

Fetch fails / times out / offline: refresh() -> null or 8 s timeout -> state keeps the
  initialize() values; no error is shown; next launch tries again

Funnel (guest): Get Started -> onboarding_start; /gender (screen_view gender, no gender value
  logged); 5 slides -> onboarding_complete{occasion_count}; /personalize; /auth "Skip for now"
  -> guest_start; /home; Home "View outfits" -> outfit_generated{mode:automatic,result_count:3};
  result detail "Save" -> outfit_saved{source:generated,item_count:n}; Profile banner -> /premium
  -> screen_view premium + paywall_view
```

## 6. Interface surface

```text
lib/shared/backend/analytics_service.dart
  abstract interface class AnalyticsSink { Future<void> logEvent(String, Map<String,Object>); Future<void> logScreenView(String) }
  class NoopAnalyticsSink implements AnalyticsSink                          const
  class AnalyticsService { const AnalyticsService(AnalyticsSink); const AnalyticsService.noop();
    void screenView(String location); void onboardingStarted(); void onboardingCompleted({required int occasionCount});
    void onboardingSkipped(OnboardingSkipPoint from, {int? slide}); void signedIn(SignInMethod method); void guestStarted();
    void outfitGenerated({required OutfitGenerationMode mode, required int resultCount});
    void wardrobeItemsAdded({required String source, required int itemCount, required int photoCount});
    void outfitSaved({required OutfitSaveSource source, required int itemCount}); void paywallViewed(); }
  enum OnboardingSkipPoint { welcome, intro }  enum SignInMethod { google }
  enum OutfitGenerationMode { automatic, match }  enum OutfitSaveSource { generated, builder }
  AnalyticsEvents.{onboardingStart..paywallView, all}   AnalyticsParams.{occasionCount..photoCount, all}
  String screenNameFor(String location)       AnalyticsService analyticsOf(BuildContext context)
lib/shared/backend/firebase_analytics_sink.dart   FirebaseAnalyticsSink(FirebaseAnalytics)        main.dart only
lib/shared/backend/screen_view_tracker.dart       ScreenViewTracker(GoRouter, AnalyticsService) attach()/detach()
lib/shared/models/app_config.dart                 RemoteConfigKeys; AppConfig{5 fields, defaults, copyWith, toDefaultsMap()}
lib/shared/backend/remote_config_service.dart     RemoteConfigService{initialize(), refresh()}; DefaultsRemoteConfigService
lib/shared/backend/firebase_remote_config_service.dart  FirebaseRemoteConfigService(FirebaseRemoteConfig, {bool debug})  main.dart only
lib/shared/backend/app_platform.dart              StoreListing; Future<bool> openStoreListing(); Future<String?> readInstalledVersion()
lib/features/app_config/models/app_version.dart   AppVersion.tryParse, compareTo, ==, <
lib/features/app_config/cubit/                    AppConfigCubit{load, openStore, dismissUpdateNudge, dismissMaintenance}; AppConfigState
lib/features/app_config/view/update_required_view.dart     UpdateRequiredView
lib/features/app_config/widgets/app_config_gate.dart       AppConfigGate({required Widget child})
lib/features/app_config/widgets/app_notice_banner.dart     AppNoticeBanner

OnboardingCubit({AnalyticsService? analytics}); void skipFromWelcome(); void skipFromIntro()
AuthCubit({AuthRepository? repository, AnalyticsService? analytics}); void continueAsGuest()
StylistCubit(WardrobeCubit, {int Function()? clock, AnalyticsService? analytics})
ImportCubit(WardrobeCubit, {..., AnalyticsService? analytics})
OutfitsCubit(WardrobeCubit, {OutfitsRepository? repository, int Function()? clock, AnalyticsService? analytics})
StyloBuddyApp({..., AnalyticsService? analytics, RemoteConfigService? remoteConfig,
               Future<String?> Function()? installedVersion, Future<bool> Function()? openStore})
```

Errors: no new method throws. `AnalyticsService.*`, `RemoteConfigService.*`,
`openStoreListing`, `readInstalledVersion` and `AppConfigCubit.*` swallow failures and return
the documented fallback (§10).

## 7. Domain model usage

- **New shared model `AppConfig`** (`lib/shared/models/app_config.dart`), added to
  `docs/foundation/03-domain-model.md` §1 and §4 on 2026-10-29 before implementation (§13 P1,
  03 §5). It is read-only client config, not user data, and never written to Firestore.
- `AppConfigState`, `AppVersion` are feature-local to `app_config` (same status as
  `OnboardingState`).
- Read for analytics counts only: `OnboardingState.chosenOccasions.length`,
  `StylistState.results.length`, `ImportState.source` (mapped to the 3-value enum),
  `ClothingItem.imageUrl` (non-null count only), `Outfit.items.length`. `ProfileState.gender`
  and `OnboardingState.gender` are **not** read by any analytics code path.

## 8. Data changes

- No Firestore, Supabase or `firestore.rules` change.
- New file `scripts/remoteconfig.template.json` (not deployed by this feature).
- `android/app/src/main/AndroidManifest.xml`: one `<meta-data>` (§2.1).
- `pubspec.yaml` / `pubspec.lock`: `package_info_plus`, `url_launcher`.
- No migration: Remote Config has no prior state; Analytics has no prior events.

## 9. Background work and events

- Analytics events: §2.1 table. Delivery, batching, retry and offline queueing are the Firebase
  SDK's own; the app fires and forgets. No event is deduplicated by the app except consecutive
  identical `screen_view`s.
- Remote Config: one `load()` per app process (cold start). `minimumFetchInterval` throttles
  real network fetches to one per 5 min (debug) / 1 h (release); `refresh()` within the
  interval returns cached values without a network call. Activation happens inside
  `fetchAndActivate`; the app never activates mid-session except via that one call.

## 10. Degradation and failure

| Situation | Outcome |
|---|---|
| Analytics sink throws synchronously or its future errors | Swallowed; the cubit action completes normally; debug-only log (A07) |
| No `AnalyticsService` provided above a context (test, isolated widget) | `analyticsOf` returns the no-op service (A08) |
| `initialize()` throws (platform channel down) | `AppConfig.defaults` (A15) |
| `refresh()` fails, returns `null`, or exceeds 8 s | Previously emitted values kept, no error UI, no gate change (A20, A21) |
| Installed version unreadable (`null` / throw) | `installedVersion == null` -> never `updateRequired`, never nudge (A23) |
| `min_supported_version` missing or `''` | No gate (missing and empty both mean "no minimum") (A24) |
| `min_supported_version` unparseable (`'1.x'`, `'latest'`) | No gate (fail-open: a typo must not lock out every user) (A24) |
| `latest_version` `''`/unparseable/<= installed | No nudge (A25) |
| `maintenance_message` `''` or whitespace-only | No banner; any non-blank text -> banner with the trimmed text (A27) |
| Store cannot be opened (`market://` and https both fail, or iOS) | `storeLaunchFailed` -> error line shown; gate stays (A31) |
| `load()` called twice | Second call is a no-op (A22) |
| A flag value is a non-boolean string on the server (`'maybe'`) | `getBool` yields `false` (SDK rule), i.e. the safe default (A16) |

## 11. Validation assertions

```
F25-A01  [U]  AnalyticsEvents.all == {'onboarding_start','onboarding_complete','onboarding_skip','login','guest_start','outfit_generated','wardrobe_items_added','outfit_saved','paywall_view'}; AnalyticsParams.all == {'occasion_count','skip_from','slide','method','mode','result_count','source','item_count','photo_count'}; every event name and param key matches ^[a-z][a-z0-9_]{0,39}$ and none starts with 'firebase_', 'google_' or 'ga_'
F25-A02  [U]  With a recording sink, each AnalyticsService method logs exactly one call with exactly the §2.1 name and parameter map: onboardingStarted -> ('onboarding_start', {}); onboardingCompleted(occasionCount: 2) -> {'occasion_count': 2}; onboardingSkipped(welcome) -> {'skip_from': 'welcome'} (no 'slide' key); onboardingSkipped(intro, slide: 3) -> {'skip_from': 'intro', 'slide': 3}; signedIn(google) -> ('login', {'method': 'google'}); guestStarted -> ('guest_start', {}); outfitGenerated(match, 2) -> {'mode': 'match', 'result_count': 2}; outfitSaved(builder, 4) -> {'source': 'builder', 'item_count': 4}; paywallViewed -> ('paywall_view', {})
F25-A03  [U]  wardrobeItemsAdded(source: 'camera'|'gallery', itemCount: 3, photoCount: 1) logs source verbatim; source 'Camera', '', 'my closet' and 'gallery ' each log source 'other'; item_count and photo_count are logged as ints
F25-A04  [U]  Privacy: across one call of every AnalyticsService method (with arbitrary inputs), every parameter key is in AnalyticsParams.all and every value is an int or one of the fixed wire strings {'welcome','intro','google','automatic','match','camera','gallery','other','generated','builder'}; no key contains 'gender', 'name', 'email', 'uid' or 'id'
              Amended 2026-10-30 (contract audit): the original wording was unsatisfiable, because A01's own key `slide` contains "id". Meaning now: no key contains 'gender', 'name', 'email' or 'uid', and no key equals 'id' or ends with '_id'. The test already checked this.
F25-A05  [U]  screenNameFor: '/home' -> 'home'; '/saved-detail?id=3' -> 'saved_detail'; '/wear-detail?id=1&outfitId=2' -> 'wear_detail'; '/not-found' -> 'not_found'; '' -> 'unknown'; '/' -> 'unknown'; '/Home' -> 'unknown'; '/a/b' -> 'unknown'; 'home' -> 'unknown'; '/home#x' -> 'home'
F25-A06  [U]  screenView('/saved-detail?id=3') calls sink.logScreenView('saved_detail') exactly once and never logEvent
F25-A07  [U]  A sink whose logEvent/logScreenView throw synchronously, and one whose futures complete with an error, both leave every AnalyticsService method returning normally with no uncaught async error reaching the test zone
F25-A08  [U]  analyticsOf(context) returns the provided instance under RepositoryProvider<AnalyticsService>.value, and an AnalyticsService equal in behaviour to .noop() (sink is NoopAnalyticsSink) when none is provided
F25-A09  [U]  Structural: within lib/, package:firebase_analytics is imported only by lib/shared/backend/firebase_analytics_sink.dart and lib/main.dart; package:firebase_remote_config only by lib/shared/backend/firebase_remote_config_service.dart and lib/main.dart; package:url_launcher and package:package_info_plus only by lib/shared/backend/app_platform.dart; no file under lib/ calls setUserId(, setUserProperty( or setDefaultEventParameters(; no file under lib/features/*/view or */widgets imports any of those four packages
F25-A10  [U]  ScreenViewTracker on a real GoRouter: after attach, go('/home') then push('/saved-detail?id=1') then pop() logs screen views ['home','saved_detail','home'] in order; a second go('/home') while already on /home logs nothing; going to an unknown path logs 'not_found'; after detach, navigation logs nothing
F25-A11  [U]  ScreenViewTracker logs paywall_view exactly once per arrival on /premium (go('/premium') -> 1; push('/plan') -> still 1; pop back to /premium -> 2) and never for /plan, /purchase or /subscription
F25-A12  [U]  RemoteConfigKeys.all == {'min_supported_version','latest_version','ai_stylist_enabled','premium_enabled','maintenance_message'}; AppConfig.defaults has minSupportedVersion '', latestVersion '', aiStylistEnabled false, premiumEnabled false, maintenanceMessage ''; AppConfig.defaults.toDefaultsMap() has exactly those five keys with those values (bools as bool)
F25-A13  [U]  AppConfig value semantics: two instances with equal fields are == with equal hashCode; copyWith(maintenanceMessage: 'x') changes only that field
F25-A14  [U]  FirebaseRemoteConfigService(mock, debug: true).initialize() calls setConfigSettings with fetchTimeout 10 s and minimumFetchInterval 5 min, then setDefaults(AppConfig.defaults.toDefaultsMap()), and returns an AppConfig built from getString/getBool of the five keys; with debug: false the minimumFetchInterval is 1 h
              Amended 2026-10-30 (review fix): was 12 h. A bad min_supported_version could keep a device gated for up to 12 h after a rollback, and the ai_stylist_enabled kill switch should act within the hour; Remote Config tolerates a 1 h client interval for five small keys.
F25-A15  [U]  FirebaseRemoteConfigService.initialize() returns AppConfig.defaults when setConfigSettings or setDefaults throws
F25-A16  [U]  FirebaseRemoteConfigService.refresh() returns the typed values after fetchAndActivate succeeds (e.g. min '1.2.0', ai flag true, message 'Down at 9'); returns null when fetchAndActivate throws; a server value typed via getBool is whatever the SDK's getBool returns (non-boolean strings are the SDK's false)
F25-A17  [U]  DefaultsRemoteConfigService: initialize() == AppConfig.defaults, refresh() == null
F25-A18  [U]  AppVersion.tryParse: '1.2.10' > '1.2.9'; '1.10.0' > '1.9.9'; '2.0' > '1.99.99'; '1.2' == '1.2.0' == '1.2.0.0'; '01.2.3' == '1.2.3'; '1.2.3+45' == '1.2.3'; '1.2.3-beta.1' == '1.2.3'; ' 1.0.0 ' parses; '', '  ', 'abc', 'v1.2', '1..2', '1.2.', '1.x', '1.2.3.4.5', '-1.0' all return null
F25-A19  [U]  AppConfigCubit.load() with initialize() -> AppConfig.defaults.copyWith(minSupportedVersion: '1.5.0'), refresh() -> defaults.copyWith(minSupportedVersion: '2.0.0') and installed '1.0.0' emits exactly two states in order: (1) config min '1.5.0', installedVersion '1.0.0', loaded false, updateRequired true (cached value applies before any fetch); (2) config min '2.0.0', installedVersion '1.0.0', loaded true, updateRequired true. The initial state (before load) is config == AppConfig.defaults, installedVersion null, loaded false, updateRequired false
F25-A20  [U]  AppConfigCubit.load() when refresh() returns null, and separately when refresh() throws: final config equals the initialize() result, loaded true, no exception escapes
F25-A21  [U]  AppConfigCubit.load() with a refresh() that never completes and fetchTimeout 50 ms: load() completes within ~50 ms with the initialize() config kept and loaded true (fake async)
              Clarified 2026-10-30 (contract audit): the test uses real time, not fake async, and asserts completion in under 2 s with a 50 ms timeout. An ignored 8 s default would still fail it.
F25-A22  [U]  Calling load() twice (concurrently and again after completion) calls initialize() and refresh() once each
F25-A23  [U]  installedVersion function returning null, and one that throws: installedVersion stays null and updateRequired/updateAvailable are false even with min '99.0.0' and latest '99.0.0'
F25-A24  [U]  updateRequired truth table (installed '1.2.9'): min '1.2.10' -> true; min '1.2.9' -> false; min '1.2.8' -> false; min '' -> false; min '1.x' -> false; min 'latest' -> false; installed '1.2.10' with min '1.2.9' -> false
F25-A25  [U]  updateAvailable (installed '1.0.1'): latest '1.0.3', min '' -> true; latest '1.0.1' -> false; latest '1.0.0' -> false; latest '' -> false; latest 'x' -> false; latest '1.0.3' with min '1.0.2' -> false (required wins, never both)
F25-A26  [U]  dismissUpdateNudge() sets showUpdateNudge false and changes nothing else; dismissMaintenance() sets showMaintenance false; neither affects updateRequired
F25-A27  [U]  maintenanceMessage: '' -> null; '   \n ' -> null; '  Back at 9  ' -> 'Back at 9'; showMaintenance mirrors it
F25-A28  [U]  openStore(): launcher returning true -> storeLaunchFailed false; returning false -> true; throwing -> true; called exactly once per call
F25-A29  [U]  AppConfigGate with default state renders its child as the direct, identical widget (no Stack/Column/Offstage added) and no banner/update keys exist
F25-A30  [U]  AppConfigGate with updateRequired: Key('update-required-view') shows 'Update required', the exact body text and 'Update now'; the child is inside an Offstage(offstage: true) and its text is neither hit-testable nor findable by find.text (skipOffstage default); there is no widget with text 'Later', 'Skip', 'Close', 'Not now' or '✕'; pressing Android back (handlePopRoute) leaves the update view showing
F25-A31  [U]  Tapping 'Update now' calls the injected openStore once; when it returns false the line "Couldn't open Google Play. Please update StyloBuddy from the Play Store." appears and the update view stays
F25-A32  [U]  AppConfigGate with showMaintenance ('Back at 9'): Key('maintenance-banner') shows 'Back at 9' above the child, the child still renders and is tappable; tapping the semantics 'Dismiss notice' control removes the banner and leaves the child
F25-A33  [U]  AppConfigGate with showUpdateNudge: Key('update-nudge-banner') shows 'A new version of StyloBuddy is available.' and 'Update'; 'Update' calls openStore once; 'Dismiss update notice' removes the banner; with both maintenance and nudge active the maintenance banner is above the nudge
F25-A34  [U]  OnboardingCubit with a recording analytics: start() logs onboarding_start; next() x4 logs nothing; the 5th next() (exit finished) logs onboarding_complete with occasion_count == chosenOccasions.length; skipFromWelcome() logs {'skip_from':'welcome'}; on slide index 2, skipFromIntro() logs {'skip_from':'intro','slide':3}; neither skip method emits a new state; after setGender('female'), no recorded event has a parameter value 'female' or 'male' or a key containing 'gender'
F25-A35  [U]  AuthCubit: signInWithGoogle success (fake repository) logs ('login', {'method':'google'}) once; cancellation (StateError), FirebaseAuthException and a generic throw each log nothing; continueAsGuest() logs guest_start and emits no state
F25-A36  [U]  StylistCubit: generateAutomatic() logs outfit_generated {'mode':'automatic','result_count':3} once after the 1150 ms wait; generateMatches() logs mode 'match' with result_count == results.length; a second call while generating logs nothing extra; closing the cubit during the wait logs nothing
F25-A37  [U]  ImportCubit: finishing a 3-draft batch with no picked files logs wardrobe_items_added {'source':'camera','item_count':3,'photo_count':0} exactly once; with source 'gallery' and one draft carrying a picked file that uploads successfully -> photo_count 1; a failed upload counts 0 for that item; intermediate confirmCurrent calls (not the last draft) log nothing
F25-A38  [U]  OutfitsCubit: saveOrFind of a new item list logs outfit_saved {'source':'generated','item_count':n}; saveOrFind of an existing list logs nothing; upsertManual create logs {'source':'builder','item_count':n}; upsertManual editing an existing id logs nothing; upsertManual with a stale editingId (falls back to create) logs source 'builder'
F25-A39  [U]  Every pre-existing constructor call of OnboardingCubit, AuthCubit, StylistCubit, ImportCubit, OutfitsCubit compiles unchanged and logs nothing (default no-op): constructing each with no analytics argument and exercising one logging path records nothing on any sink (structural: their default is AnalyticsService.noop())
F25-A40  [I]  Real StyloBuddyApp (router override, recording analytics, no Firebase): Welcome renders and screen_view 'welcome' is logged; Get Started -> Male -> Continue walks the intro through to /personalize via the UI and the recorded log contains, in order, 'welcome', onboarding_start, 'gender', 'intro', onboarding_complete, 'personalize'; no event carries a gender value
F25-A41  [I]  Real StyloBuddyApp from /welcome: 'Skip introduction' logs onboarding_skip {'skip_from':'welcome'} then screen_view 'auth'; 'Skip for now' logs guest_start then screen_view 'home'
F25-A42  [I]  Real StyloBuddyApp at /profile: tapping the Premium banner logs screen_view 'premium' and paywall_view; a uid flip (fake uidStream null -> 'uid-1', firestoreOverride fake) keeps logging screen views through the new subtree's router (tracker re-attached), and the old router's tracker no longer logs
F25-A43  [I]  Real StyloBuddyApp with remoteConfig returning min '9.0.0' from initialize() and installedVersion '1.0.0': after the app settles, UpdateRequiredView is shown, find.text('Get Started') finds nothing, and 'Update now' calls the injected openStore; with DefaultsRemoteConfigService and no installedVersion the app renders /welcome exactly as before with no banner; with maintenance_message 'Back at 9' the banner shows above Welcome and Get Started still navigates
F25-A44  [L]  Release-mode Android build against stylobuddy-b7e46 with Analytics DebugView enabled (adb shell setprop debug.firebase.analytics.app com.stylobuddy.stylobuddy): walking Welcome -> Get Started -> Male -> slides -> Personalize -> Skip for now -> Home -> View outfits -> Save -> Profile -> Premium shows, in DebugView, screen_view events with the §2.1 screen names and onboarding_start, onboarding_complete, guest_start, outfit_generated, outfit_saved, paywall_view with the documented parameters, and no parameter carrying a gender, name, email or id
F25-A45  [L]  With the template published and then min_supported_version raised above the installed versionName in a test-only condition (or on a test project), a device that has fetched it shows UpdateRequiredView on the next cold start, Android back does not reveal the app, and 'Update now' opens the Play Store listing for com.stylobuddy.stylobuddy; restoring the value removes the gate on the next fetch after the interval
F25-A46  [L]  On a device with no network on first launch, the app paints Welcome without waiting for Remote Config (no frame delay versus pre-F25), and a non-empty maintenance_message published later appears as a banner on a subsequent cold start after a successful fetch
```

## 12. Edge cases

- **`a -> b -> a` navigation** logs three screen views; only exact consecutive repeats collapse.
- **Query ids** (`/clothing?id=white-shirt`) are stripped: only `clothing` is logged. Item ids
  are slugs of item names for seed data and user-chosen for imports, so they count as content.
- **Pushed route then pop** logs the revealed screen again (it is a new view of it).
- **Welcome "Get Started" twice** (Back from `/gender`, then Get Started again) logs
  `onboarding_start` twice; the funnel counts users, not taps, in the console.
- **Intro "Skip" on the last slide** logs `onboarding_skip` with `slide: 5`, not
  `onboarding_complete` (the user did not press "Create My Wardrobe").
- **Sign-in from Personalize -> /auth -> Google** logs `login` but no `guest_start`; a guest who
  later signs in from Profile logs both (two separate decisions).
- **Version strings with build metadata** (`1.0.0+7`) compare on `1.0.0` only: build numbers
  are not part of the gate. Raising the gate needs a new `versionName`, not just a new
  `versionCode` (runbook note).
- **Installed version exactly equal** to `min_supported_version` is allowed.
- **Server min below installed after a rollback**: the next successful fetch clears the gate.
  A process already showing the gate keeps it until restart (no mid-session re-fetch, §3).
- **Forced update while signed in**: the router subtree (and its Cubits) stays alive offstage;
  nothing is lost if the gate is lifted by a later rollback in the same process (it isn't,
  per above) — the gate never disposes user state.
- **Banner + keyboard / SafeArea**: the banner consumes the top inset; screens below render
  with `padding.top == 0` so no double status-bar gap appears.
- **Web (verification surface only)**: Remote Config and Analytics are not initialized on web
  by `main.dart` differently from today; `openStoreListing` returns `false` off Android.

## 13. Open questions

**Preconditions (mechanical, applied before code):**

- **P1 — Foundation amendments (2026-10-29).** `03-domain-model.md` §1 gains the `AppConfig`
  entity and §4 gains rows for `min_supported_version`/`latest_version`/`maintenance_message`
  (missing vs empty). `01-tech-stack.md` gains a dated note (Analytics + Remote Config wired,
  two new dependencies). `07-security.md` §5 replaces "Analytics ... still Later" with the
  privacy rules. `02-architecture.md` §2 notes the analytics/remote-config abstractions are
  shared backend plumbing callable from Cubits (not views). No existing assertion is amended:
  default config renders the app unchanged and every new cubit parameter defaults to no-op.

**Product questions (non-blocking):**

- **Q1 — `ai_stylist_enabled` consumer.** Should the AI Stylist entry points be hidden while
  the flag is `false`? Today they run the in-app prototype engine (F03), not a backend, so
  hiding them would remove a working demo feature. Decided: not consumed until the LLM feature.
- **Q2 — `premium_enabled` consumer.** `/premium` and the Profile banner show a preview paywall
  (F13: "preview-only, never changes plan"). Whether to hide them for the first public launch
  is a store-review/product call; the flag is ready for it.
- **Q3 — Analytics consent.** No in-app opt-out is shipped. If the owner targets the EEA/UK at
  launch, Google's consent mode / a Settings toggle should be added before release.
- **Q4 — Release signing.** `android/app/build.gradle.kts` still signs release with the debug
  key. Not this feature's scope, but the forced-update path only matters once a real Play
  release exists.

---

## Completion block

```
Status: DONE (gates 1-3) — 2026-10-29

[x] Gate 1  Interface documented (§6; dartdoc on every public type, and on every method except the one-line analytics event methods)
[x] Gate 2  Unit          A01-A39
[x] Gate 3  Integration   A40-A43 (real StyloBuddyApp, recording analytics, no Firebase)
[ ] Gate 4  Live run      A44-A46 deferred (device + live Firebase project), same as every
                          other feature's [L] assertions; nothing published to Remote Config

Assertions: 43/46 PASS (A01-A43: 51 tests named F25_Axx + 1 manifest check); A44-A46 [L] deferred, not run
Tests:      test/shared/backend/f25_{analytics_service,structure,screen_view_tracker,remote_config}_test.dart,
            test/features/app_config/f25_{app_version,app_config_cubit,app_config_gate}_test.dart,
            test/f25_funnel_events_test.dart (A34-A39), test/f25_app_wiring_test.dart (A40-A43)
Regression: flutter analyze: No issues found; flutter test 682 passed / 10 skipped (emulator rules
            tag, excluded by default) / 0 failed (baseline before F25: 631 / 10 / 0)
Validation: built and self-checked in a session without a sub-agent tool (ADR-005); independent
            scrutiny-validator pass 2026-10-30 found no privacy or architecture problem and
            disproved the "banner loses navigator state" worry, but found two real bugs and one
            operational risk, fixed the same day:
            - AppVersion.tryParse threw on an all-digit segment beyond int range (e.g.
              '1.99999999999999999999'), which could blank the app on a uid-keyed remount; now
              returns null (fail open). A18 gained two overflow cases.
            - Android Back under the forced-update screen popped routes of the hidden app;
              the router host now uses an explicit back-button dispatcher that reports "not
              handled" while updateRequired (Back leaves the app). A30 gained an app-level
              test with a pushed route (test/f25_app_wiring_test.dart).
            - A wrong min_supported_version could keep a device gated up to 12 h after a
              rollback; the release fetch interval is now 1 h (A14 amended, dated).
            Also fixed: runbook REST publish uses the ETag instead of If-Match: *; Gate 1
            dartdoc wording. Not covered (need a device): TalkBack on the banners, real Play
            Store launch, thin Firebase adapters (A44/A45). Known, not addressed here: iOS is
            not ready (no store id / Info.plist / privacy manifest); no analytics consent toggle
            (matters for EEA/UK launches; Play Data safety form must declare it).
Interface note (2026-10-29, during build, not an assertion change): onboarding skip is two
            no-arg methods skipFromWelcome()/skipFromIntro() instead of skip(OnboardingSkipPoint),
            so no view imports lib/shared/backend/ (02 §2); A34 reworded accordingly.
```
