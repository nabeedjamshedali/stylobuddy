import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/builder_view.dart';
import 'view/manual_preview_view.dart';

/// Prototype `pages.builder` / `pages['manual-preview']`.
final List<RouteBase> builderRoutes = [
  GoRoute(
    path: AppRoutes.builder,
    builder: (context, state) => const BuilderView(),
  ),
  GoRoute(
    path: AppRoutes.manualPreview,
    builder: (context, state) => const ManualPreviewView(),
  ),
];
