import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real shopping screens.
final List<RouteBase> shoppingRoutes = [
  GoRoute(
    path: AppRoutes.shopping,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.shopItem,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
