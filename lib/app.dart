import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/cubit/planner_cubit.dart';
import 'features/profile/cubit/profile_cubit.dart';
import 'features/saved/cubit/outfits_cubit.dart';
import 'features/stylist/cubit/stylist_cubit.dart';
import 'features/wardrobe/cubit/import_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_browse_cubit.dart';
import 'features/wardrobe/cubit/wardrobe_cubit.dart';
import 'features/wardrobe/repository/wardrobe_repository.dart';

class StyloBuddyApp extends StatelessWidget {
  const StyloBuddyApp({super.key, this.router});

  /// Override for tests; defaults to the global [appRouter].
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
      ],
      child: MaterialApp.router(
        title: 'StyloBuddy',
        theme: AppTheme.light,
        routerConfig: router ?? appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
