import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real wardrobe screens.
final List<RouteBase> wardrobeRoutes = [
  GoRoute(
    path: AppRoutes.wardrobe,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.clothingPath,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.editItem,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.filter,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.import,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.importSource,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.batch,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.analyzing,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.review,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.addConfirm,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
