import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/app_config/cubit/app_config_cubit.dart';
import 'features/app_config/widgets/app_config_gate.dart';
import 'features/builder/cubit/builder_cubit.dart';
import 'features/calendar/cubit/planner_cubit.dart';
import 'features/calendar/repository/firestore_planner_repository.dart';
import 'features/calendar/repository/in_memory_planner_repository.dart';
import 'features/packing/cubit/packing_cubit.dart';
import 'features/packing/repository/firestore_packing_repository.dart';
import 'features/packing/repository/in_memory_packing_repository.dart';
import 'features/profile/cubit/profile_cubit.dart';
import 'features/profile/repository/firestore_profile_repository.dart';
import 'features/profile/repository/in_memory_profile_repository.dart';
import 'features/saved/cubit/outfits_cubit.dart';
import 'features/saved/repository/firestore_outfits_repository.dart';
import 'features/saved/repository/in_memory_outfits_repository.dart';
import 'features/shopping/cubit/shopping_cubit.dart';
import 'features/shopping/repository/firestore_shopping_repository.dart';
import 'features/shopping/repository/in_memory_shopping_repository.dart';
import 'features/stylist/cubit/stylist_cubit.dart';
import 'features/wardrobe/cubit/import_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_browse_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_cubit.dart';
import 'features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'shared/backend/ai_stylist_client.dart';
import 'shared/backend/analytics_service.dart';
import 'shared/backend/app_platform.dart';
import 'shared/backend/auth_session.dart';
import 'shared/backend/firestore_service.dart';
import 'shared/backend/http_ai_stylist_client.dart';
import 'shared/backend/pending_onboarding_selections.dart';
import 'shared/backend/remote_config_service.dart';
import 'shared/backend/screen_view_tracker.dart';
import 'shared/data/seed_data.dart';

/// The single, combined D5 bootstrap seed writer (F18 fix-round, binding
/// controller ruling) — writes `SeedData`'s wardrobe items, outfits, and
/// planned entries under the given [userDoc]'s subcollections, reusing
/// each feature's own `FirestoreXRepository.seedFieldsFor*` document-write
/// shape rather than hand-duplicating field lists here. This is the one
/// and only production call site for wardrobe/outfits/planner's D5 seed
/// data — before this fix round, `runBootstrapIfNeeded` (Task 1) had zero
/// production callers at all for those three features, so a real
/// brand-new signed-in user never got their wardrobe/outfits/planner
/// seeded.
///
/// Side-effect-free outside [tx] (no network calls, no writes via a
/// different client) and safe to re-run if the transaction retries on
/// contention (every write is a fixed-id `tx.set`, so re-running this is
/// idempotent) — per D5's existing `seedWriter` contract.
Future<void> _bootstrapOtherFeatures(
  Transaction tx,
  DocumentReference<Map<String, dynamic>> userDoc,
) async {
  for (final item in SeedData.items) {
    tx.set(
      userDoc.collection('wardrobeItems').doc(item.id),
      FirestoreWardrobeRepository.seedFieldsFor(item),
    );
  }
  for (final outfit in SeedData.outfits) {
    tx.set(
      userDoc.collection('outfits').doc(outfit.id.toString()),
      FirestoreOutfitsRepository.seedFieldsForOutfit(outfit),
    );
  }
  for (final entry in SeedData.planned.entries) {
    tx.set(
      userDoc.collection('plannedEntries').doc(entry.key),
      FirestorePlannerRepository.seedFieldsFor(entry.value),
    );
  }
}

class StyloBuddyApp extends StatefulWidget {
  const StyloBuddyApp({
    super.key,
    this.router,
    this.uidStream,
    this.initialUid,
    this.firestoreOverride,
    this.analytics,
    this.remoteConfig,
    this.installedVersion,
    this.openStore,
    this.aiStylistClient,
  });

  /// Override for tests; when omitted a brand-new [GoRouter] is built (via
  /// [createAppRouter]) every time the uid-keyed subtree below is rebuilt —
  /// see [_StyloBuddyAppState.build] for why that matters.
  ///
  /// A test that passes this override opts out of that uid-aware
  /// router-teardown behavior entirely: the same [GoRouter] instance is
  /// reused across a uid flip (see `didUpdateWidget`/`_RoutedMaterialApp`
  /// below), so such a test exercises nothing about whether a
  /// sign-in/sign-out transition tears down the previous navigation stack.
  /// Only a test that omits this parameter (letting `app.dart` build its
  /// own router per uid) covers that behavior — see
  /// `F14_A05_regression` in `test/app_backend_wiring_test.dart`.
  final GoRouter? router;

  /// Override for tests; defaults to the real [uidChanges]. Driving this
  /// with a fake stream lets a widget test simulate sign-in/sign-out
  /// without ever touching `FirebaseAuth.instance` (F14-A05/A06/A08/A09).
  final Stream<String?>? uidStream;

  /// Test-only seam: when paired with [uidStream] (never used alone, and
  /// never set by production code — the real app always omits this and
  /// relies on [currentUid] instead), this is the value the `StreamBuilder`
  /// built around [uidStream] renders on its very first build, before
  /// [uidStream] has emitted anything. Lets a widget test prove the "already
  /// signed in at cold start" first frame — see
  /// `F14_initialData_first_frame` in `test/app_backend_wiring_test.dart` —
  /// without touching `FirebaseAuth.instance`.
  final String? initialUid;

  /// Test-only seam (Task 2, F15): overrides the [FirebaseFirestore]
  /// instance a signed-in uid-keyed subtree's Firestore-backed
  /// repositories are built with (e.g. `FirestoreWardrobeRepository`).
  /// Never set by production code, which always relies on the real
  /// `FirebaseFirestore.instance`. Needed because the uid-stream test seam
  /// above lets a widget test simulate a signed-in uid (e.g. `'uid-1'')
  /// without ever calling `Firebase.initializeApp()` — without this
  /// override, constructing a real `FirestoreService()` for that uid would
  /// throw `[core/no-app]` the moment any Firestore-backed repository is
  /// touched. A test instead passes a `FakeFirebaseFirestore()` here.
  final FirebaseFirestore? firestoreOverride;

  /// F25: the app-wide analytics service. `main.dart` passes the Firebase
  /// one; omitted (every test) it is the no-op service, so no test needs
  /// Firebase. Provided once above the uid-keyed subtree, so it survives
  /// sign-in/sign-out.
  final AnalyticsService? analytics;

  /// F25: Remote Config source. Defaults to [DefaultsRemoteConfigService]
  /// (in-app defaults, never fetches).
  final RemoteConfigService? remoteConfig;

  /// F25: reads the installed `versionName`. Defaults to "unknown", which
  /// never triggers the forced update.
  final Future<String?> Function()? installedVersion;

  /// F25: opens the store listing for the update button. Defaults to
  /// [openStoreListing].
  final Future<bool> Function()? openStore;

  /// F26 test-only seam: replaces the real HTTP AI client for signed-in users.
  /// Production never sets it. Guests never get a client either way.
  final AiStylistClient? aiStylistClient;

  @override
  State<StyloBuddyApp> createState() => _StyloBuddyAppState();
}

class _StyloBuddyAppState extends State<StyloBuddyApp> {
  // Created once in initState (not in build()) so the real uidChanges()
  // stream is subscribed to exactly once per app lifetime rather than being
  // torn down and resubscribed on every unrelated root rebuild.
  late Stream<String?> _uidStream;

  /// `StreamBuilder`'s `initialData`. For the production `uidChanges()`
  /// stream this is always [currentUid]'s synchronous read. For a
  /// test-injected `widget.uidStream`, it is `widget.initialUid` (`null`
  /// unless a test opts in) rather than a fresh `currentUid()` call, so a
  /// test never depends on the real `FirebaseAuth.instance`. `uidChanges()`'s
  /// own first emission is always asynchronous, so without this, a
  /// signed-in cold start would render the guest subtree for one frame
  /// before that first emission arrives — see the `currentUid()`/
  /// `uidChanges()` doc comments in `shared/backend/auth_session.dart`.
  String? _initialUid;

  /// F25: fixed for the app's lifetime (not rebuilt on a uid change).
  late final AnalyticsService _analytics;
  late final AppConfigCubit _appConfig;

  @override
  void initState() {
    super.initState();
    _analytics = widget.analytics ?? const AnalyticsService.noop();
    // F25: the Remote Config load runs in the background and never delays
    // the first frame; until it lands the state is the in-app defaults.
    _appConfig = AppConfigCubit(
      remoteConfig: widget.remoteConfig ?? const DefaultsRemoteConfigService(),
      installedVersion: widget.installedVersion,
      openStore: widget.openStore ?? openStoreListing,
    );
    unawaited(_appConfig.load());
    if (widget.uidStream != null) {
      _uidStream = widget.uidStream!;
      _initialUid = widget.initialUid;
    } else {
      _initialUid = currentUid();
      _uidStream = uidChanges();
    }
  }

  @override
  void didUpdateWidget(covariant StyloBuddyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a test replaces an already-mounted StyloBuddyApp's `uidStream`
    // override (e.g. calling `tester.pumpWidget` again with a different
    // fake stream on the same root Element, which Flutter reconciles via
    // didUpdateWidget rather than a fresh initState since the widget's
    // runtimeType/key haven't changed). Production never passes an
    // override, so this never fires for the real app.
    if (widget.uidStream != null && widget.uidStream != oldWidget.uidStream) {
      _uidStream = widget.uidStream!;
    }
  }

  @override
  void dispose() {
    unawaited(_appConfig.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AnalyticsService>.value(
      value: _analytics,
      child: BlocProvider<AppConfigCubit>.value(
        value: _appConfig,
        child: _buildUidKeyedApp(),
      ),
    );
  }

  Widget _buildUidKeyedApp() {
    return StreamBuilder<String?>(
      stream: _uidStream,
      initialData: _initialUid,
      builder: (context, snapshot) {
        // Keyed by uid (architecture D3): every sign-in/sign-out fully
        // tears down the previous MultiBlocProvider subtree (every root
        // Cubit `.close()`s) and builds a brand-new one — never a patched
        // Cubit that gets re-fed data, so guest and signed-in state can
        // never bleed into each other.
        return MultiBlocProvider(
          key: ValueKey(snapshot.data),
          providers: [
            // First real dual-mode swap (Task 2 of the backend-wiring
            // plan, resolving F14 §13's open question): in-memory for a
            // guest (`uid == null`), Firestore (scoped to that uid) for a
            // signed-in user. Tasks 3-7 each do the same for their own
            // Cubit's construction.
            BlocProvider(
              create: (_) => WardrobeCubit(
                snapshot.data == null
                    ? InMemoryWardrobeRepository()
                    : FirestoreWardrobeRepository(
                        FirestoreService(firestore: widget.firestoreOverride),
                        snapshot.data!,
                      ),
              ),
            ),
            BlocProvider(
              create: (context) => OutfitsCubit(
                context.read<WardrobeCubit>(),
                repository: snapshot.data == null
                    ? InMemoryOutfitsRepository()
                    : FirestoreOutfitsRepository(
                        FirestoreService(firestore: widget.firestoreOverride),
                        snapshot.data!,
                      ),
                analytics: _analytics,
              ),
            ),
            BlocProvider(
              create: (_) => PlannerCubit(
                repository: snapshot.data == null
                    ? InMemoryPlannerRepository()
                    : FirestorePlannerRepository(
                        FirestoreService(firestore: widget.firestoreOverride),
                        snapshot.data!,
                      ),
              ),
            ),
            BlocProvider(
              create: (_) {
                if (snapshot.data == null) {
                  return ProfileCubit(
                    repository: InMemoryProfileRepository(),
                  );
                }
                final repository = FirestoreProfileRepository(
                  FirestoreService(firestore: widget.firestoreOverride),
                  snapshot.data!,
                );
                // Consume-and-clear the onboarding handoff holder exactly
                // once per signed-in subtree construction (F18 Task 5) —
                // folded into this uid's D5 bootstrap seed write. A
                // returning/already-seeded uid's bootstrap is a no-op
                // (F14's existing guard), so this is safe to call every
                // time without re-seeding. Fire-and-forget with error
                // handling (contract requirement) — the BlocProvider
                // `create` callback cannot be async; `watchProfile()`'s
                // live subscription below picks up the seeded document
                // once the transaction commits.
                //
                // F18 fix round: this is also the single production call
                // site for wardrobe/outfits/planner's D5 seed data
                // (_bootstrapOtherFeatures, passed as seedWriter) and for
                // the real signed-in user's FirebaseAuth display
                // name/email (currentUserProfileHint, Important #4) —
                // both folded into this one runBootstrapIfNeeded call
                // under the single shared `seeded` flag, per the
                // controller ruling.
                final pendingOccasions = PendingOnboardingSelections.consume();
                // F24: the /gender choice rides the same bootstrap seed;
                // consumed (cleared) exactly once here even when the uid is
                // already seeded, so it never leaks into a later sign-up.
                final pendingGender = PendingOnboardingSelections.consumeGender();
                final profileHint = currentUserProfileHint();
                unawaited(
                  repository
                      .bootstrapIfNeeded(
                        pendingOccasions: pendingOccasions,
                        gender: pendingGender,
                        name: profileHint.name,
                        email: profileHint.email,
                        seedWriter: _bootstrapOtherFeatures,
                      )
                      .catchError((Object error, StackTrace stackTrace) {
                        if (kDebugMode) {
                          debugPrint(
                            'StyloBuddyApp: profile bootstrap failed: '
                            '$error\n$stackTrace',
                          );
                        }
                      }),
                );
                return ProfileCubit(repository: repository);
              },
            ),
            BlocProvider(
              create: (context) => StylistCubit(
                context.read<WardrobeCubit>(),
                analytics: _analytics,
                // F26: guests never get an AI client; the flag is read at
                // call time, so a late Remote Config load applies to the
                // next generation.
                aiClient: snapshot.data == null
                    ? null
                    : (widget.aiStylistClient ?? HttpAiStylistClient()),
                aiAvailable: () =>
                    snapshot.data != null &&
                    _appConfig.state.config.aiStylistEnabled,
              ),
            ),
            BlocProvider(create: (_) => WardrobeBrowseCubit()),
            BlocProvider(
              create: (context) => ImportCubit(
                context.read<WardrobeCubit>(),
                analytics: _analytics,
              ),
            ),
            BlocProvider(
              create: (context) => BuilderCubit(context.read<OutfitsCubit>()),
            ),
            BlocProvider(
              create: (_) => ShoppingCubit(
                repository: snapshot.data == null
                    ? InMemoryShoppingRepository()
                    : FirestoreShoppingRepository(
                        FirestoreService(firestore: widget.firestoreOverride),
                        snapshot.data!,
                      ),
              ),
            ),
            BlocProvider(
              create: (_) => PackingCubit(
                repository: snapshot.data == null
                    ? InMemoryPackingRepository()
                    : FirestorePackingRepository(
                        FirestoreService(firestore: widget.firestoreOverride),
                        snapshot.data!,
                      ),
              ),
            ),
          ],
          // _RoutedMaterialApp is a child of this uid-keyed MultiBlocProvider
          // (not a sibling built directly here), so when the ValueKey above
          // changes, Flutter disposes this entire Element subtree — the
          // router included — and builds a brand-new one. Building the
          // GoRouter directly in this method (or reusing the global
          // `appRouter` singleton) would NOT achieve that: go_router keeps
          // its own internal GlobalKey<NavigatorState>-backed state
          // independent of the Flutter element tree above it, so a widget
          // that cached a Cubit reference in initState (e.g.
          // manual_preview_view.dart, new_trip_view.dart) could survive a
          // sign-in/sign-out transition by being *reparented* into the new
          // tree instead of disposed, left holding a now-closed Cubit.
          // Giving every uid-keyed subtree its own fresh GoRouter instance
          // (created once, in _RoutedMaterialApp's own initState) forces
          // go_router to tear down and rebuild its whole Navigator/page
          // stack together with the providers above it.
          child: _RoutedMaterialApp(
            router: widget.router,
            uid: snapshot.data,
            analytics: _analytics,
          ),
        );
      },
    );
  }
}

/// Builds (and, in tests, may be handed) the [GoRouter] used by
/// [MaterialApp.router]. Deliberately a separate [StatefulWidget] whose
/// [State] constructs the router once in [initState]: see the comment above
/// where this is instantiated in [_StyloBuddyAppState.build] for why that
/// placement (rather than building it inline in `build()`) is load-bearing.
class _RoutedMaterialApp extends StatefulWidget {
  const _RoutedMaterialApp({
    required this.router,
    required this.uid,
    required this.analytics,
  });

  final GoRouter? router;

  /// F25: every router this widget uses gets a [ScreenViewTracker].
  final AnalyticsService analytics;

  /// The uid this subtree was built for (`null` means guest). Only consulted
  /// when `router` is null, to pick the freshly-built [GoRouter]'s
  /// `initialLocation`: signed-in lands on [AppRoutes.home], guest lands on
  /// [AppRoutes.welcome]. This widget is itself a child of the uid-keyed
  /// `MultiBlocProvider` in [_StyloBuddyAppState.build], so it is only ever
  /// constructed fresh (never updated in place) when the uid actually
  /// changes — see the comment there for why that matters.
  final String? uid;

  @override
  State<_RoutedMaterialApp> createState() => _RoutedMaterialAppState();
}

class _RoutedMaterialAppState extends State<_RoutedMaterialApp> {
  late final BackButtonDispatcher _backDispatcher = _UpdateWallBackDispatcher(
    _updateRequired,
  );
  late GoRouter _router;

  bool _updateRequired() {
    if (!mounted) return false;
    try {
      return context.read<AppConfigCubit>().state.updateRequired;
    } catch (_) {
      return false;
    }
  }


  /// Whether `_router` was built by this widget (and so must be disposed by
  /// it) rather than handed in via `widget.router` as a test override that
  /// this widget doesn't own.
  bool _ownsRouter = false;

  /// F25: `screen_view` logging for `_router`; re-attached when a test swaps
  /// the router, detached before the router is disposed.
  late ScreenViewTracker _tracker;

  @override
  void initState() {
    super.initState();
    if (widget.router != null) {
      _router = widget.router!;
    } else {
      _router = createAppRouter(
        initialLocation: widget.uid != null
            ? AppRoutes.home
            : AppRoutes.welcome,
      );
      _ownsRouter = true;
    }
    _tracker = ScreenViewTracker(_router, widget.analytics)..attach();
  }

  @override
  void didUpdateWidget(covariant _RoutedMaterialApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mirrors _StyloBuddyAppState.didUpdateWidget: only relevant when a
    // test re-pumps StyloBuddyApp with a different explicit `router:` on
    // an already-mounted root Element (same uid key, so this subtree isn't
    // torn down). Production never passes an override, so `widget.router`
    // is always null there and this never fires.
    if (widget.router != null && widget.router != oldWidget.router) {
      _tracker.detach();
      _router = widget.router!;
      _ownsRouter = false;
      _tracker = ScreenViewTracker(_router, widget.analytics)..attach();
    }
  }

  @override
  void dispose() {
    _tracker.detach();
    // Only dispose a router this widget built itself — a test-injected
    // `widget.router` override is owned by whoever constructed it, not by
    // this widget.
    if (_ownsRouter) {
      _router.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StyloBuddy',
      theme: AppTheme.light,
      // Explicit pieces (not `routerConfig:`) so the back button can be
      // intercepted: while the forced-update screen is up, Android Back must
      // leave the app, not silently pop routes of the hidden app behind it.
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      backButtonDispatcher: _backDispatcher,
      debugShowCheckedModeBanner: false,
      // F25: forced update / maintenance notice / update nudge. Returns the
      // Navigator untouched under default Remote Config values.
      builder: (context, child) =>
          AppConfigGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// F25 review fix: with the forced-update screen showing, Back reports
/// "not handled" so the system leaves the app, instead of popping routes of
/// the (hidden) app behind the wall.
class _UpdateWallBackDispatcher extends RootBackButtonDispatcher {
  _UpdateWallBackDispatcher(this._blocked);

  final bool Function() _blocked;

  @override
  Future<bool> didPopRoute() {
    if (_blocked()) return Future<bool>.value(false);
    return super.didPopRoute();
  }
}
