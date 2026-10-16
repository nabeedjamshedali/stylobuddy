import '../../../shared/data/seed_data.dart';
import '../../../shared/models/clothing_item.dart';

class WardrobeRepository {
  /// Returns a fresh copy of the seed wardrobe (Firestore slot later).
  List<ClothingItem> loadItems() => SeedData.items;
}
