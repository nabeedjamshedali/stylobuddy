import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;
  late FirestoreWardrobeRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore);
    repository = FirestoreWardrobeRepository(service, 'uid-1');
  });

  ClothingItem makeItem({
    String id = 'item-1',
    String name = 'Shirt',
    String category = 'Shirts',
    String color = 'White',
    String occasion = 'Everyday',
    String season = 'All season',
    int wears = 0,
    String? sourceId,
    String? imageUrl,
  }) => ClothingItem(
    id: id,
    name: name,
    category: category,
    color: color,
    occasion: occasion,
    season: season,
    wears: wears,
    sourceId: sourceId,
    imageUrl: imageUrl,
  );

  test(
    'F15_A01 addItem followed by watchItems() first emission round-trips every field unchanged',
    () async {
      final item = makeItem(
        id: 'item-1',
        name: 'Denim Jacket',
        category: 'Jackets',
        color: 'Blue',
        occasion: 'Casual',
        season: 'Fall',
        wears: 3,
        sourceId: 'denim-jacket',
        imageUrl: 'https://example.com/photo.jpg',
      );

      await repository.addItem(item);
      final emitted = await repository.watchItems().first;

      expect(emitted.length, 1);
      final roundTripped = emitted.single;
      expect(roundTripped.id, item.id);
      expect(roundTripped.name, item.name);
      expect(roundTripped.category, item.category);
      expect(roundTripped.color, item.color);
      expect(roundTripped.occasion, item.occasion);
      expect(roundTripped.season, item.season);
      expect(roundTripped.wears, item.wears);
      expect(roundTripped.sourceId, item.sourceId);
      expect(roundTripped.imageUrl, item.imageUrl);
    },
  );

  test(
    'F15_A02 the document ID equals item.id verbatim, never re-derived or re-hashed',
    () async {
      final item = makeItem(id: 'new-1700000000000-0');
      await repository.addItem(item);

      final raw = await firestore
          .collection('users/uid-1/wardrobeItems')
          .doc('new-1700000000000-0')
          .get();
      expect(raw.exists, isTrue);
    },
  );

  test(
    'F15_A03 the stored document also carries id as a plain field equal to the doc ID',
    () async {
      final item = makeItem(id: 'item-xyz');
      await repository.addItem(item);

      final raw = await firestore
          .collection('users/uid-1/wardrobeItems')
          .doc('item-xyz')
          .get();
      expect(raw.data()!['id'], 'item-xyz');
    },
  );

  test(
    'F15_A04 updateItem replaces exactly the matching document; a second emission reflects it and no other document changes',
    () async {
      await repository.addItem(makeItem(id: 'item-1', name: 'Original'));
      await repository.addItem(makeItem(id: 'item-2', name: 'Untouched'));

      await repository.updateItem(makeItem(id: 'item-1', name: 'Renamed'));
      final emitted = await repository.watchItems().first;

      final updated = emitted.firstWhere((i) => i.id == 'item-1');
      final other = emitted.firstWhere((i) => i.id == 'item-2');
      expect(updated.name, 'Renamed');
      expect(other.name, 'Untouched');
    },
  );

  test(
    'F15_A05 removeItem removes exactly that document; watchItems() no longer includes it, every other item unaffected',
    () async {
      await repository.addItem(makeItem(id: 'item-1'));
      await repository.addItem(makeItem(id: 'item-2'));

      await repository.removeItem('item-1');
      final emitted = await repository.watchItems().first;

      expect(emitted.any((i) => i.id == 'item-1'), isFalse);
      expect(emitted.any((i) => i.id == 'item-2'), isTrue);
    },
  );

  test('F15_A06 adjustWears never drives wears below 0', () async {
    await repository.addItem(makeItem(id: 'item-1', wears: 1));

    await repository.adjustWears(['item-1'], -5);
    final emitted = await repository.watchItems().first;

    expect(emitted.single.wears, 0);
  });

  test(
    'F15_edge adjustWears skips an id that has no matching document, without throwing',
    () async {
      await repository.addItem(makeItem(id: 'item-1', wears: 2));

      await repository.adjustWears(['item-1', 'does-not-exist'], 1);
      final emitted = await repository.watchItems().first;

      expect(emitted.single.wears, 3);
    },
  );

  test(
    'F15_A15 a document with no imageUrl field at all, and one with imageUrl: null explicitly stored, both resolve to imageUrl == null',
    () async {
      await firestore.collection('users/uid-1/wardrobeItems').doc('no-field').set({
        'id': 'no-field',
        'name': 'No field',
        'category': 'Shirts',
        'color': 'White',
        'occasion': 'Everyday',
        'season': 'All season',
        'wears': 0,
      });
      await repository.addItem(makeItem(id: 'explicit-null', imageUrl: null));

      final emitted = await repository.watchItems().first;

      expect(emitted.firstWhere((i) => i.id == 'no-field').imageUrl, isNull);
      expect(
        emitted.firstWhere((i) => i.id == 'explicit-null').imageUrl,
        isNull,
      );
    },
  );

  test(
    'F15_A16 an imageUrl stored as an empty string does not resolve as a usable URL — treated the same as null',
    () async {
      await firestore.collection('users/uid-1/wardrobeItems').doc('empty-url').set({
        'id': 'empty-url',
        'name': 'Empty url',
        'category': 'Shirts',
        'color': 'White',
        'occasion': 'Everyday',
        'season': 'All season',
        'wears': 0,
        'imageUrl': '',
      });

      final emitted = await repository.watchItems().first;

      expect(emitted.single.imageUrl, isNull);
    },
  );

  test(
    'F15_A16_contrast a real, non-empty imageUrl is preserved exactly as stored',
    () async {
      await repository.addItem(
        makeItem(id: 'has-url', imageUrl: 'https://example.com/a.jpg'),
      );

      final emitted = await repository.watchItems().first;

      expect(emitted.single.imageUrl, 'https://example.com/a.jpg');
    },
  );

  test(
    'F15_A22 watchItems() performs zero writes on subscription for a brand-new, empty collection',
    () async {
      final emitted = await repository.watchItems().first;
      expect(emitted, isEmpty);

      final raw = await firestore
          .collection('users/uid-1/wardrobeItems')
          .get();
      expect(raw.docs, isEmpty);
    },
  );

  test(
    'F15_A09 FirestoreWardrobeRepository never imports/uses an in-memory seed list — a brand-new uid starts with zero items until something else writes',
    () async {
      final emitted = await repository.watchItems().first;
      expect(emitted, isEmpty);
    },
  );

  test(
    'F15_regression addItems (plural batch) writes every item in one call',
    () async {
      await repository.addItems([
        makeItem(id: 'batch-1'),
        makeItem(id: 'batch-2'),
      ]);

      final emitted = await repository.watchItems().first;
      expect(emitted.map((i) => i.id).toSet(), {'batch-1', 'batch-2'});
    },
  );
}
