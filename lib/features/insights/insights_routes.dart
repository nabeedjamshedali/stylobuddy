import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real insights screens.
final List<RouteBase> insightsRoutes = [
  GoRoute(
    path: AppRoutes.insights,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
