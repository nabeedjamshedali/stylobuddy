import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/builder/cubit/builder_cubit.dart';
import 'features/calendar/cubit/planner_cubit.dart';
import 'features/packing/cubit/packing_cubit.dart';
import 'features/profile/cubit/profile_cubit.dart';
import 'features/saved/cubit/outfits_cubit.dart';
import 'features/shopping/cubit/shopping_cubit.dart';
import 'features/stylist/cubit/stylist_cubit.dart';
import 'features/wardrobe/cubit/import_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_browse_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_cubit.dart';
import 'features/wardrobe/repository/wardrobe_repository.dart';
import 'shared/backend/auth_session.dart';

class StyloBuddyApp extends StatefulWidget {
  const StyloBuddyApp({super.key, this.router, this.uidStream});

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

  @override
  State<StyloBuddyApp> createState() => _StyloBuddyAppState();
}

class _StyloBuddyAppState extends State<StyloBuddyApp> {
  // Created once in initState (not in build()) so the real uidChanges()
  // stream is subscribed to exactly once per app lifetime rather than being
  // torn down and resubscribed on every unrelated root rebuild.
  late Stream<String?> _uidStream;

  @override
  void initState() {
    super.initState();
    _uidStream = widget.uidStream ?? uidChanges();
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
      builder: (context, snapshot) {
        // Keyed by uid (architecture D3): every sign-in/sign-out fully
        // tears down the previous MultiBlocProvider subtree (every root
        // Cubit `.close()`s) and builds a brand-new one — never a patched
        // Cubit that gets re-fed data, so guest and signed-in state can
        // never bleed into each other.
        return MultiBlocProvider(
          key: ValueKey(snapshot.data),
          providers: [
            // Today (Task 1 of the backend-wiring plan): only
            // `WardrobeRepository` exists and it is single-in-memory —
            // no Firestore-backed repository has landed for any feature
            // yet, so every root Cubit below still only has its current
            // in-memory construction in both the guest and signed-in
            // subtree. Tasks 2-7 each swap their own Cubit's construction
            // to pick a real Firestore repository when `snapshot.data`
            // (the uid) is non-null.
            BlocProvider(create: (_) => WardrobeCubit(WardrobeRepository())),
            BlocProvider(
              create: (context) => OutfitsCubit(context.read<WardrobeCubit>()),
            ),
            BlocProvider(create: (_) => PlannerCubit()),
            BlocProvider(create: (_) => ProfileCubit()),
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
