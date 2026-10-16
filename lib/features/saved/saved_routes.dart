import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real saved screens.
final List<RouteBase> savedRoutes = [
  GoRoute(
    path: AppRoutes.saved,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.savedDetailPath,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.wearDetailPath,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
