import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/saved/repository/firestore_outfits_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/models/outfit.dart';
import 'package:stylobuddy/shared/models/wear_event.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;
  late FirestoreOutfitsRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore);
    repository = FirestoreOutfitsRepository(service, 'uid-1');
  });

  Outfit makeOutfit({
    int id = 1,
    String name = 'Outfit',
    String occasion = 'Everyday',
    List<String> items = const ['white-shirt'],
    String why = 'why',
    int worn = 0,
  }) => Outfit(
    id: id,
    name: name,
    occasion: occasion,
    items: items,
    why: why,
    worn: worn,
  );

  WearEvent makeEvent({
    int id = 100,
    int outfitId = 1,
    String name = 'Outfit',
    String occasion = 'Everyday',
    List<String> items = const ['white-shirt'],
    DateTime? timestamp,
  }) => WearEvent(
    id: id,
    outfitId: outfitId,
    name: name,
    occasion: occasion,
    items: items,
    timestamp: timestamp ?? DateTime.fromMillisecondsSinceEpoch(1000),
  );

  test(
    'F16_A01 saveOrFind with no identical-items match writes a new document and watchOutfits() round-trips every field unchanged',
    () async {
      final draft = makeOutfit(
        id: 500,
        name: 'New Look',
        occasion: 'Party',
        items: ['black-shirt', 'black-jeans'],
        why: 'why text',
        worn: 3,
      );

      final result = await repository.saveOrFind(draft, current: const []);
      expect(result.id, 500);

      final emitted = await repository.watchOutfits().first;
      expect(emitted.length, 1);
      final saved = emitted.single;
      expect(saved.id, 500);
      expect(saved.name, 'New Look');
      expect(saved.occasion, 'Party');
      expect(saved.why, 'why text');
      expect(saved.items, ['black-shirt', 'black-jeans']);
      expect(saved.worn, 3);
    },
  );

  test(
    'F16_A02 saveOrFind with an identical-items match (order-sensitive) writes no new document and returns the existing outfit unchanged',
    () async {
      final existing = makeOutfit(id: 1, items: ['white-shirt', 'navy-chinos']);
      final draft = makeOutfit(id: 999, items: ['white-shirt', 'navy-chinos']);

      final result = await repository.saveOrFind(draft, current: [existing]);

      expect(result.id, 1);
      final emitted = await repository.watchOutfits().first;
      expect(emitted, isEmpty);
    },
  );

  test(
    'F16_A02_order_sensitive a reordered-items draft does not match an outfit with the same items in a different order',
    () async {
      final existing = makeOutfit(id: 1, items: ['white-shirt', 'navy-chinos']);
      final draft = makeOutfit(id: 999, items: ['navy-chinos', 'white-shirt']);

      final result = await repository.saveOrFind(draft, current: [existing]);

      expect(result.id, 999);
      final emitted = await repository.watchOutfits().first;
      expect(emitted.length, 1);
    },
  );

  test(
    'F16_A03 the document ID for a saved outfit equals Outfit.id.toString() verbatim',
    () async {
      await repository.saveOrFind(makeOutfit(id: 42), current: const []);

      final raw = await firestore
          .collection('users/uid-1/outfits')
          .doc('42')
          .get();
      expect(raw.exists, isTrue);
    },
  );

  test(
    'F16_A04 the stored outfits document also carries id as a plain int field equal to int.parse(doc ID)',
    () async {
      await repository.saveOrFind(makeOutfit(id: 42), current: const []);

      final raw = await firestore
          .collection('users/uid-1/outfits')
          .doc('42')
          .get();
      expect(raw.data()!['id'], 42);
    },
  );

  test(
    'F16_A05 upsertManual with editingId set replaces exactly that document\'s name/items/occasion; other documents unaffected; worn untouched',
    () async {
      await repository.saveOrFind(
        makeOutfit(id: 1, name: 'Original', worn: 7),
        current: const [],
      );
      await repository.saveOrFind(
        makeOutfit(id: 2, name: 'Other', items: ['other-item']),
        current: const [],
      );

      final candidate = makeOutfit(
        id: 1,
        name: 'Renamed',
        occasion: 'Office',
        items: ['renamed-item'],
        worn: 0,
      );
      await repository.upsertManual(
        candidate: candidate,
        editingId: 1,
        current: const [],
      );

      final emitted = await repository.watchOutfits().first;
      final updated = emitted.firstWhere((o) => o.id == 1);
      final other = emitted.firstWhere((o) => o.id == 2);
      expect(updated.name, 'Renamed');
      expect(updated.occasion, 'Office');
      expect(updated.items, ['renamed-item']);
      // worn is untouched even though candidate.worn differs from stored.
      expect(updated.worn, 7);
      expect(other.name, 'Other');
      expect(other.items, ['other-item']);
    },
  );

  test(
    'F16_A05_fallback upsertManual editing a concurrently-deleted document falls back to set() instead of crashing',
    () async {
      final candidate = makeOutfit(id: 999, name: 'Resurrected');

      // editingId 999 has never been written, mirroring a concurrent delete.
      final result = await repository.upsertManual(
        candidate: candidate,
        editingId: 999,
        current: const [],
      );

      expect(result.name, 'Resurrected');
      final emitted = await repository.watchOutfits().first;
      expect(emitted.single.id, 999);
    },
  );

  test(
    'F16_A06 upsertManual with editingId omitted creates a new document with worn: 0, distinct id from any existing outfit',
    () async {
      await repository.saveOrFind(makeOutfit(id: 1), current: const []);

      final candidate = makeOutfit(id: 2, name: 'Fresh', worn: 0);
      final result = await repository.upsertManual(
        candidate: candidate,
        editingId: null,
        current: const [],
      );

      expect(result.id, 2);
      expect(result.worn, 0);
      final emitted = await repository.watchOutfits().first;
      expect(emitted.map((o) => o.id).toSet(), {1, 2});
    },
  );

  test(
    'F16_A07 delete removes exactly that outfits document; watchOutfits() no longer includes it; wearEvents for it are untouched',
    () async {
      await repository.saveOrFind(makeOutfit(id: 1), current: const []);
      await repository.saveOrFind(makeOutfit(id: 2), current: const []);
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1),
        event: makeEvent(id: 100, outfitId: 1),
      );

      await repository.delete(1);

      final emittedOutfits = await repository.watchOutfits().first;
      expect(emittedOutfits.any((o) => o.id == 1), isFalse);
      expect(emittedOutfits.any((o) => o.id == 2), isTrue);

      final emittedEvents = await repository.watchWearEvents().first;
      expect(emittedEvents.any((e) => e.outfitId == 1), isTrue);
    },
  );

  test(
    'F16_A08 logWear snapshots the outfit\'s items from the transaction\'s own server-side read, not the caller-supplied outfit argument',
    () async {
      await repository.saveOrFind(
        makeOutfit(id: 1, items: ['stale-item']),
        current: const [],
      );
      // Mutate the stored outfit's items directly (simulating a change
      // that happened between the Cubit's byId lookup and this call).
      await firestore.collection('users/uid-1/outfits').doc('1').update({
        'items': ['fresh-item'],
      });

      final staleOutfitArg = makeOutfit(id: 1, items: ['stale-item']);
      await repository.logWear(
        1,
        outfit: staleOutfitArg,
        event: makeEvent(id: 200, outfitId: 1),
      );

      final events = await repository.watchWearEvents().first;
      expect(events.single.items, ['fresh-item']);
    },
  );

  test(
    'F16_A08_worn logWear increments the target outfit\'s worn by exactly 1',
    () async {
      await repository.saveOrFind(
        makeOutfit(id: 1, worn: 2),
        current: const [],
      );

      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1, worn: 2),
        event: makeEvent(id: 200, outfitId: 1),
      );

      final emitted = await repository.watchOutfits().first;
      expect(emitted.single.worn, 3);
    },
  );

  test(
    'F16_A09 logWear is implemented via runTransaction, not a bare get() followed by a separate set()/update()',
    () {
      final file = File(
        'lib/features/saved/repository/firestore_outfits_repository.dart',
      );
      final content = file.readAsStringSync();
      final start = content.indexOf('Future<void> logWear(');
      expect(start, greaterThan(-1), reason: 'logWear method not found');
      final end = content.indexOf('Future<void> removeWear(');
      final body = content.substring(start, end == -1 ? content.length : end);
      expect(body.contains('runTransaction'), isTrue);
    },
  );

  test(
    'F16_A09_removeWear removeWear is implemented via runTransaction, not a bare get() followed by a separate set()/update()',
    () {
      final file = File(
        'lib/features/saved/repository/firestore_outfits_repository.dart',
      );
      final content = file.readAsStringSync();
      final start = content.indexOf('Future<void> removeWear(');
      expect(start, greaterThan(-1), reason: 'removeWear method not found');
      final body = content.substring(start);
      expect(body.contains('runTransaction'), isTrue);
    },
  );

  test(
    'F16_A10 removeWear never drives worn below 0, even when stored worn is already 0',
    () async {
      await repository.saveOrFind(
        makeOutfit(id: 1, worn: 0),
        current: const [],
      );
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1, worn: 0),
        event: makeEvent(id: 200, outfitId: 1),
      );
      // Force worn back down to 0 directly (so removeWear's clamp is the
      // only thing protecting the invariant, not the increment above).
      await firestore.collection('users/uid-1/outfits').doc('1').update({
        'worn': 0,
      });

      await repository.removeWear(200, event: makeEvent(id: 200, outfitId: 1));

      final emitted = await repository.watchOutfits().first;
      expect(emitted.single.worn, 0);
    },
  );

  test(
    'F16_A11 removeWear deletes exactly the target wearEvents document and leaves every other event (including same outfitId) untouched',
    () async {
      await repository.saveOrFind(
        makeOutfit(id: 1, worn: 2),
        current: const [],
      );
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1, worn: 0),
        event: makeEvent(id: 200, outfitId: 1),
      );
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1, worn: 1),
        event: makeEvent(id: 201, outfitId: 1),
      );

      await repository.removeWear(200, event: makeEvent(id: 200, outfitId: 1));

      final events = await repository.watchWearEvents().first;
      expect(events.map((e) => e.id).toSet(), {201});
    },
  );

  test(
    'F16_A12 watchWearEvents() emits events ordered by timestamp descending, tie-broken by id descending for equal timestamps',
    () async {
      final t = DateTime.fromMillisecondsSinceEpoch(5000);
      await repository.saveOrFind(makeOutfit(id: 1), current: const []);
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1),
        event: makeEvent(id: 10, outfitId: 1, timestamp: t),
      );
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1),
        event: makeEvent(id: 20, outfitId: 1, timestamp: t),
      );
      await repository.logWear(
        1,
        outfit: makeOutfit(id: 1),
        event: makeEvent(
          id: 5,
          outfitId: 1,
          timestamp: DateTime.fromMillisecondsSinceEpoch(9000),
        ),
      );

      final events = await repository.watchWearEvents().first;
      expect(events.map((e) => e.id).toList(), [5, 20, 10]);
    },
  );

  test(
    'F16_sort_order watchOutfits() always emits newest-first by id descending, surviving a Firestore round-trip regardless of insertion order or doc-id lexicographic order',
    () async {
      // Doc ids are Outfit.id.toString() — intentionally saved in an
      // order where lexicographic string order ('100' < '20' < '9999')
      // disagrees with both insertion order and numeric id order, so a
      // regression back to "no orderBy, Firestore's native doc-id order"
      // would emit a visibly different (and non-newest-first) sequence
      // than the one asserted below.
      await repository.saveOrFind(makeOutfit(id: 20), current: const []);
      await repository.saveOrFind(makeOutfit(id: 9999), current: const []);
      await repository.saveOrFind(makeOutfit(id: 100), current: const []);

      final emitted = await repository.watchOutfits().first;
      expect(emitted.map((o) => o.id).toList(), [9999, 100, 20]);
    },
  );

  test(
    'F16_A13 logWear against a non-existent outfitId is a silent no-op, not a crash',
    () async {
      await expectLater(
        repository.logWear(
          999,
          outfit: makeOutfit(id: 999),
          event: makeEvent(id: 1, outfitId: 999),
        ),
        completes,
      );

      final outfits = await repository.watchOutfits().first;
      final events = await repository.watchWearEvents().first;
      expect(outfits, isEmpty);
      expect(events, isEmpty);
    },
  );

  test(
    'F16_A14 removeWear against a non-existent eventId is a silent no-op, not a crash',
    () async {
      await repository.saveOrFind(
        makeOutfit(id: 1, worn: 2),
        current: const [],
      );

      await expectLater(
        repository.removeWear(999, event: makeEvent(id: 999, outfitId: 1)),
        completes,
      );

      final emitted = await repository.watchOutfits().first;
      expect(emitted.single.worn, 2);
    },
  );
}
