@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';
const _bob = 'bob';
const _itemPath = 'users/$_alice/wardrobeItems/white-shirt';

Map<String, Object?> _seedItem({Object? sourceId, Object? imageUrl}) => {
  'id': 'white-shirt',
  'name': 'White Oxford Shirt',
  'category': 'Shirts',
  'color': 'White',
  'occasion': 'Office',
  'season': 'All season',
  'wears': 0,
  'sourceId': sourceId,
  'imageUrl': imageUrl,
};

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 wardrobeItems', () {
    test('F22_A13 owner create succeeds for null/explicit/absent/empty variants', () async {
      final a = await client.commit(
        [client.fullSet(_itemPath, _seedItem())],
        token: mockIdToken(_alice),
      );
      expect(a.ok, isTrue, reason: a.body.toString());
      final readA = await client.get(_itemPath, token: mockIdToken(_alice));
      expect(readA.fields['sourceId'], isNull);
      expect(readA.fields['imageUrl'], isNull);
      final list = await client.list('users/$_alice/wardrobeItems', token: mockIdToken(_alice));
      expect(list.ok, isTrue);

      await client.clearData();
      final b = await client.commit(
        [client.fullSet(_itemPath, _seedItem(sourceId: 'white-shirt', imageUrl: 'alice/white-shirt.jpg'))],
        token: mockIdToken(_alice),
      );
      expect(b.ok, isTrue, reason: b.body.toString());

      await client.clearData();
      final noKeys = {..._seedItem()}..removeWhere((key, value) => key == 'sourceId' || key == 'imageUrl');
      final c = await client.commit(
        [client.fullSet(_itemPath, noKeys)],
        token: mockIdToken(_alice),
      );
      expect(c.ok, isTrue, reason: c.body.toString());

      await client.clearData();
      final d = await client.commit(
        [client.fullSet(_itemPath, _seedItem(imageUrl: ''))],
        token: mockIdToken(_alice),
      );
      expect(d.ok, isTrue, reason: d.body.toString());
      final readD = await client.get(_itemPath, token: mockIdToken(_alice));
      expect(readD.fields['imageUrl'], '');
    });

    test('F22_A14 extra key denied', () async {
      for (final extraKey in ['imageId', 'price', 'items']) {
        final result = await client.commit(
          [client.fullSet(_itemPath, {..._seedItem(), extraKey: 'x'})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: 'extra key $extraKey: ${result.body}');
      }
    });

    test('F22_A15 other uid denied on get/list/create/update/delete', () async {
      final seed = await client.commit(
        [client.fullSet(_itemPath, _seedItem())],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      expect((await client.get(_itemPath, token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect(
        (await client.list('users/$_alice/wardrobeItems', token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit(
          [client.fullSet('users/$_alice/wardrobeItems/bob-item', _seedItem())],
          token: mockIdToken(_bob),
        )).isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit(
          [client.mergeSet(_itemPath, {'wears': 5})],
          token: mockIdToken(_bob),
        )).isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.deleteDoc(_itemPath)], token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
    });

    test('F22_A16 signed out denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_itemPath, _seedItem())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_itemPath)).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/wardrobeItems')).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/wardrobeItems/x', _seedItem())])).isPermissionDenied,
        isTrue,
      );
      expect((await client.commit([client.deleteDoc(_itemPath)])).isPermissionDenied, isTrue);
    });

    test('F22_A17 type/invariant checks', () async {
      Future<void> expectDenied(Map<String, Object?> overrides) async {
        final result = await client.commit(
          [client.fullSet(_itemPath, {..._seedItem(), ...overrides})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$overrides -> ${result.body}');
      }

      await expectDenied({'wears': -1});
      final allowedZero = await client.commit(
        [client.fullSet(_itemPath, {..._seedItem(), 'wears': 0})],
        token: mockIdToken(_alice),
      );
      expect(allowedZero.ok, isTrue, reason: allowedZero.body.toString());

      await expectDenied({'wears': 1.5});
      await expectDenied({'wears': '3'});
      await expectDenied({'id': 'other-id'});
      await expectDenied({'sourceId': 5});
      await expectDenied({'name': null});
    });

    test('F22_A18 owner delete succeeds and document no longer exists', () async {
      final seed = await client.commit([client.fullSet(_itemPath, _seedItem())], token: ownerToken);
      expect(seed.ok, isTrue);

      final delete = await client.commit([client.deleteDoc(_itemPath)], token: mockIdToken(_alice));
      expect(delete.ok, isTrue, reason: delete.body.toString());

      final after = await client.get(_itemPath, token: ownerToken);
      expect(after.isNotFound, isTrue);
    });
  });
}
