@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';
const _bob = 'bob';
const _dateKey = '2026-10-15';
const _entryPath = 'users/$_alice/plannedEntries/$_dateKey';

Map<String, Object?> _entry({Object? outfitId = 1, Object? occasion = 'Everyday'}) =>
    {'outfitId': outfitId, 'occasion': occasion};

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 plannedEntries', () {
    test('F22_A32 owner create succeeds, get/list succeed', () async {
      final result = await client.commit([client.fullSet(_entryPath, _entry())], token: mockIdToken(_alice));
      expect(result.ok, isTrue, reason: result.body.toString());
      expect((await client.get(_entryPath, token: mockIdToken(_alice))).ok, isTrue);
      expect((await client.list('users/$_alice/plannedEntries', token: mockIdToken(_alice))).ok, isTrue);
    });

    test('F22_A33 extra key denied', () async {
      for (final key in ['date', 'id']) {
        final result = await client.commit(
          [client.fullSet(_entryPath, {..._entry(), key: 'x'})],
          token: mockIdToken(_alice),
        );
        expect(result.isPermissionDenied, isTrue, reason: '$key: ${result.body}');
      }
    });

    test('F22_A34 other uid denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_entryPath, _entry())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_entryPath, token: mockIdToken(_bob))).isPermissionDenied, isTrue);
      expect(
        (await client.list('users/$_alice/plannedEntries', token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit(
          [client.fullSet('users/$_alice/plannedEntries/2026-10-16', _entry())],
          token: mockIdToken(_bob),
        )).isPermissionDenied,
        isTrue,
      );
      expect(
        (await client.commit([client.deleteDoc(_entryPath)], token: mockIdToken(_bob))).isPermissionDenied,
        isTrue,
      );
    });

    test('F22_A35 signed out denied on get/list/create/delete', () async {
      final seed = await client.commit([client.fullSet(_entryPath, _entry())], token: ownerToken);
      expect(seed.ok, isTrue);

      expect((await client.get(_entryPath)).isPermissionDenied, isTrue);
      expect((await client.list('users/$_alice/plannedEntries')).isPermissionDenied, isTrue);
      expect(
        (await client.commit([client.fullSet('users/$_alice/plannedEntries/2026-10-17', _entry())]))
            .isPermissionDenied,
        isTrue,
      );
      expect((await client.commit([client.deleteDoc(_entryPath)])).isPermissionDenied, isTrue);
    });

    test('F22_A36 type/key checks', () async {
      final badOutfitId = await client.commit(
        [client.fullSet(_entryPath, _entry(outfitId: '1'))],
        token: mockIdToken(_alice),
      );
      expect(badOutfitId.isPermissionDenied, isTrue, reason: badOutfitId.body.toString());

      final nullOccasion = await client.commit(
        [client.fullSet(_entryPath, _entry(occasion: null))],
        token: mockIdToken(_alice),
      );
      expect(nullOccasion.isPermissionDenied, isTrue, reason: nullOccasion.body.toString());

      final badDocId1 = await client.commit(
        [client.fullSet('users/$_alice/plannedEntries/2026-1-5', _entry())],
        token: mockIdToken(_alice),
      );
      expect(badDocId1.isPermissionDenied, isTrue, reason: badDocId1.body.toString());

      final badDocId2 = await client.commit(
        [client.fullSet('users/$_alice/plannedEntries/tomorrow', _entry())],
        token: mockIdToken(_alice),
      );
      expect(badDocId2.isPermissionDenied, isTrue, reason: badDocId2.body.toString());
    });

    test('F22_A37 owner delete succeeds', () async {
      final seed = await client.commit([client.fullSet(_entryPath, _entry())], token: ownerToken);
      expect(seed.ok, isTrue);
      final delete = await client.commit([client.deleteDoc(_entryPath)], token: mockIdToken(_alice));
      expect(delete.ok, isTrue, reason: delete.body.toString());
      expect((await client.get(_entryPath, token: ownerToken)).isNotFound, isTrue);
    });
  });
}
