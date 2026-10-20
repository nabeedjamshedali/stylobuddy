/// Dual-mode repository (architecture D2, D6) for `ShoppingState.wishlist`
/// only (F19 doc §2/§6). `ShoppingState.tab`/`selectedId` are named
/// exclusions (schema doc §7) and get no method here, ever — they stay
/// pure, local `ShoppingCubit.emit(state.copyWith(...))` calls.
///
/// `toggleWishlist` is the one case in this app's dual-mode repositories
/// where the Cubit does NOT hand the repository an already-computed final
/// value (contrast `ProfileRepository.setStyles`): the repository itself
/// holds (in-memory) or reads (Firestore) the current membership and
/// computes the add-or-remove result, returning whether the id was added
/// (`true`) or removed (`false`) — mirroring `ShoppingCubit.
/// toggleWishlist`'s existing bool contract verbatim (F19 doc §6).
abstract class ShoppingRepository {
  Stream<List<String>> watchWishlist();

  Future<bool> toggleWishlist(String id);
}
