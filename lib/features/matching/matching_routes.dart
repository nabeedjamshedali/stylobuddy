import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real matching screens.
final List<RouteBase> matchingRoutes = [
  GoRoute(
    path: AppRoutes.matching,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchSelect,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchReview,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchOptions,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchingProgress,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchingResults,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.matchingDetail,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
