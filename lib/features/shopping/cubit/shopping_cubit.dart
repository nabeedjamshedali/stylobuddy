import 'package:flutter_bloc/flutter_bloc.dart';

import 'shopping_state.dart';

/// Shopping assistant state (F11, `app.js:220-267`). Registered at the app
/// root (not feature-local) so the wishlist survives navigating away from
/// `/shopping` and back, matching the prototype's global `S.wishlist`.
class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit() : super(const ShoppingState());

  /// Prototype `shopTab`.
  void setTab(String tab) => emit(state.copyWith(tab: tab));

  /// Prototype `openShop`.
  void select(String id) => emit(state.copyWith(selectedId: id));

  /// Prototype `toggleWish`: adds an unsaved id or removes a saved one.
  /// Returns `true` when the id was added, `false` when it was removed, so
  /// the caller can toast accordingly.
  bool toggleWishlist(String id) {
    final added = !state.wishlist.contains(id);
    final wishlist = added
        ? [...state.wishlist, id]
        : state.wishlist.where((x) => x != id).toList();
    emit(state.copyWith(wishlist: wishlist));
    return added;
  }
}
