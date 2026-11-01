import 'dart:async';

import '../../../shared/data/seed_data.dart';
import '../../../shared/models/clothing_item.dart';
import 'wardrobe_repository.dart';

/// Guest-mode repository (architecture D2): today's `SeedData.items`
/// behavior moved behind [WardrobeRepository] verbatim — same seed list,
/// same synchronous-feeling writes (every write's `Future` is already
/// resolved by the time it's returned), no network call ever constructed
/// on this branch (F15-A08).
///
/// [watchItems] is deliberately **single-subscription** (backed by a plain
/// `StreamController<List<ClothingItem>>()`, not `.broadcast()`): this
/// repository has exactly one caller in this codebase today
/// ([WardrobeCubit]'s own constructor), so multi-listener support was never
/// needed and a second concurrent `.listen()` would throw
/// `Bad state: Stream has already been listened to`. If a future caller
/// ever needs a second concurrent listener against this class, switch the
/// controller to `.broadcast()` (see [WardrobeRepository.watchItems]'s own
/// doc comment for why this isn't guaranteed by the interface).
class InMemoryWardrobeRepository implements WardrobeRepository {
  InMemoryWardrobeRepository() {
    // A single-subscription StreamController buffers events added before
    // anyone has listened yet rather than dropping them, so the seed list
    // added here in the constructor is still delivered once
    // [WardrobeCubit] subscribes in its own constructor, immediately after
    // this repository is constructed (architecture D6: "a Stream wrapping
    // a StreamController seeded once for the in-memory implementation").
    _controller = StreamController<List<ClothingItem>>();
    _emit();
  }

  final List<ClothingItem> _items = List.of(SeedData.items);
  late final StreamController<List<ClothingItem>> _controller;

  /// Synchronous escape hatch used only by [WardrobeCubit]'s constructor
  /// (see its docstring) so a guest's very first frame already has the
  /// seed list — Dart's `Stream` contract never delivers an event
  /// synchronously to a just-attached listener (verified: even a
  /// single-subscription controller seeded before `.listen()` only
  /// delivers on the next microtask), so without this, a guest would see
  /// one empty frame before the real F06 seed data appears, which neither
  /// today's behavior nor F15-A07's "zero existing assertion edited"
  /// requirement can tolerate.
  List<ClothingItem> get snapshot => List.unmodifiable(_items);

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Stream<List<ClothingItem>> watchItems() => _controller.stream;

  @override
  Future<void> addItem(ClothingItem item) async {
    _items.add(item);
    _emit();
  }

  @override
  Future<void> addItems(List<ClothingItem> items) async {
    _items.addAll(items);
    _emit();
  }

  @override
  Future<void> updateItem(ClothingItem item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
    _emit();
  }

  @override
  Future<void> removeItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    _emit();
  }

  @override
  Future<void> adjustWears(List<String> ids, int delta) async {
    for (var i = 0; i < _items.length; i++) {
      if (ids.contains(_items[i].id)) {
        _items[i] = _items[i].copyWith(
          wears: (_items[i].wears + delta).clamp(0, 1 << 30),
        );
      }
    }
    _emit();
  }
}
