@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';
const _bob = 'bob';
const _outfitPath = 'users/$_alice/outfits/1';

Map<String, Object?> _outfit({List<Object?> items = const ['white-shirt', 'navy-chinos', 'white-sneakers', 'black-watch'], int worn = 0}) => {
  'id': 1,
  'name': 'Everyday Essential',
  'occasion': 'Everyday',
  'why': 'A crisp oxford creates structure.',
  'items': items,
  'worn': worn,
};

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 outfits', () {
    test('F22_A19 owner create succeeds, items:[] also allowed', () async {
      final a = await client.commit([client.fullSet(_outfitPath, _outfit())], token: mockIdToken(_alice));
      expect(a.ok, isTrue, reason: a.body.toString());
      expect((await client.get(_outfitPath, token: mockIdToken(_alice))).ok, isTrue);
      expect((await client.list('users/$_alice/outfits', token: mockIdToken(_alice))).ok, isTrue);

      await client.clearData();
      final b = await client.commit(
        [client.fullSet(_outfitPath, _outfit(items: const []))],
        token: mockIdToken(_alice),
      );
      expect(b.ok, isTrue, reason: b.body.toString());
    });

    test('F22_A20 extra key denied', () async {
      for (final key in ['createdAt', 'wears']) {
        final result = await client.commit(
          [client.fullSet(_outfitPath, {..._outfit(), key: 'x'})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$key: ${result.body}');
      }
    });

    test('F22_A21 other uid denied on get/list/create/update/delete', () async {
      final seed = await client.commit([client.fullSet(_outfitPath, _outfit())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_outfitPath, token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/outfits', token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/outfits/2', _outfit())], token: mockIdToken(_bob)))
            .isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.mergeSet(_outfitPath, {'worn': 9})], token: mockIdToken(_bob)))
            .isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.deleteDoc(_outfitPath)], token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
    });

    test('F22_A22 signed out denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_outfitPath, _outfit())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_outfitPath)).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/outfits')).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/outfits/3', _outfit())])).isPermissionDenied,
        isTrue,
      );
      expect((await client.commit([client.deleteDoc(_outfitPath)])).isPermissionDenied, isTrue);
    });

    test('F22_A23 type/invariant checks', () async {
      Future<void> expectDenied(Map<String, Object?> overrides) async {
        final result = await client.commit(
          [client.fullSet(_outfitPath, {..._outfit(), ...overrides})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$overrides -> ${result.body}');
      }

      await expectDenied({'worn': -1});
      final okZero = await client.commit(
        [client.fullSet(_outfitPath, {..._outfit(), 'worn': 0})],
        token: mockIdToken(_alice),
      );
      expect(okZero.ok, isTrue, reason: okZero.body.toString());

      await expectDenied({'items': 'a,b'});
      await expectDenied({'id': '1'});
      await expectDenied({'why': null});

      final wrongId = await client.commit(
        [client.fullSet(_outfitPath, {..._outfit(), 'id': 2})],
        token: mockIdToken(_alice),
      );
      expect(wrongId.isPermissionDenied, isTrue, reason: wrongId.body.toString());
    });

    test('F22_A24 upsertManual update path: not-found vs permission-denied', () async {
      final seed = await client.commit([client.fullSet(_outfitPath, _outfit(worn: 3))], token: ownerToken);
      expect(seed.ok, isTrue);

      final update = await client.commit(
        [client.updateExisting(_outfitPath, {'name': 'Renamed', 'occasion': 'Casual', 'items': ['white-shirt']})],
        token: mockIdToken(_alice),
      );
      expect(update.ok, isTrue, reason: update.body.toString());
      final after = await client.get(_outfitPath, token: ownerToken);
      expect(after.fields['worn'], 3);

      const missingPath = 'users/$_alice/outfits/999';
      final missingUpdate = await client.commit(
        [client.updateExisting(missingPath, {'name': 'X', 'occasion': 'Y', 'items': <String>[]})],
        token: mockIdToken(_alice),
      );
      expect(missingUpdate.isNotFound, isTrue, reason: missingUpdate.body.toString());

      final fallbackSet = await client.commit(
        [client.fullSet(missingPath, _outfit()..['id'] = 999)],
        token: mockIdToken(_alice),
      );
      expect(fallbackSet.ok, isTrue, reason: fallbackSet.body.toString());
    });

    test('F22_A25 owner delete succeeds', () async {
      final seed = await client.commit([client.fullSet(_outfitPath, _outfit())], token: ownerToken);
      expect(seed.ok, isTrue);
      final delete = await client.commit([client.deleteDoc(_outfitPath)], token: mockIdToken(_alice));
      expect(delete.ok, isTrue, reason: delete.body.toString());
      expect((await client.get(_outfitPath, token: ownerToken)).isNotFound, isTrue);
    });
  });
}
