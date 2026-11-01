import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../stylist/stylist_routes.dart';
import 'view/match_options_view.dart';
import 'view/match_review_view.dart';
import 'view/match_select_view.dart';
import 'view/matching_view.dart';

/// Match My Clothes (F04): a 3-step flow on top of F03's shared
/// `StylistCubit` / results views, driven with `isMatchMode: true`.
final List<RouteBase> matchingRoutes = [
  GoRoute(
    path: AppRoutes.matching,
    builder: (context, state) => const MatchingView(),
  ),
  GoRoute(
    path: AppRoutes.matchSelect,
    builder: (context, state) => const MatchSelectView(),
  ),
  GoRoute(
    path: AppRoutes.matchReview,
    builder: (context, state) => const MatchReviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchOptions,
    builder: (context, state) => const MatchOptionsView(),
  ),
  GoRoute(
    path: AppRoutes.matchingProgress,
    builder: (context, state) => const GeneratingView(match: true),
  ),
  GoRoute(
    path: AppRoutes.matchingResults,
    builder: (context, state) => const ResultsView(match: true),
  ),
  GoRoute(
    path: AppRoutes.matchingDetail,
    builder: (context, state) => const ResultDetailView(match: true),
  ),
];
