@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';
const _bob = 'bob';

Map<String, Object?> _bootstrapPayload() => {
  'name': '',
  'email': '',
  'styles': <String>[],
  'occasions': ['Everyday', 'Casual', 'Office'],
  'dailyNotifications': true,
  'plannedNotifications': true,
  'productNotifications': false,
  'weatherConsent': false,
  'climate': 'Mild',
  'plan': 'free',
  'billingCycle': 'monthly',
  'wishlist': <String>[],
  'seeded': true,
};

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 users/{uid} profile', () {
    test('F22_A07 owner create with all 13 allowed keys succeeds and reads back', () async {
      final payload = _bootstrapPayload();
      final write = await client.commit(
        [client.fullSet('users/$_alice', payload)],
        token: mockIdToken(_alice),
      );
      expect(write.ok, isTrue, reason: write.body.toString());

      final read = await client.get('users/$_alice', token: mockIdToken(_alice));
      expect(read.ok, isTrue);
      expect(read.fields, payload);
    });

    test('F22_A08 extra key denied as full create and as one-key merge', () async {
      final full = await client.commit(
        [client.fullSet('users/$_alice', {..._bootstrapPayload(), 'isAdmin': true})],
        token: mockIdToken(_alice),
      );
      expect(full.isPermissionDenied, isTrue, reason: full.body.toString());

      final seed = await client.commit(
        [client.fullSet('users/$_alice', _bootstrapPayload())],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      final merge = await client.commit(
        [client.mergeSet('users/$_alice', {'isAdmin': true})],
        token: mockIdToken(_alice),
      );
      expect(merge.isPermissionDenied, isTrue, reason: merge.body.toString());
    });

    test('F22_A09 other uid get and merge-set denied, document unchanged', () async {
      final seed = await client.commit(
        [client.fullSet('users/$_alice', _bootstrapPayload())],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      final get = await client.get('users/$_alice', token: mockIdToken(_bob));
      expect(get.isPermissionDenied, isTrue);

      final write = await client.commit(
        [client.mergeSet('users/$_alice', {'climate': 'Hot'})],
        token: mockIdToken(_bob),
      );
      expect(write.isPermissionDenied, isTrue);

      final after = await client.get('users/$_alice', token: ownerToken);
      expect(after.fields['climate'], 'Mild');
    });

    test('F22_A10 signed out get and merge-set denied', () async {
      final seed = await client.commit(
        [client.fullSet('users/$_alice', _bootstrapPayload())],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      final get = await client.get('users/$_alice');
      expect(get.isPermissionDenied, isTrue);

      final write = await client.commit([
        client.mergeSet('users/$_alice', {'climate': 'Hot'}),
      ]);
      expect(write.isPermissionDenied, isTrue);
    });

    test('F22_A11 partial profile documents allowed on a non-existent doc', () async {
      final merge = await client.commit(
        [client.mergeSet('users/$_alice', {'styles': ['Casual']})],
        token: mockIdToken(_alice),
      );
      expect(merge.ok, isTrue, reason: merge.body.toString());
      final after = await client.get('users/$_alice', token: ownerToken);
      expect(after.fields, {'styles': ['Casual']});

      await client.clearData();
      final union = await client.commit(
        [client.arrayTransform('users/$_alice', 'wishlist', union: ['shop-1'])],
        token: mockIdToken(_alice),
      );
      expect(union.ok, isTrue, reason: union.body.toString());

      final remove = await client.commit(
        [client.arrayTransform('users/$_alice', 'wishlist', remove: ['absent-id'])],
        token: mockIdToken(_alice),
      );
      expect(remove.ok, isTrue, reason: remove.body.toString());
    });

    test('F22_A12 profile type checks: denied cases', () async {
      final seed = await client.commit(
        [client.fullSet('users/$_alice', _bootstrapPayload())],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      final deniedPatches = <Map<String, Object?>>[
        {'dailyNotifications': 'yes'},
        {'seeded': 1},
        {'styles': 'Casual'},
        {'wishlist': 'shop-1'},
        {'name': 7},
        {'name': null},
        {'styles': null},
      ];
      for (final patch in deniedPatches) {
        final result = await client.commit(
          [client.mergeSet('users/$_alice', patch)],
          token: mockIdToken(_alice),
        );
        expect(
          result.isPermissionDenied,
          isTrue,
          reason: 'patch $patch should be denied, got ${result.body}',
        );
      }
    });

    test('F22_A12 missing vs empty vs null are three distinct outcomes', () async {
      final seed = await client.commit(
        [client.fullSet('users/$_alice', _bootstrapPayload())],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      for (final patch in <Map<String, Object?>>[
        {'styles': <String>[]},
        {'wishlist': <String>[]},
        {'name': ''},
      ]) {
        final result = await client.commit(
          [client.mergeSet('users/$_alice', patch)],
          token: mockIdToken(_alice),
        );
        expect(result.ok, isTrue, reason: 'patch $patch should be allowed, got ${result.body}');
      }

      await client.clearData();
      final noStyles = await client.commit(
        [client.mergeSet('users/$_alice', {'climate': 'Hot'})],
        token: mockIdToken(_alice),
      );
      expect(noStyles.ok, isTrue);

      final nullStyles = await client.commit(
        [client.mergeSet('users/$_alice', {'styles': null})],
        token: mockIdToken(_alice),
      );
      expect(nullStyles.isPermissionDenied, isTrue);
    });
  });
}
