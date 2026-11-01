import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/add_confirm_view.dart';
import 'view/analyzing_view.dart';
import 'view/batch_view.dart';
import 'view/clothing_view.dart';
import 'view/edit_item_view.dart';
import 'view/filter_view.dart';
import 'view/import_source_view.dart';
import 'view/import_view.dart';
import 'view/review_view.dart';
import 'view/wardrobe_view.dart';

/// Wardrobe (F06): browse/search/filter the wardrobe, view/edit/remove an
/// item, and the simulated import walk-through.
final List<RouteBase> wardrobeRoutes = [
  GoRoute(
    path: AppRoutes.wardrobe,
    builder: (context, state) => const WardrobeView(),
  ),
  GoRoute(
    path: AppRoutes.clothingPath,
    builder: (context, state) =>
        ClothingView(id: state.uri.queryParameters['id'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.editItem,
    builder: (context, state) =>
        EditItemView(id: state.uri.queryParameters['id'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.filter,
    builder: (context, state) => const FilterView(),
  ),
  GoRoute(
    path: AppRoutes.import,
    builder: (context, state) => const ImportView(),
  ),
  GoRoute(
    path: AppRoutes.importSource,
    builder: (context, state) => const ImportSourceView(),
  ),
  GoRoute(
    path: AppRoutes.batch,
    builder: (context, state) => const BatchView(),
  ),
  GoRoute(
    path: AppRoutes.analyzing,
    builder: (context, state) => const AnalyzingView(),
  ),
  GoRoute(
    path: AppRoutes.review,
    builder: (context, state) => const ReviewView(),
  ),
  GoRoute(
    path: AppRoutes.addConfirm,
    builder: (context, state) => const AddConfirmView(),
  ),
];
