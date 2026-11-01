@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/firestore_values.dart';
import 'support/rules_test_client.dart';

const _alice = 'alice';
const _bob = 'bob';
const _eventId = 1730000000000;
const _eventPath = 'users/$_alice/wearEvents/$_eventId';
const _outfitPath = 'users/$_alice/outfits/1';

Map<String, Object?> _event({int id = _eventId, Object? outfitId = 1}) => {
  'id': id,
  'outfitId': outfitId,
  'name': 'Everyday Essential',
  'occasion': 'Everyday',
  'items': ['white-shirt', 'navy-chinos'],
  'timestamp': const TimestampValue('2026-10-20T10:00:00.000Z'),
};

Map<String, Object?> _outfit({int worn = 1}) => {
  'id': 1,
  'name': 'Everyday Essential',
  'occasion': 'Everyday',
  'why': 'why',
  'items': ['white-shirt', 'navy-chinos'],
  'worn': worn,
};

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 wearEvents', () {
    test('F22_A26 owner create succeeds, get/list succeed', () async {
      final result = await client.commit([client.fullSet(_eventPath, _event())], token: mockIdToken(_alice));
      expect(result.ok, isTrue, reason: result.body.toString());
      expect((await client.get(_eventPath, token: mockIdToken(_alice))).ok, isTrue);
      expect((await client.list('users/$_alice/wearEvents', token: mockIdToken(_alice))).ok, isTrue);
    });

    test('F22_A27 extra key denied', () async {
      for (final key in ['worn', 'date']) {
        final result = await client.commit(
          [client.fullSet(_eventPath, {..._event(), key: 'x'})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$key: ${result.body}');
      }
    });

    test('F22_A28 other uid denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_eventPath, _event())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_eventPath, token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/wearEvents', token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/wearEvents/2', _event(id: 2))], token: mockIdToken(_bob)))
            .isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.deleteDoc(_eventPath)], token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
    });

    test('F22_A29 signed out denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_eventPath, _event())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_eventPath)).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/wearEvents')).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/wearEvents/3', _event(id: 3))])).isPermissionDenied,
        isTrue,
      );
      expect((await client.commit([client.deleteDoc(_eventPath)])).isPermissionDenied, isTrue);
    });

    test('F22_A30 type checks', () async {
      Future<void> expectDenied(Map<String, Object?> overrides) async {
        final result = await client.commit(
          [client.fullSet(_eventPath, {..._event(), ...overrides})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$overrides -> ${result.body}');
      }

      await expectDenied({'timestamp': '2026-10-20T10:00:00Z'});
      await expectDenied({'timestamp': 1730000000000});
      await expectDenied({'items': 'white-shirt'});
      await expectDenied({'outfitId': '1'});
      await expectDenied({'id': _eventId + 1});
    });

    test('F22_A31 removeWear transaction shape succeeds atomically', () async {
      final seedOutfit = await client.commit([client.fullSet(_outfitPath, _outfit(worn: 1))], token: ownerToken);
      expect(seedOutfit.ok, isTrue);
      final seedEvent = await client.commit([client.fullSet(_eventPath, _event())], token: ownerToken);
      expect(seedEvent.ok, isTrue);

      final result = await client.commit(
        [
          client.deleteDoc(_eventPath),
          client.fullSet(_outfitPath, _outfit(worn: 0)),
        ],
        token: mockIdToken(_alice),
      );
      expect(result.ok, isTrue, reason: result.body.toString());
      expect((await client.get(_eventPath, token: ownerToken)).isNotFound, isTrue);
      expect((await client.get(_outfitPath, token: ownerToken)).fields['worn'], 0);
    });
  });
}
