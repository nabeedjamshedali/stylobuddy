/// Dual-mode repository (architecture D2, D6) for `ShoppingState.wishlist`
/// only (F19 doc §2/§6). `ShoppingState.tab`/`selectedId` are named
/// exclusions (schema doc §7) and get no method here, ever — they stay
/// pure, local `ShoppingCubit.emit(state.copyWith(...))` calls.
///
/// `setMembership` follows the same "Cubit already decided, repository
/// just writes it" shape every other dual-mode repository in this app uses
/// (contrast `ProfileRepository.setStyles`) — a fix-round correction from
/// this task's original `toggleWishlist(id)` design, which let
/// `ShoppingCubit` and `FirestoreShoppingRepository` each independently
/// re-decide add-vs-remove from two different sources of truth (the
/// Cubit's own state vs. a fresh Firestore read) and could disagree,
/// producing a UI toast that claimed the opposite of what was actually
/// persisted. `ShoppingCubit.toggleWishlist` is the one place that still
/// *decides* add-or-remove (from its own held state, exactly as before);
/// [setMembership] merely carries out that already-made decision — never
/// re-reads the document to re-derive it.
abstract class ShoppingRepository {
  Stream<List<String>> watchWishlist();

  /// Adds [id] to the wishlist when [add] is `true`, removes it when
  /// `false` — an idempotent, unambiguous instruction, not a toggle the
  /// repository must figure out for itself.
  Future<void> setMembership(String id, bool add);
}
