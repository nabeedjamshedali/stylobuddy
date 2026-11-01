@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/saved/repository/firestore_outfits_repository.dart';
import 'package:stylobuddy/features/calendar/repository/firestore_planner_repository.dart';
import 'package:stylobuddy/features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';

Map<String, Object?> _profilePayload() => {
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

/// The real D5 bootstrap's 27 writes (F22_A47), built from the real
/// repositories' public `seedFieldsFor*` wrappers so this test exercises the
/// exact field maps the app writes, not a hand-copied approximation.
List<Map<String, dynamic>> _bootstrapWrites(RulesTestClient client, {String? extraKeyOnItemId}) {
  final writes = <Map<String, dynamic>>[
    client.fullSet('users/$_alice', _profilePayload()),
  ];
  for (final item in SeedData.items) {
    final fields = FirestoreWardrobeRepository.seedFieldsFor(item);
    if (item.id == extraKeyOnItemId) {
      fields['legacyFlag'] = true;
    }
    writes.add(client.fullSet('users/$_alice/wardrobeItems/${item.id}', fields));
  }
  for (final outfit in SeedData.outfits) {
    writes.add(
      client.fullSet(
        'users/$_alice/outfits/${outfit.id}',
        FirestoreOutfitsRepository.seedFieldsForOutfit(outfit),
      ),
    );
  }
  SeedData.planned.forEach((key, entry) {
    writes.add(
      client.fullSet('users/$_alice/plannedEntries/$key', FirestorePlannerRepository.seedFieldsFor(entry)),
    );
  });
  return writes;
}

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 bootstrap + legacy data', () {
    test('F22_A47 D5 bootstrap commits as one transaction; all 27 docs present', () async {
      final writes = _bootstrapWrites(client);
      expect(writes.length, 1 + 23 + 2 + 1);

      final result = await client.commit(writes, token: mockIdToken(_alice));
      expect(result.ok, isTrue, reason: result.body.toString());

      final profile = await client.get('users/$_alice', token: ownerToken);
      expect(profile.fields['seeded'], isTrue);

      for (final item in SeedData.items) {
        final doc = await client.get('users/$_alice/wardrobeItems/${item.id}', token: ownerToken);
        expect(doc.ok, isTrue, reason: 'missing wardrobeItems/${item.id}');
      }
      for (final outfit in SeedData.outfits) {
        final doc = await client.get('users/$_alice/outfits/${outfit.id}', token: ownerToken);
        expect(doc.ok, isTrue, reason: 'missing outfits/${outfit.id}');
      }
      for (final key in SeedData.planned.keys) {
        final doc = await client.get('users/$_alice/plannedEntries/$key', token: ownerToken);
        expect(doc.ok, isTrue, reason: 'missing plannedEntries/$key');
      }
    });

    test('F22_A47 one wardrobe doc with an extra key denies the whole commit', () async {
      final badItemId = SeedData.items.first.id;
      final writes = _bootstrapWrites(client, extraKeyOnItemId: badItemId);

      final result = await client.commit(writes, token: mockIdToken(_alice));
      expect(result.isPermissionDenied, isTrue, reason: result.body.toString());

      final profile = await client.get('users/$_alice', token: ownerToken);
      expect(profile.isNotFound, isTrue);
      expect(profile.fields['seeded'], isNot(isTrue));

      for (final item in SeedData.items) {
        final doc = await client.get('users/$_alice/wardrobeItems/${item.id}', token: ownerToken);
        expect(doc.isNotFound, isTrue, reason: 'wardrobeItems/${item.id} should not exist');
      }
      for (final outfit in SeedData.outfits) {
        final doc = await client.get('users/$_alice/outfits/${outfit.id}', token: ownerToken);
        expect(doc.isNotFound, isTrue, reason: 'outfits/${outfit.id} should not exist');
      }
      for (final key in SeedData.planned.keys) {
        final doc = await client.get('users/$_alice/plannedEntries/$key', token: ownerToken);
        expect(doc.isNotFound, isTrue, reason: 'plannedEntries/$key should not exist');
      }
    });

    test('F22_A48 legacy out-of-schema key blocks later valid writes under strict hasOnly', () async {
      final legacyProfile = {..._profilePayload(), 'legacyFlag': true};
      final seed = await client.commit([client.fullSet('users/$_alice', legacyProfile)], token: ownerToken);
      expect(seed.ok, isTrue);

      final validMerge = await client.commit(
        [client.mergeSet('users/$_alice', {'climate': 'Mild'})],
        token: mockIdToken(_alice),
      );
      expect(validMerge.isPermissionDenied, isTrue, reason: validMerge.body.toString());

      // The bootstrap's own `...existingData` spread (FirestoreService
      // ._runBootstrap) replays the same shape here: it would write
      // `legacyFlag` straight back onto the document, which the strict
      // full-document `hasOnly` check rejects (§13 Q3, option (a)).
      final spreadBootstrap = await client.commit(
        [client.mergeSet('users/$_alice', {...legacyProfile, 'seeded': true})],
        token: mockIdToken(_alice),
      );
      expect(spreadBootstrap.isPermissionDenied, isTrue, reason: spreadBootstrap.body.toString());
    });
  });
}
