import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real stylist screens.
final List<RouteBase> stylistRoutes = [
  GoRoute(
    path: AppRoutes.stylist,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.occasion,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.stylingOptions,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.generating,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.results,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.resultDetail,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
