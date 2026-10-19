import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
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

class StyloBuddyApp extends StatelessWidget {
  const StyloBuddyApp({super.key, this.router, this.uidStream});

  /// Override for tests; defaults to the global [appRouter].
  final GoRouter? router;

  /// Override for tests; defaults to the real [uidChanges]. Driving this
  /// with a fake stream lets a widget test simulate sign-in/sign-out
  /// without ever touching `FirebaseAuth.instance` (F14-A05/A06/A08/A09).
  final Stream<String?>? uidStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: uidStream ?? uidChanges(),
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
              create: (context) =>
                  OutfitsCubit(context.read<WardrobeCubit>()),
            ),
            BlocProvider(create: (_) => PlannerCubit()),
            BlocProvider(create: (_) => ProfileCubit()),
            BlocProvider(
              create: (context) =>
                  StylistCubit(context.read<WardrobeCubit>()),
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
          child: MaterialApp.router(
            title: 'StyloBuddy',
            theme: AppTheme.light,
            routerConfig: router ?? appRouter,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
