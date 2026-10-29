# ADR-005 — F25 Analytics + Remote Config build decisions

**Date:** 2026-10-29 · **Status:** Accepted · **Affects:** F25, 01, 02, 03, 07, `lib/app.dart`, `lib/main.dart`

## Context

F25 wires the last two Firebase services of the fixed stack. Constraints: no existing test may
need Firebase (F14 rule); views must not touch backend SDKs (02 §4); gender and other personal
data must never reach Analytics (F24 §3); a forced update must not be bypassable but a bad
Remote Config value must not lock every user out; the first frame must never wait on the
network. The build session had no sub-agent tool, so the orchestrator implemented and
self-checked F25 (same arrangement as ADR-004); an independent validator pass is owed.

## Decision

1. **Typed analytics facade, not free-form logging.** `AnalyticsService` exposes one method per
   funnel event with enum/int parameters only; `AnalyticsSink` is the swappable backend
   (`NoopAnalyticsSink` default, `FirebaseAnalyticsSink` in `main.dart`). Free text cannot be
   logged because no method accepts it (the one `String` input, import source, is clamped to
   `camera|gallery|other`). No `setUserId` / user properties.
2. **Constructor injection with a no-op default** into the five logging Cubits
   (`OnboardingCubit`, `AuthCubit`, `StylistCubit`, `ImportCubit`, `OutfitsCubit`); the app
   provides the service once via `RepositoryProvider<AnalyticsService>` above the uid-keyed
   subtree; route-built Cubits read it with `analyticsOf(context)` (no-op fallback).
3. **Screen views from a router-delegate listener** (`ScreenViewTracker`), not a
   `NavigatorObserver`: observers on `GoRouter.observers` miss `ShellRoute` navigators.
   Query parameters are stripped; unknown paths become `unknown`/`not_found`.
   Android's automatic Activity screen reporting is switched off in the manifest.
4. **`paywall_view` is route-derived** (arrival on `/premium`) so no view needs a side effect.
5. **Remote Config keys** `min_supported_version`, `latest_version`, `ai_stylist_enabled`,
   `premium_enabled`, `maintenance_message`. tech-stack.md's suggested `force_update` and
   `maintenance_mode` booleans are deliberately replaced: a version floor already expresses
   "force update" without a second flag that can disagree with it, and a non-empty message is
   the maintenance switch.
6. **Fail-open gate.** Missing, empty or unparseable version strings, or an unreadable installed
   version, never trigger the forced update. Build metadata (`+N`) and pre-release suffixes are
   ignored when comparing.
7. **Maintenance is a dismissible banner, not a blocking screen.** A blocking flag with a typo
   would take the app down for everyone; blocking maintenance needs its own decision.
8. **Soft nudge implemented** (cheap with the shared banner): dismissible per process.
9. **Flags without consumers.** `ai_stylist_enabled` / `premium_enabled` default `false` and are
   exposed on `AppConfigCubit`, but nothing reads them yet: hiding the working F03 demo stylist
   or the F13 preview paywall would change shipped behaviour and existing assertions. The
   features that wire the LLM provider and RevenueCat consume them.
10. **Startup.** `AppConfigCubit.load()` runs un-awaited from `StyloBuddyApp.initState`;
    `initialize()` returns the last activated values (so a previously fetched floor applies
    before any network), then `fetchAndActivate` bounded by 8 s. Fetch interval 5 min debug /
    12 h release. (Superseded 2026-10-30: release interval is now 1 h, see F25-A14.)
11. **Gate placement.** `MaterialApp.router(builder:)` wraps the router's Navigator in
    `AppConfigGate`; when forced, the Navigator is kept `Offstage` (state not disposed) under
    `UpdateRequiredView`. Default state returns the child untouched so no existing widget tree
    changes.
12. **Dependencies.** `package_info_plus` and `url_launcher` added (neither was present);
    imported only by `lib/shared/backend/app_platform.dart`. `.claude/harness.json` was not
    edited (agent config is out of scope); its UI boundary list does not yet include
    `lib/features/app_config/{view,widgets}` — F25-A09 covers that boundary with a test instead.
13. **Nothing published.** The template lives in `scripts/remoteconfig.template.json`;
    `firebase.json` is unchanged so a plain `firebase deploy` cannot publish it by accident.

## Alternatives rejected

| Option | Why not |
|--------|---------|
| Global static analytics singleton | Leaks between tests; hides the dependency |
| `context.read<AnalyticsService>()` in views | Views would carry side effects (project-hygiene) |
| Awaiting Remote Config before `runApp` | Blocks first paint on slow networks |
| Blocking maintenance screen | One typo takes the app down |
| Hiding AI Stylist / Premium behind default-false flags now | Changes F03/F13 behaviour and breaks their assertions |

## Consequences

Every new funnel event needs a new typed method (deliberate friction for privacy review). The
gate only reacts at cold start; real-time config is later scope. iOS needs an App Store id and
`Info.plist` flag before the update button works there.
