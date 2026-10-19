import '../../../shared/models/clothing_item.dart';

/// Dual-mode repository interface (architecture D2): [InMemoryWardrobeRepository]
/// for guests, [FirestoreWardrobeRepository] for signed-in users, both
/// implementing this one surface so [WardrobeCubit] never needs to know
/// which it has.
abstract class WardrobeRepository {
  /// Live collection stream (architecture D6) — Firestore's `snapshots()`
  /// for the signed-in implementation, a seeded in-memory stream for the
  /// guest implementation. Never performs a write as a side effect of being
  /// listened to (F15-A22).
  Stream<List<ClothingItem>> watchItems();

  Future<void> addItem(ClothingItem item);

  Future<void> addItems(List<ClothingItem> items);

  Future<void> updateItem(ClothingItem item);

  Future<void> removeItem(String id);

  Future<void> adjustWears(List<String> ids, int delta);
}
