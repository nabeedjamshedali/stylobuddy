import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/calendar/repository/firestore_planner_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;
  late FirestorePlannerRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore);
    repository = FirestorePlannerRepository(service, 'uid-1');
  });

  test(
    'F17_A01 plan on a key with no existing document writes a new plannedEntries/{key} document whose doc ID equals the key verbatim and watchPlanned() round-trips outfitId/occasion unchanged',
    () async {
      await repository.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 2, occasion: 'Casual'),
      );

      final raw = await firestore
          .collection('users/uid-1/plannedEntries')
          .doc('2026-10-20')
          .get();
      expect(raw.exists, isTrue);

      final emitted = await repository.watchPlanned().first;
      expect(emitted.containsKey('2026-10-20'), isTrue);
      expect(emitted['2026-10-20']!.outfitId, 2);
      expect(emitted['2026-10-20']!.occasion, 'Casual');
    },
  );

  test(
    'F17_A02 plan on a key with an existing document fully overwrites outfitId and occasion — no old field survives',
    () async {
      await repository.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 1, occasion: 'Work'),
      );
      await repository.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 9, occasion: 'Party'),
      );

      final emitted = await repository.watchPlanned().first;
      expect(emitted['2026-10-20']!.outfitId, 9);
      expect(emitted['2026-10-20']!.occasion, 'Party');
    },
  );

  test(
    'F17_A03 a plannedEntries document never carries a separate id or date field — only outfitId and occasion are written',
    () async {
      await repository.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 2, occasion: 'Casual'),
      );

      final raw = await firestore
          .collection('users/uid-1/plannedEntries')
          .doc('2026-10-20')
          .get();
      expect(raw.data()!.keys.toSet(), {'outfitId', 'occasion'});
    },
  );

  test(
    'F17_A04 remove deletes exactly the target plannedEntries document; watchPlanned() no longer includes that key, every other key unaffected',
    () async {
      await repository.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 1, occasion: 'Work'),
      );
      await repository.plan(
        '2026-10-21',
        const PlannedEntry(outfitId: 2, occasion: 'Casual'),
      );

      await repository.remove('2026-10-20');

      final emitted = await repository.watchPlanned().first;
      expect(emitted.containsKey('2026-10-20'), isFalse);
      expect(emitted['2026-10-21']!.outfitId, 2);
    },
  );

  test(
    'F17_A05 remove against a key with no existing document resolves without throwing and performs no write (a verified no-op)',
    () async {
      await expectLater(repository.remove('2026-11-30'), completes);

      final emitted = await repository.watchPlanned().first;
      expect(emitted, isEmpty);
    },
  );

  test(
    'F17_A06 plan and remove are each implemented without runTransaction — this collection intentionally performs no read-modify-write, unlike F16 logWear/removeWear',
    () {
      final file = File(
        'lib/features/calendar/repository/firestore_planner_repository.dart',
      );
      final content = file.readAsStringSync();
      final start = content.indexOf('Future<void> plan(');
      expect(start, greaterThan(-1), reason: 'plan method not found');
      final body = content.substring(start);
      expect(
        body.contains('runTransaction'),
        isFalse,
        reason:
            'plan/remove must not use runTransaction — neither reads a '
            'prior value to compute a new one (F17 doc §13)',
      );
    },
  );

  test(
    'F17_A07 watchPlanned() emits a map keyed by each document\'s own Firestore doc ID, not a field inside the document — verified with doc IDs that differ from any field value coincidentally present',
    () async {
      // outfitId/occasion values deliberately never match the doc-ID-shaped
      // date keys, so a bug keying off a field value instead of doc.id
      // would produce visibly wrong keys here.
      await repository.plan(
        '2026-01-05',
        const PlannedEntry(outfitId: 42, occasion: 'Interview'),
      );
      await repository.plan(
        '2026-07-04',
        const PlannedEntry(outfitId: 99, occasion: 'Picnic'),
      );

      final emitted = await repository.watchPlanned().first;
      expect(emitted.keys.toSet(), {'2026-01-05', '2026-07-04'});
      expect(emitted['2026-01-05']!.outfitId, 42);
      expect(emitted['2026-07-04']!.outfitId, 99);
    },
  );
}
