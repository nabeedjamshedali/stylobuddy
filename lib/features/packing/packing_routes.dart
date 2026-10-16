import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/new_trip_view.dart';
import 'view/packing_add_view.dart';
import 'view/packing_list_view.dart';
import 'view/packing_preview_view.dart';
import 'view/packing_view.dart';

/// Packing assistant (F10): create trips, a suggested-from-wardrobe packing
/// checklist, and add/remove items. `PackingCubit` is root-provided (see
/// `lib/app.dart`), same as the other durable-user-data cubits
/// (`ShoppingCubit`, `StylistCubit`, `BuilderCubit`) — see
/// `.memory/decisions/ADR-002-packing-cubit-scope.md` for why this
/// supersedes the original route-scoped `ShellRoute` design.
final List<RouteBase> packingRoutes = [
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
];
