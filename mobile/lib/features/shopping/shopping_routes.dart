import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/shop_item_view.dart';
import 'view/shopping_view.dart';

/// Shopping assistant (F11): wardrobe-gap suggestions, wishlist, detail.
/// `ShoppingCubit` is provided at the app root (see `app.dart`) so the
/// wishlist survives leaving and returning to `/shopping`.
final List<RouteBase> shoppingRoutes = [
  GoRoute(
    path: AppRoutes.shopping,
    builder: (context, state) => const ShoppingView(),
  ),
  GoRoute(
    path: AppRoutes.shopItem,
    builder: (context, state) => const ShopItemView(),
  ),
];
