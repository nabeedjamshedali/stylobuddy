import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/insights_view.dart';

/// Style insights (F12): `/insights`. Read-only report built from
/// [InsightStats.from] over `WardrobeCubit`/`OutfitsCubit` state already
/// provided at the app root.
final List<RouteBase> insightsRoutes = [
  GoRoute(
    path: AppRoutes.insights,
    builder: (context, state) => const InsightsView(),
  ),
];
