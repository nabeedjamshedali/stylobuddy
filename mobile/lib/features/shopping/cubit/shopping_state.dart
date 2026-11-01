/// State for the shopping assistant (F11). Wishlist and tab are in-memory
/// only, per the prototype's `S.shopTab` / `S.wishlist` / `S.shopSelected`.
class ShoppingState {
  const ShoppingState({
    this.tab = 'discover',
    this.wishlist = const [],
    this.selectedId,
  });

  final String tab;

  /// Saved ids, in insertion order.
  final List<String> wishlist;

  /// `null` until a suggestion is opened; the detail screen falls back to
  /// the first catalog entry for an unknown id.
  final String? selectedId;

  ShoppingState copyWith({
    String? tab,
    List<String>? wishlist,
    String? selectedId,
  }) => ShoppingState(
    tab: tab ?? this.tab,
    wishlist: wishlist ?? this.wishlist,
    selectedId: selectedId ?? this.selectedId,
  );
}
