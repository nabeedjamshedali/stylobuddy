import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/insights/models/insight_stats.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

void main() {
  final seed = SeedData.items;

  test('F12_A01 count wears worn computed from seed', () {
    final d = InsightStats.from(seed);
    expect(d.count, 23);
    expect(d.wears, 43);
    expect(d.worn, 18);
    expect(d.count - d.worn, 5);
  });

  test('F12_A02 categories in desc order, stable by first appearance', () {
    final d = InsightStats.from(seed);
    expect(d.cats, [
      ('Shirts', 5),
      ('Accessories', 5),
      ('Pants', 4),
      ('Shoes', 4),
      ('Dresses', 2),
      ('Outerwear', 2),
      ('Skirts', 1),
    ]);
  });

  test('F12_A03 occasions in desc order, stable by first appearance', () {
    final d = InsightStats.from(seed);
    expect(d.occasions, [
      ('Casual', 8),
      ('Office', 7),
      ('Party', 3),
      ('Everyday', 2),
      ('Wedding', 2),
      ('Date Night', 1),
    ]);
  });

  test(
    'F12_A04 top four by wears desc (ties keep wardrobe order); least is first 5 unworn',
    () {
      final d = InsightStats.from(seed);
      expect(
        d.top.take(4).map((i) => i.id),
        ['navy-chinos', 'brown-loafers', 'sage-dress', 'cream-cardigan'],
      );
      expect(
        d.least.map((i) => i.id),
        [
          'white-shirt',
          'beige-chinos',
          'black-boots',
          'black-skirt',
          'black-heels',
        ],
      );
    },
  );

  test(
    'F12_A05 wears 0 counts as unworn; empty occasion counts under Everyday',
    () {
      final items = [
        const ClothingItem(
          id: 'a',
          name: 'A',
          category: 'Shirts',
          color: 'White',
          occasion: '',
          wears: 0,
        ),
        const ClothingItem(
          id: 'b',
          name: 'B',
          category: 'Shirts',
          color: 'Black',
          occasion: 'Everyday',
          wears: 2,
        ),
      ];
      final d = InsightStats.from(items);
      expect(d.worn, 1);
      expect(d.occasions, [('Everyday', 2)]);
    },
  );

  test('F12_A06 empty wardrobe reports count 0, not a crash', () {
    final d = InsightStats.from(const []);
    expect(d.count, 0);
    expect(d.wears, 0);
    expect(d.worn, 0);
    expect(d.cats, isEmpty);
    expect(d.occasions, isEmpty);
    expect(d.top, isEmpty);
    expect(d.least, isEmpty);
  });

  test('F12_A16 when every item has wears >= 1, least is empty (fallback is a view concern)', () {
    final items = [
      const ClothingItem(
        id: 'a',
        name: 'A',
        category: 'Shirts',
        color: 'White',
        occasion: 'Office',
        wears: 3,
      ),
      const ClothingItem(
        id: 'b',
        name: 'B',
        category: 'Pants',
        color: 'Black',
        occasion: 'Casual',
        wears: 1,
      ),
    ];
    final d = InsightStats.from(items);
    expect(d.least, isEmpty);
  });

  test('F12_A20 stats derive only from the items passed in', () {
    final filtered = [for (final i in seed) if (i.id != 'white-shirt') i];
    final d = InsightStats.from(filtered);
    expect(d.count, 22);
    expect(d.least.map((i) => i.id), isNot(contains('white-shirt')));
  });

  test('InsightStats.percent rounds half up on n/total*100', () {
    expect(InsightStats.percent(5, 23), 22);
    expect(InsightStats.percent(4, 23), 17);
    expect(InsightStats.percent(2, 23), 9);
    expect(InsightStats.percent(1, 23), 4);
    expect(InsightStats.percent(18, 23), 78);
    expect(InsightStats.percent(0, 0), 0);
  });
}
