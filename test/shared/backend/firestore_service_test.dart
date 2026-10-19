import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore);
  });

  group('paths', () {
    test('F14_A10 userDoc(uid).path equals users/<uid>', () {
      expect(service.userDoc('uid-1').path, 'users/uid-1');
    });

    test(
      'F14_A11 subcollection(uid, name, ...).path is always users/<uid>/<name>',
      () {
        for (final name in [
          'wardrobeItems',
          'outfits',
          'wearEvents',
          'plannedEntries',
          'packingTrips',
        ]) {
          final collection = service.subcollection<Map<String, dynamic>>(
            'uid-1',
            name,
            (data, id) => data,
            (value) => value,
          );
          expect(collection.path, 'users/uid-1/$name');
        }
      },
    );

    test(
      'F14_A12 toFirestore writes the doc id as a plain field in addition to the doc ID',
      () async {
        final collection = service.subcollection<_Thing>(
          'uid-1',
          'things',
          (data, id) => _Thing(id: id, name: data['name'] as String),
          (value) => {'id': value.id, 'name': value.name},
        );
        await collection.doc('thing-1').set(_Thing(id: 'thing-1', name: 'x'));

        final raw = await firestore
            .collection('users/uid-1/things')
            .doc('thing-1')
            .get();
        expect(raw.data()!['id'], 'thing-1');
      },
    );

    test(
      'F14_A13 fromFirestore trusts the real doc ID over a disagreeing stored id field',
      () async {
        await firestore.collection('users/uid-1/things').doc('real-id').set({
          'id': 'stale-id',
          'name': 'x',
        });

        final collection = service.subcollection<_Thing>(
          'uid-1',
          'things',
          (data, id) => _Thing(id: id, name: data['name'] as String),
          (value) => {'id': value.id, 'name': value.name},
        );
        final snapshot = await collection.doc('real-id').get();

        expect(snapshot.data()!.id, 'real-id');
      },
    );
  });

  group('runBootstrapIfNeeded', () {
    test(
      'F14_A15 missing seeded field invokes seedWriter exactly once and leaves seeded true',
      () async {
        var calls = 0;
        await service.runBootstrapIfNeeded('uid-1', (tx, userDoc) async {
          calls++;
        });

        expect(calls, 1);
        final snapshot = await service.userDoc('uid-1').get();
        expect(snapshot.data()!['seeded'], true);
      },
    );

    test(
      'F14_A16 explicit seeded:false behaves identically to a missing field',
      () async {
        await service
            .userDoc('uid-2')
            .set({'seeded': false}, SetOptions(merge: true));
        var calls = 0;

        await service.runBootstrapIfNeeded('uid-2', (tx, userDoc) async {
          calls++;
        });

        expect(calls, 1);
        final snapshot = await service.userDoc('uid-2').get();
        expect(snapshot.data()!['seeded'], true);
      },
    );

    test('F14_A17 seeded:true never invokes seedWriter', () async {
      await service
          .userDoc('uid-3')
          .set({'seeded': true}, SetOptions(merge: true));
      var calls = 0;

      await service.runBootstrapIfNeeded('uid-3', (tx, userDoc) async {
        calls++;
      });

      expect(calls, 0);
    });

    test(
      'F14_A18 two concurrent calls for the same brand-new uid invoke seedWriter exactly once',
      () async {
        var calls = 0;
        Future<void> writer(
          Transaction tx,
          DocumentReference<Map<String, dynamic>> userDoc,
        ) async {
          calls++;
        }

        await Future.wait([
          service.runBootstrapIfNeeded('uid-4', writer),
          service.runBootstrapIfNeeded('uid-4', writer),
        ]);

        expect(calls, 1);
        final snapshot = await service.userDoc('uid-4').get();
        expect(snapshot.data()!['seeded'], true);
      },
    );

    test(
      'F14_A19 a throwing seedWriter leaves seeded unset, so a retry invokes it again',
      () async {
        var calls = 0;

        await expectLater(
          service.runBootstrapIfNeeded('uid-5', (tx, userDoc) async {
            calls++;
            throw StateError('boom');
          }),
          throwsStateError,
        );

        var snapshot = await service.userDoc('uid-5').get();
        expect(snapshot.data()?['seeded'], isNot(true));

        await service.runBootstrapIfNeeded('uid-5', (tx, userDoc) async {
          calls++;
        });

        expect(calls, 2);
        snapshot = await service.userDoc('uid-5').get();
        expect(snapshot.data()!['seeded'], true);
      },
    );

    test(
      'F14_edge a uid whose user doc does not exist yet is treated as unseeded and the transaction creates it',
      () async {
        final existing = await service.userDoc('uid-6').get();
        expect(existing.exists, isFalse);

        await service.runBootstrapIfNeeded('uid-6', (tx, userDoc) async {});

        final after = await service.userDoc('uid-6').get();
        expect(after.exists, isTrue);
        expect(after.data()!['seeded'], true);
      },
    );
  });
}

class _Thing {
  _Thing({required this.id, required this.name});
  final String id;
  final String name;
}
