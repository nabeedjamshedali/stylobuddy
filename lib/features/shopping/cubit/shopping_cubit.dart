import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/in_memory_shopping_repository.dart';
import '../repository/shopping_repository.dart';
import 'shopping_state.dart';

/// Shopping assistant state (F11, `app.js:220-267`). Registered at the app
/// root (not feature-local) so the wishlist survives navigating away from
/// `/shopping` and back, matching the prototype's global `S.wishlist`.
///
/// `wishlist` only (F19, Task 6 of the backend-wiring plan) is now backed
/// by the dual-mode [ShoppingRepository] (architecture D2, D6); `tab`/
/// `selectedId` stay pure, local `emit(state.copyWith(...))` calls, unchanged
/// (schema doc §7's named exclusion — never a repository method).
class ShoppingCubit extends Cubit<ShoppingState> {
  // [repository] defaults to a fresh InMemoryShoppingRepository() (guest
  // mode) so the pre-existing `ShoppingCubit()` call site in lib/app.dart
  // and every pre-existing test needs no edit (same no-churn precedent as
  // F16/F17/F18's Cubit constructors). The default is resolved once in this
  // forwarding factory (never twice) so the same resolved instance backs
  // both this Cubit's initial snapshot and its live watchWishlist()
  // subscription.
  factory ShoppingCubit({ShoppingRepository? repository}) =>
      ShoppingCubit._(repository ?? InMemoryShoppingRepository());

  ShoppingCubit._(this._repository) : super(_initial(_repository)) {
    // Subscribes immediately so a Firestore reconciliation (or, for the
    // in-memory implementation, this repository's own write-driven
    // re-emit) reaches this Cubit's state — mirrors ProfileCubit's own
    // constructor-time subscription (F18), torn down in [close].
    _subscription = _repository.watchWishlist().listen(
      (wishlist) => emit(state.copyWith(wishlist: wishlist)),
      // A snapshot error must not kill this subscription silently for the
      // rest of the Cubit's lifetime, nor propagate as an unhandled stream
      // error (F19-A15) — the last known state is kept.
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchWishlist() stream error', error, stackTrace);
      },
    );
  }

  final ShoppingRepository _repository;
  late final StreamSubscription<List<String>> _subscription;

  /// Non-fatal logging for a background write/stream failure — never
  /// rethrown, never left as an unhandled async error (which `main.dart`
  /// would otherwise report to Crashlytics as `fatal: true`).
  static void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('ShoppingCubit: $context: $error\n$stackTrace');
    }
  }

  /// Mirrors ProfileCubit's `_initial`: a guest's very first frame must
  /// already show the current wishlist (today's synchronous behavior,
  /// F19-A08) rather than one empty frame before
  /// [ShoppingRepository.watchWishlist]'s always-asynchronous first event.
  /// A signed-in (Firestore) instance has no such synchronous snapshot — it
  /// legitimately starts at `ShoppingState()`'s defaults (empty wishlist)
  /// until its first `watchWishlist()` event arrives.
  static ShoppingState _initial(ShoppingRepository repository) {
    if (repository is InMemoryShoppingRepository) {
      return ShoppingState(wishlist: repository.snapshot);
    }
    return const ShoppingState();
  }

  /// Prototype `shopTab`.
  void setTab(String tab) => emit(state.copyWith(tab: tab));

  /// Prototype `openShop`.
  void select(String id) => emit(state.copyWith(selectedId: id));

  /// Prototype `toggleWish`: adds an unsaved id or removes a saved one.
  /// Returns `true` when the id was added, `false` when it was removed, so
  /// the caller can toast accordingly — same bool contract as before this
  /// task (F19 doc §6).
  ///
  /// Applies the optimistic update synchronously (matching today's
  /// instant-feeling UX and keeping the existing guest-mode test suite's
  /// synchronous assertions unaffected, F19-A08/A12) and fires the
  /// repository's own persistence call in the background. If that call
  /// fails, it rolls back ONLY `wishlist`, evaluated against the Cubit's
  /// *current* state at failure time — never a captured-whole-state-before-
  /// the-call restore, which would clobber a different, concurrently
  /// in-flight, independently succeeding `setTab`/`select` call's already
  /// applied change (F17/F18's own review-round fix, baked in here from the
  /// start — F19-A13).
  bool toggleWishlist(String id) {
    final added = !state.wishlist.contains(id);
    final previousWishlist = state.wishlist;
    final nextWishlist = added
        ? [...state.wishlist, id]
        : state.wishlist.where((x) => x != id).toList();
    emit(state.copyWith(wishlist: nextWishlist));
    unawaited(
      _repository.toggleWishlist(id).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('toggleWishlist failed', error, stackTrace);
        if (!isClosed) {
          emit(state.copyWith(wishlist: previousWishlist));
        }
        return added;
      }),
    );
    return added;
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
