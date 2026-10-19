import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/builder/cubit/builder_cubit.dart';
import 'features/calendar/cubit/planner_cubit.dart';
import 'features/calendar/repository/firestore_planner_repository.dart';
import 'features/calendar/repository/in_memory_planner_repository.dart';
import 'features/packing/cubit/packing_cubit.dart';
import 'features/profile/cubit/profile_cubit.dart';
import 'features/profile/repository/firestore_profile_repository.dart';
import 'features/profile/repository/in_memory_profile_repository.dart';
import 'features/saved/cubit/outfits_cubit.dart';
import 'features/saved/repository/firestore_outfits_repository.dart';
import 'features/saved/repository/in_memory_outfits_repository.dart';
import 'features/shopping/cubit/shopping_cubit.dart';
import 'features/stylist/cubit/stylist_cubit.dart';
import 'features/wardrobe/cubit/import_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_browse_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_cubit.dart';
import 'features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'shared/backend/auth_session.dart';
import 'shared/backend/firestore_service.dart';
import 'shared/backend/pending_onboarding_selections.dart';

class StyloBuddyApp extends StatefulWidget {
  const StyloBuddyApp({
    super.key,
    this.router,
    this.uidStream,
    this.initialUid,
    this.firestoreOverride,
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

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
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
                final pendingOccasions = PendingOnboardingSelections.consume();
                unawaited(
                  repository
                      .bootstrapIfNeeded(pendingOccasions: pendingOccasions)
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
              create: (context) => StylistCubit(context.read<WardrobeCubit>()),
            ),
            BlocProvider(create: (_) => WardrobeBrowseCubit()),
            BlocProvider(
              create: (context) => ImportCubit(context.read<WardrobeCubit>()),
            ),
            BlocProvider(
              create: (context) => BuilderCubit(context.read<OutfitsCubit>()),
            ),
            BlocProvider(create: (_) => ShoppingCubit()),
            BlocProvider(create: (_) => PackingCubit()),
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
          child: _RoutedMaterialApp(router: widget.router, uid: snapshot.data),
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
  const _RoutedMaterialApp({required this.router, required this.uid});

  final GoRouter? router;

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
  late GoRouter _router;

  /// Whether `_router` was built by this widget (and so must be disposed by
  /// it) rather than handed in via `widget.router` as a test override that
  /// this widget doesn't own.
  bool _ownsRouter = false;

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
      _router = widget.router!;
      _ownsRouter = false;
    }
  }

  @override
  void dispose() {
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
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
