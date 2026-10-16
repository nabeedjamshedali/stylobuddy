/// One entry of the fixed five-item shopping catalog (prototype
/// `shopCatalog`, `app.js:220-226`).
class ShopEntry {
  const ShopEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.tone,
    required this.tag,
    required this.description,
    required this.pair,
    required this.tip,
    required this.symbol,
  });

  final String id;
  final String title;
  final String category;
  final String tone;
  final String tag;
  final String description;

  /// Wardrobe item ids this suggestion pairs with; ids missing from the
  /// current wardrobe are omitted at render time, not shown as placeholders.
  final List<String> pair;
  final String tip;

  /// Glyph rendered in the art tile in place of a photo.
  final String symbol;
}
