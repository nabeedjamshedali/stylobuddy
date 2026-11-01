import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/generating_view.dart';
import 'view/occasion_view.dart';
import 'view/result_detail_view.dart';
import 'view/results_view.dart';
import 'view/styling_options_view.dart';
import 'view/stylist_view.dart';

export 'stylist_navigation.dart' show refreshStylistResults;
export 'view/generating_view.dart' show GeneratingView;
export 'view/result_detail_view.dart' show ResultDetailView;
export 'view/results_view.dart' show ResultsView;

final List<RouteBase> stylistRoutes = [
  GoRoute(
    path: AppRoutes.stylist,
    builder: (context, state) => const StylistView(),
  ),
  GoRoute(
    path: AppRoutes.occasion,
    builder: (context, state) => const OccasionView(),
  ),
  GoRoute(
    path: AppRoutes.stylingOptions,
    builder: (context, state) => const StylingOptionsView(),
  ),
  GoRoute(
    path: AppRoutes.generating,
    builder: (context, state) => const GeneratingView(),
  ),
  GoRoute(
    path: AppRoutes.results,
    builder: (context, state) => const ResultsView(),
  ),
  GoRoute(
    path: AppRoutes.resultDetail,
    builder: (context, state) => const ResultDetailView(),
  ),
];
