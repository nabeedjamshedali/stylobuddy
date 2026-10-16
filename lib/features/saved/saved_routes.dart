import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'cubit/saved_view_cubit.dart';
import 'view/saved_detail_view.dart';
import 'view/saved_view.dart';
import 'view/wear_detail_view.dart';

/// Saved looks and wear history (F08): `/saved`, `/saved-detail`,
/// `/wear-detail`. Nested under one [ShellRoute] so [SavedViewCubit] (tab +
/// search) survives drill-down navigation between the three screens, while
/// staying feature-local rather than app-root-provided.
final List<RouteBase> savedRoutes = [
  ShellRoute(
    builder: (context, state, child) =>
        BlocProvider(create: (_) => SavedViewCubit(), child: child),
    routes: [
      GoRoute(
        path: AppRoutes.saved,
        builder: (context, state) => const SavedView(),
      ),
      GoRoute(
        path: AppRoutes.savedDetailPath,
        builder: (context, state) => SavedDetailView(
          id: int.tryParse(state.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.wearDetailPath,
        builder: (context, state) => WearDetailView(
          eventId: int.tryParse(state.uri.queryParameters['id'] ?? ''),
          outfitIdHint: int.tryParse(
            state.uri.queryParameters['outfitId'] ?? '',
          ),
        ),
      ),
    ],
  ),
];
