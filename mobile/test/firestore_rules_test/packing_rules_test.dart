@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/firestore_values.dart';
import 'support/rules_test_client.dart';

const _alice = 'alice';
const _bob = 'bob';
const _tripPath = 'users/$_alice/packingTrips/trip-1';

Map<String, Object?> _item({required String key, Object? wardrobeId}) =>
    {'key': key, 'label': key, 'wardrobeId': wardrobeId, 'packed': false};

Map<String, Object?> _trip({List<Object?> items = const [], int days = 3}) => {
  'id': 'trip-1',
  'name': 'Weekend',
  'destination': 'Lahore',
  'start': '2026-11-01',
  'end': '2026-11-03',
  'type': 'Leisure',
  'notes': '',
  'days': days,
  'items': items,
};

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 packingTrips', () {
    test('F22_A38 owner create succeeds for items:[] and mixed wardrobeId', () async {
      final a = await client.commit([client.fullSet(_tripPath, _trip())], token: mockIdToken(_alice));
      expect(a.ok, isTrue, reason: a.body.toString());
      expect((await client.get(_tripPath, token: mockIdToken(_alice))).ok, isTrue);
      expect((await client.list('users/$_alice/packingTrips', token: mockIdToken(_alice))).ok, isTrue);

      await client.clearData();
      final items = [
        _item(key: 'white-shirt', wardrobeId: 'white-shirt'),
        _item(key: 'extra-1', wardrobeId: null),
      ];
      final b = await client.commit(
        [client.fullSet(_tripPath, _trip(items: items))],
        token: mockIdToken(_alice),
      );
      expect(b.ok, isTrue, reason: b.body.toString());
    });

    test('F22_A39 extra key denied', () async {
      for (final key in ['draft', 'selectedTripId']) {
        final result = await client.commit(
          [client.fullSet(_tripPath, {..._trip(), key: 'x'})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$key: ${result.body}');
      }
    });

    test('F22_A40 other uid denied on get/list/create/update/delete', () async {
      final seed = await client.commit([client.fullSet(_tripPath, _trip())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_tripPath, token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/packingTrips', token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/packingTrips/trip-2', _trip())], token: mockIdToken(_bob)))
            .isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.mergeSet(_tripPath, {'days': 5})], token: mockIdToken(_bob)))
            .isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.deleteDoc(_tripPath)], token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
    });

    test('F22_A41 signed out denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_tripPath, _trip())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_tripPath)).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/packingTrips')).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/packingTrips/trip-3', _trip())])).isPermissionDenied,
        isTrue,
      );
      expect((await client.commit([client.deleteDoc(_tripPath)])).isPermissionDenied, isTrue);
    });

    test('F22_A42 type/invariant checks', () async {
      Future<void> expectDenied(Map<String, Object?> overrides) async {
        final result = await client.commit(
          [client.fullSet(_tripPath, {..._trip(), ...overrides})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$overrides -> ${result.body}');
      }

      await expectDenied({'days': 0});
      final okOne = await client.commit(
        [client.fullSet(_tripPath, {..._trip(), 'days': 1})],
        token: mockIdToken(_alice),
      );
      expect(okOne.ok, isTrue, reason: okOne.body.toString());

      await expectDenied({'days': '3'});
      await expectDenied({'items': 'x'});
      await expectDenied({'start': const TimestampValue('2026-11-01T00:00:00.000Z')});
      await expectDenied({'id': 'trip-2'});
    });

    test('F22_A43 saveTrip edit-branch merge-set excluding items', () async {
      final seedItems = [_item(key: 'white-shirt', wardrobeId: 'white-shirt')];
      final seed = await client.commit([client.fullSet(_tripPath, _trip(items: seedItems))], token: ownerToken);
      expect(seed.ok, isTrue);

      final editFields = {
        'id': 'trip-1',
        'name': 'Weekend (updated)',
        'destination': 'Lahore',
        'start': '2026-11-01',
        'end': '2026-11-04',
        'type': 'Leisure',
        'notes': 'Pack light',
        'days': 4,
      };
      final edit = await client.commit([client.mergeSet(_tripPath, editFields)], token: mockIdToken(_alice));
      expect(edit.ok, isTrue, reason: edit.body.toString());
      final after = await client.get(_tripPath, token: ownerToken);
      expect(after.fields['items'], seedItems);

      const missingPath = 'users/$_alice/packingTrips/trip-missing';
      final editMissing = {...editFields, 'id': 'trip-missing'};
      final onMissing = await client.commit([client.mergeSet(missingPath, editMissing)], token: mockIdToken(_alice));
      expect(onMissing.ok, isTrue, reason: onMissing.body.toString());
      final afterMissing = await client.get(missingPath, token: ownerToken);
      expect(afterMissing.fields.containsKey('items'), isFalse);
    });

    test('F22_A44 _mutateItems transaction shape succeeds', () async {
      final seed = await client.commit([client.fullSet(_tripPath, _trip())], token: ownerToken);
      expect(seed.ok, isTrue);

      final newItems = [_item(key: 'extra-1')];
      final result = await client.commit(
        [client.updateExisting(_tripPath, {'items': newItems})],
        token: mockIdToken(_alice),
      );
      expect(result.ok, isTrue, reason: result.body.toString());
      final after = await client.get(_tripPath, token: ownerToken);
      expect(after.fields['items'], newItems);
    });

    test('F22_A45 owner delete succeeds', () async {
      final seed = await client.commit([client.fullSet(_tripPath, _trip())], token: ownerToken);
      expect(seed.ok, isTrue);
      final delete = await client.commit([client.deleteDoc(_tripPath)], token: mockIdToken(_alice));
      expect(delete.ok, isTrue, reason: delete.body.toString());
      expect((await client.get(_tripPath, token: ownerToken)).isNotFound, isTrue);
    });
  });
}
