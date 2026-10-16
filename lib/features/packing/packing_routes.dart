import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'cubit/packing_cubit.dart';
import 'view/new_trip_view.dart';
import 'view/packing_add_view.dart';
import 'view/packing_list_view.dart';
import 'view/packing_preview_view.dart';
import 'view/packing_view.dart';

/// Packing assistant (F10): create trips, a suggested-from-wardrobe packing
/// checklist, and add/remove items. `PackingCubit` is feature-local and
/// provided here (not at the app root) so its in-memory trips reset each
/// time this flow is entered, matching the prototype's fresh `S.trips`.
final List<RouteBase> packingRoutes = [
  ShellRoute(
    builder: (context, state, child) =>
        BlocProvider(create: (_) => PackingCubit(), child: child),
    routes: [
      GoRoute(
        path: AppRoutes.packing,
        builder: (context, state) => const PackingView(),
      ),
      GoRoute(
        path: AppRoutes.newTrip,
        builder: (context, state) => const NewTripView(),
      ),
      GoRoute(
        path: AppRoutes.packingPreview,
        builder: (context, state) => const PackingPreviewView(),
      ),
      GoRoute(
        path: AppRoutes.packingList,
        builder: (context, state) => const PackingListView(),
      ),
      GoRoute(
        path: AppRoutes.packingAdd,
        builder: (context, state) => const PackingAddView(),
      ),
    ],
  ),
];
