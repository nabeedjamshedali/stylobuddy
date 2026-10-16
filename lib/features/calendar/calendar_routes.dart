import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real calendar screens.
final List<RouteBase> calendarRoutes = [
  GoRoute(
    path: AppRoutes.calendar,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.calendarChoose,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.calendarDate,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
