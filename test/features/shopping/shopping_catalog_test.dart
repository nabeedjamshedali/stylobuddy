import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/shopping/shopping_catalog.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

void main() {
  final seed = SeedData.items;

  test('F11_A02 seed wardrobe shows all five suggestions', () {
    final suggestions = ShoppingCatalog.suggestionsFor(seed);
    expect(suggestions.map((e) => e.id), [
      'neutral-blazer',
      'versatile-knit',
      'formal-shoes',
      'everyday-bag',
      'neutral-bottom',
    ]);
  });

  test(
    'F11_A03 adding Outerwear items removes the blazer first, then the knit',
    () {
      ClothingItem outerwear(String id) => ClothingItem(
        id: id,
        name: id,
        category: 'Outerwear',
        color: 'Black',
        occasion: 'Casual',
      );

      // Seed already has 2 Outerwear items; +2 more makes 4.
      final fourOuterwear = [...seed, outerwear('o1'), outerwear('o2')];
      final at4 = ShoppingCatalog.suggestionsFor(fourOuterwear).map((e) => e.title);
      expect(at4, isNot(contains('Neutral tailored blazer')));
      expect(at4, contains('Lightweight layering knit'));

      final fiveOuterwear = [...fourOuterwear, outerwear('o3')];
      final at5 = ShoppingCatalog.suggestionsFor(fiveOuterwear).map((e) => e.title);
      expect(at5, isNot(contains('Neutral tailored blazer')));
      expect(at5, isNot(contains('Lightweight layering knit')));
    },
  );

  test('F11_A04 category thresholds hide the matching suggestion', () {
    ClothingItem of(String category) => ClothingItem(
      id: '$category-extra',
      name: category,
      category: category,
      color: 'Black',
      occasion: 'Casual',
    );

    // Seed has 4 Shoes; +1 makes 5 -> formal shoes hidden.
    final fiveShoes = [...seed, of('Shoes')];
    expect(
      ShoppingCatalog.suggestionsFor(fiveShoes).map((e) => e.title),
      isNot(contains('Dress-ready footwear')),
    );

    // Seed has 5 Accessories; +1 makes 6 -> bag hidden.
    final sixAccessories = [...seed, of('Accessories')];
    expect(
      ShoppingCatalog.suggestionsFor(sixAccessories).map((e) => e.title),
      isNot(contains('Everyday structured bag')),
    );

    // Seed has 4 Pants; +2 makes 6 -> neutral bottoms hidden.
    final sixPants = [...seed, of('Pants'), of('Pants')];
    expect(
      ShoppingCatalog.suggestionsFor(sixPants).map((e) => e.title),
      isNot(contains('Versatile neutral bottoms')),
    );
  });

  test('F11_A15 unknown selected id falls back to the first catalog entry', () {
    expect(ShoppingCatalog.byId('nope').title, 'Neutral tailored blazer');
    expect(ShoppingCatalog.byId(null).title, 'Neutral tailored blazer');
  });

  test('F11_A12 neutral-bottom pair omits green-shirt (not in the seed wardrobe)', () {
    final entry = ShoppingCatalog.byId('neutral-bottom');
    expect(entry.pair, contains('green-shirt'));
    final ids = seed.map((i) => i.id).toSet();
    final owned = entry.pair.where(ids.contains).toList();
    expect(owned, ['white-sneakers', 'black-watch']);
  });
}
