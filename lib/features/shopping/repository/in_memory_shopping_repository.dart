import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture;

import 'shopping_repository.dart';

/// Guest-mode repository (architecture D2): today's `ShoppingCubit.
/// toggleWishlist`'s add-or-remove logic moved behind [ShoppingRepository]
/// verbatim — same semantics, same synchronous-feeling writes
/// (`SynchronousFuture`, per the Task 2/F15, Task 3/F16, Task 4/F17,
/// Task 5/F18 lesson — not `async`), no network call ever constructed on
/// this branch (F19-A09/A10).
///
/// [watchWishlist] is deliberately **single-subscription** (backed by a
/// plain, non-broadcast `StreamController`): this repository has exactly
/// one caller in this codebase today (`ShoppingCubit`'s own constructor),
/// mirroring `InMemoryProfileRepository`'s own documented stance.
class InMemoryShoppingRepository implements ShoppingRepository {
  InMemoryShoppingRepository() {
    _controller = StreamController<List<String>>();
    _emit();
  }

  List<String> _wishlist = const [];
  late final StreamController<List<String>> _controller;

  /// Synchronous escape hatch used only by `ShoppingCubit`'s constructor,
  /// for the same reason `InMemoryProfileRepository.snapshot` exists: a
  /// guest's very first frame must already show the current wishlist
  /// rather than one empty frame before this stream's first (always
  /// asynchronous) event.
  List<String> get snapshot => _wishlist;

  void _emit() {
    if (!_controller.isClosed) _controller.add(_wishlist);
  }

  @override
  Stream<List<String>> watchWishlist() => _controller.stream;

  @override
  Future<bool> toggleWishlist(String id) {
    final added = !_wishlist.contains(id);
    _wishlist = added
        ? [..._wishlist, id]
        : _wishlist.where((x) => x != id).toList();
    _emit();
    return SynchronousFuture(added);
  }
}
