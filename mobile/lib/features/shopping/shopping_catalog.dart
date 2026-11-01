import '../../shared/models/clothing_item.dart';
import 'models/shop_entry.dart';

/// Fixed five-item catalog and the wardrobe-gap rule, ported verbatim from
/// `shopCatalog` / `shoppingSuggestions` (`app.js:220-238`).
abstract final class ShoppingCatalog {
  static const List<ShopEntry> all = [
    ShopEntry(
      id: 'neutral-blazer',
      title: 'Neutral tailored blazer',
      category: 'Outerwear',
      tone: 'Sand / charcoal',
      tag: 'Versatile layer',
      description:
          'A structured neutral layer can bridge casual and office looks, '
          'especially with existing trousers and simple tops.',
      pair: ['white-shirt', 'navy-chinos', 'brown-loafers'],
      tip: 'Try a simple cut with enough room for lightweight layers.',
      symbol: '♧',
    ),
    ShopEntry(
      id: 'versatile-knit',
      title: 'Lightweight layering knit',
      category: 'Outerwear',
      tone: 'Stone / cream',
      tag: 'Everyday essential',
      description:
          'A breathable knit makes existing shirts and trousers work '
          'across changing temperatures.',
      pair: ['blue-shirt', 'beige-chinos', 'white-sneakers'],
      tip: 'Look for a soft texture and a midweight feel.',
      symbol: '▧',
    ),
    ShopEntry(
      id: 'formal-shoes',
      title: 'Dress-ready footwear',
      category: 'Shoes',
      tone: 'Black / brown',
      tag: 'Occasion upgrade',
      description:
          'Refined shoes can dress up combinations already in your '
          'wardrobe for meetings and formal occasions.',
      pair: ['white-shirt', 'navy-chinos', 'black-watch'],
      tip: 'Prioritize a comfortable fit and a versatile finish.',
      symbol: '◇',
    ),
    ShopEntry(
      id: 'everyday-bag',
      title: 'Everyday structured bag',
      category: 'Accessories',
      tone: 'Tan / black',
      tag: 'Finishing touch',
      description:
          'A practical bag can complete coordinated outfits without '
          'adding another clothing layer.',
      pair: ['cream-blouse', 'black-skirt', 'black-heels'],
      tip: 'Choose a size that works with your daily essentials.',
      symbol: '▣',
    ),
    ShopEntry(
      id: 'neutral-bottom',
      title: 'Versatile neutral bottoms',
      category: 'Pants',
      tone: 'Taupe / navy',
      tag: 'Easy combinations',
      description:
          'Neutral bottoms can unlock more combinations with patterned or '
          'colorful tops you already own.',
      pair: ['green-shirt', 'white-sneakers', 'black-watch'],
      tip: 'Choose a cut that complements the tops you wear most.',
      symbol: '▤',
    ),
  ];

  /// Prototype `shopItem`: unknown id falls back to the first catalog entry.
  static ShopEntry byId(String? id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);

  /// Prototype `shoppingSuggestions`: an item is suggested while the
  /// wardrobe owns fewer than the threshold count of its category.
  static List<ShopEntry> suggestionsFor(List<ClothingItem> items) {
    int count(String category) =>
        items.where((i) => i.category == category).length;
    bool keep(ShopEntry e) => switch (e.id) {
      'neutral-blazer' => count('Outerwear') < 4,
      'versatile-knit' => count('Outerwear') < 5,
      'formal-shoes' => count('Shoes') < 5,
      'everyday-bag' => count('Accessories') < 6,
      'neutral-bottom' => count('Pants') < 6,
      _ => false,
    };
    return [for (final e in all) if (keep(e)) e];
  }
}
