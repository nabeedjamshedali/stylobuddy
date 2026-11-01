import '../../../shared/models/clothing_item.dart';

/// Pure port of the prototype `insightStats` (`P/app.js:326`). Call
/// [InsightStats.from] with the current wardrobe items; it never mutates or
/// reads any outside state, so tests can feed it any list directly.
class InsightStats {
  const InsightStats({
    required this.items,
    required this.count,
    required this.wears,
    required this.cats,
    required this.worn,
    required this.top,
    required this.least,
    required this.occasions,
  });

  final List<ClothingItem> items;
  final int count;
  final int wears;

  /// `(category, count)`, sorted desc; ties keep first-appearance order.
  final List<(String, int)> cats;

  final int worn;

  /// All items sorted by wears desc; ties keep wardrobe order.
  final List<ClothingItem> top;

  /// Items with zero wears, in wardrobe order, first 5 only. Empty when no
  /// item is unworn ("missing is not zero": the view falls back to the
  /// lowest-wear items when this list is empty).
  final List<ClothingItem> least;

  /// `(occasion, count)`, sorted desc; ties keep first-appearance order.
  /// Items with an empty occasion are counted under 'Everyday'.
  final List<(String, int)> occasions;

  int get unused => count - worn;

  static InsightStats from(List<ClothingItem> source) {
    final items = List<ClothingItem>.of(source);
    final count = items.length;
    final wears = items.fold<int>(0, (a, b) => a + b.wears);
    final worn = items.where((i) => i.wears > 0).length;

    final cats = _groupCountsDesc(items, (i) => i.category);
    final occasions = _groupCountsDesc(
      items,
      (i) => i.occasion.isEmpty ? 'Everyday' : i.occasion,
    );

    final top = _stableSortDesc(items, (i) => i.wears);
    final least = items.where((i) => i.wears == 0).take(5).toList();

    return InsightStats(
      items: items,
      count: count,
      wears: wears,
      cats: cats,
      worn: worn,
      top: top,
      least: least,
      occasions: occasions,
    );
  }

  /// Round-half-up on `n/total*100` (`insightPercent`, `P/app.js:327`);
  /// `0` when [total] is `0` rather than dividing by zero.
  static int percent(int n, int total) {
    if (total == 0) return 0;
    return (n / total * 100).round();
  }

  static List<(String, int)> _groupCountsDesc(
    List<ClothingItem> items,
    String Function(ClothingItem) keyOf,
  ) {
    final order = <String>[];
    final counts = <String, int>{};
    for (final item in items) {
      final key = keyOf(item);
      if (!counts.containsKey(key)) order.add(key);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final indexed = [
      for (var i = 0; i < order.length; i++) (i, order[i], counts[order[i]]!),
    ]..sort((a, b) {
      final cmp = b.$3.compareTo(a.$3);
      return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) (e.$2, e.$3)];
  }

  static List<ClothingItem> _stableSortDesc(
    List<ClothingItem> items,
    int Function(ClothingItem) keyOf,
  ) {
    final indexed = [
      for (var i = 0; i < items.length; i++) (i, items[i]),
    ]..sort((a, b) {
      final cmp = keyOf(b.$2).compareTo(keyOf(a.$2));
      return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}
