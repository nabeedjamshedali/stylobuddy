import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real home screens.
final List<RouteBase> homeRoutes = [
  GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
