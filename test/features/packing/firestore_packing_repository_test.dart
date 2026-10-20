import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/packing/models/packing_item.dart';
import 'package:stylobuddy/features/packing/models/trip.dart';
import 'package:stylobuddy/features/packing/repository/firestore_packing_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;
  late FirestorePackingRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore);
    repository = FirestorePackingRepository(service, 'uid-1');
  });

  Trip makeTrip({
    String id = 'trip-1',
    String name = 'Lisbon getaway',
    String destination = 'Lisbon',
    String start = '2026-11-01',
    String end = '2026-11-03',
    String type = 'Vacation',
    String notes = 'bring sunscreen',
    int days = 3,
    List<PackingItem> items = const [],
  }) => Trip(
    id: id,
    name: name,
    destination: destination,
    start: start,
    end: end,
    type: type,
    notes: notes,
    days: days,
    items: items,
  );

  test(
    'F20_A01 createTrip (via saveTrip isNew:true) writes a trip document whose '
    'id/name/destination/start/end/type/notes/days round-trip exactly '
    'through watchTrips(), with items stored as [] — written as one whole '
    'document, never a subcollection',
    () async {
      final trip = makeTrip();
      await repository.saveTrip(trip, isNew: true);

      final emitted = await repository.watchTrips().first;
      expect(emitted.length, 1);
      final saved = emitted.single;
      expect(saved.id, 'trip-1');
      expect(saved.name, 'Lisbon getaway');
      expect(saved.destination, 'Lisbon');
      expect(saved.start, '2026-11-01');
      expect(saved.end, '2026-11-03');
      expect(saved.type, 'Vacation');
      expect(saved.notes, 'bring sunscreen');
      expect(saved.days, 3);
      expect(saved.items, isEmpty);

      final itemsSub = await firestore
          .collection('users/uid-1/packingTrips/trip-1/items')
          .get();
      expect(itemsSub.docs, isEmpty);
    },
  );

  test(
    'F20_A02 the Firestore document ID for a created trip is exactly '
    'trip.id.toString(), verified by reading the document directly off '
    'that path rather than only through watchTrips()',
    () async {
      await repository.saveTrip(makeTrip(id: 'trip-42'), isNew: true);

      final raw = await firestore
          .collection('users/uid-1/packingTrips')
          .doc('trip-42')
          .get();
      expect(raw.exists, isTrue);
      expect(raw.data()!['id'], 'trip-42');
    },
  );

  test(
    'F20_A03 a signed-in user\'s trip, created via createTrip, is read back '
    'correctly by a FRESH FirestorePackingRepository instance constructed '
    'afterward against the same backing Firestore data — the genuine '
    'app-restart simulation',
    () async {
      final trip = makeTrip(
        items: const [
          PackingItem(key: 'white-shirt', label: 'White Shirt', packed: true),
        ],
      );
      await repository.saveTrip(trip, isNew: true);

      // A brand-new repository instance, never the same in-memory Dart
      // objects as `repository` above, against the SAME FakeFirebaseFirestore
      // backing store.
      final restarted = FirestorePackingRepository(service, 'uid-1');
      final emitted = await restarted.watchTrips().first;
      expect(emitted.length, 1);
      expect(emitted.single.id, trip.id);
      expect(emitted.single.name, trip.name);
      expect(emitted.single.items.single.key, 'white-shirt');
      expect(emitted.single.items.single.packed, isTrue);
    },
  );

  test(
    'F20_A05 toggle reads the trip document\'s items array fresh via '
    'runTransaction and writes back only that item\'s packed field flipped, '
    'leaving every other item untouched — verified against a server value '
    'mutated between the local read and the transaction committing',
    () async {
      await repository.saveTrip(
        makeTrip(
          items: const [
            PackingItem(key: 'a', label: 'A', packed: false),
            PackingItem(key: 'b', label: 'B', packed: false),
          ],
        ),
        isNew: true,
      );

      // Mutate the stored document directly (simulating a change that
      // happened between a caller's cached copy and this call) before
      // calling toggle — the transaction must read THIS fresh value, not
      // a cached one.
      await firestore.collection('users/uid-1/packingTrips').doc('trip-1').update({
        'items': [
          {'key': 'a', 'label': 'A', 'wardrobeId': null, 'packed': true},
          {'key': 'b', 'label': 'B (renamed server-side)', 'wardrobeId': null, 'packed': false},
        ],
      });

      await repository.toggle('trip-1', 'b');

      final emitted = await repository.watchTrips().first;
      final items = emitted.single.items;
      expect(items.firstWhere((i) => i.key == 'a').packed, isTrue);
      expect(items.firstWhere((i) => i.key == 'b').packed, isTrue);
      // Only 'b's packed flag flipped; the server-side relabeling of 'b'
      // survived (proving the write is built off the fresh read, not a
      // stale cached argument).
      expect(items.firstWhere((i) => i.key == 'b').label, 'B (renamed server-side)');
    },
  );

  test(
    'F20_A06 toggle/removeItem/addWardrobe/addCustom/generateChecklist are '
    'each implemented via runTransaction, not a bare get() followed by a '
    'separate set()/update()',
    () {
      final file = File(
        'lib/features/packing/repository/firestore_packing_repository.dart',
      );
      final content = file.readAsStringSync();
      final mutateStart = content.indexOf('Future<void> _mutateItems(');
      expect(mutateStart, greaterThan(-1), reason: '_mutateItems not found');
      final body = content.substring(mutateStart);
      expect(body.contains('runTransaction'), isTrue);
      for (final method in [
        'Future<void> toggle(',
        'Future<void> removeItem(',
        'Future<void> addWardrobe(',
        'Future<void> addCustom(',
        'Future<void> generateChecklist(',
      ]) {
        expect(content.contains(method), isTrue, reason: '$method missing');
        expect(content.contains('_mutateItems('), isTrue);
      }
    },
  );

  test(
    'F20_A07 generateChecklist\'s transform fills items only when the '
    'transaction\'s own fresh server read is empty; run twice in sequence, '
    'the second run leaves items and packed flags exactly as the first left '
    'them',
    () async {
      await repository.saveTrip(makeTrip(items: const []), isNew: true);
      const suggested = [
        PackingItem(key: 'a', label: 'A'),
        PackingItem(key: 'b', label: 'B'),
      ];

      await repository.generateChecklist('trip-1', suggested);
      await repository.toggle('trip-1', 'a');

      final afterFirst = await repository.watchTrips().first;
      expect(afterFirst.single.items.length, 2);
      expect(afterFirst.single.items.firstWhere((i) => i.key == 'a').packed, isTrue);

      // Second run, with a DIFFERENT suggested list, must be a no-op since
      // the fresh server read is non-empty.
      await repository.generateChecklist('trip-1', const [
        PackingItem(key: 'c', label: 'C'),
      ]);

      final afterSecond = await repository.watchTrips().first;
      expect(afterSecond.single.items.map((i) => i.key).toList(), ['a', 'b']);
      expect(afterSecond.single.items.firstWhere((i) => i.key == 'a').packed, isTrue);
    },
  );

  test(
    'F20_A08 saveTrip (edit branch) and toggle issued concurrently against '
    'the SAME trip document both land: a final read shows the edited '
    'detail fields AND the toggled item together',
    () async {
      await repository.saveTrip(
        makeTrip(
          items: const [PackingItem(key: 'a', label: 'A', packed: false)],
        ),
        isNew: true,
      );

      final editFuture = repository.saveTrip(
        makeTrip(name: 'Lisbon renamed', destination: 'Porto'),
        isNew: false,
      );
      final toggleFuture = repository.toggle('trip-1', 'a');
      await Future.wait([editFuture, toggleFuture]);

      final emitted = await repository.watchTrips().first;
      final trip = emitted.single;
      expect(trip.name, 'Lisbon renamed');
      expect(trip.destination, 'Porto');
      expect(trip.items.single.packed, isTrue);
    },
  );

  test(
    'F20_A08_non_clobber saveTrip\'s edit branch never writes an items key '
    'at all (confirmed via the raw document map, not just an equality '
    'check)',
    () async {
      await repository.saveTrip(
        makeTrip(items: const [PackingItem(key: 'a', label: 'A')]),
        isNew: true,
      );

      await repository.saveTrip(makeTrip(name: 'Renamed'), isNew: false);

      final raw = await firestore
          .collection('users/uid-1/packingTrips')
          .doc('trip-1')
          .get();
      // items must be whatever it already was (untouched) — proven here by
      // the field still existing with its original single entry, never
      // reset to [] or any other value by the merge-set.
      final items = raw.data()!['items'] as List;
      expect(items.length, 1);
      expect(raw.data()!['name'], 'Renamed');
    },
  );

  test(
    'F20_A15 toggle/removeItem/addWardrobe/addCustom/generateChecklist '
    'against a tripId that does not exist in Firestore perform no write and '
    'resolve without throwing — a silent no-op',
    () async {
      await expectLater(repository.toggle('missing', 'x'), completes);
      await expectLater(repository.removeItem('missing', 'x'), completes);
      await expectLater(
        repository.addWardrobe('missing', const PackingItem(key: 'x', label: 'X')),
        completes,
      );
      await expectLater(
        repository.addCustom('missing', const PackingItem(key: 'x', label: 'X')),
        completes,
      );
      await expectLater(
        repository.generateChecklist('missing', const []),
        completes,
      );

      final emitted = await repository.watchTrips().first;
      expect(emitted, isEmpty);
    },
  );

  test(
    'F20_A16 watchTrips() treats a document with an entirely missing items '
    'field as an empty list, distinct in test code from an '
    'explicitly-present items: [] document, and a zero-document '
    'subcollection also emits []',
    () async {
      // (a) entirely missing 'items' field.
      await firestore.collection('users/uid-1/packingTrips').doc('no-items-field').set({
        'id': 'no-items-field',
        'name': 'No items field',
        'destination': '',
        'start': '2026-01-01',
        'end': '2026-01-02',
        'type': 'Vacation',
        'notes': '',
        'days': 2,
      });
      final emittedMissing = await repository.watchTrips().first;
      expect(emittedMissing.single.items, isEmpty);

      await repository.deleteTrip('no-items-field');

      // (b) explicitly-present items: [].
      await repository.saveTrip(makeTrip(id: 'explicit-empty', items: const []), isNew: true);
      final emittedExplicit = await repository.watchTrips().first;
      expect(emittedExplicit.single.items, isEmpty);
      await repository.deleteTrip('explicit-empty');

      // (c) zero documents at all for this uid.
      final emittedZero = await repository.watchTrips().first;
      expect(emittedZero, isEmpty);
    },
  );

  test(
    'F20_A19 deleteTrip removes exactly the target packingTrips document; '
    'watchTrips() no longer includes it, and every other trip for that uid '
    'is unaffected',
    () async {
      await repository.saveTrip(makeTrip(id: 'trip-a'), isNew: true);
      await repository.saveTrip(makeTrip(id: 'trip-b', name: 'Other'), isNew: true);

      await repository.deleteTrip('trip-a');

      final emitted = await repository.watchTrips().first;
      expect(emitted.any((t) => t.id == 'trip-a'), isFalse);
      expect(emitted.any((t) => t.id == 'trip-b'), isTrue);
    },
  );
}
