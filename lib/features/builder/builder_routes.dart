import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real builder screens.
final List<RouteBase> builderRoutes = [
  GoRoute(
    path: AppRoutes.builder,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.manualPreview,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
