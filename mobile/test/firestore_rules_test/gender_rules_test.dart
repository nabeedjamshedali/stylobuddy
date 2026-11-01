@Tags(['firestore-rules'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/calendar/repository/firestore_planner_repository.dart';
import 'package:stylobuddy/features/saved/repository/firestore_outfits_repository.dart';
import 'package:stylobuddy/features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';

/// F22-A07's 13-key bootstrap payload.
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

/// F22-A47's 27-write D5 bootstrap, with [gender] added to users/alice.
List<Map<String, dynamic>> _bootstrapWrites(RulesTestClient client, Object? gender) {
  final writes = <Map<String, dynamic>>[
    client.fullSet('users/$_alice', {..._bootstrapPayload(), 'gender': gender}),
  ];
  for (final item in SeedData.items) {
    writes.add(
      client.fullSet(
        'users/$_alice/wardrobeItems/${item.id}',
        FirestoreWardrobeRepository.seedFieldsFor(item),
      ),
    );
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
      client.fullSet(
        'users/$_alice/plannedEntries/$key',
        FirestorePlannerRepository.seedFieldsFor(entry),
      ),
    );
  });
  return writes;
}

List<String> _bootstrapPaths() => [
  'users/$_alice',
  for (final item in SeedData.items) 'users/$_alice/wardrobeItems/${item.id}',
  for (final outfit in SeedData.outfits) 'users/$_alice/outfits/${outfit.id}',
  for (final key in SeedData.planned.keys) 'users/$_alice/plannedEntries/$key',
];

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  Future<void> seedValidProfile() async {
    final seed = await client.commit(
      [client.fullSet('users/$_alice', _bootstrapPayload())],
      token: ownerToken,
    );
    expect(seed.ok, isTrue, reason: seed.body.toString());
  }

  group('F24 users/{uid}.gender rules', () {
    test('F24_A36 male/female allowed on create and merge; 13-key create still allowed', () async {
      for (final gender in ['female', 'male']) {
        await client.clearData();
        final payload = {..._bootstrapPayload(), 'gender': gender};
        final write = await client.commit(
          [client.fullSet('users/$_alice', payload)],
          token: mockIdToken(_alice),
        );
        expect(write.ok, isTrue, reason: '$gender ${write.body}');
        final read = await client.get('users/$_alice', token: mockIdToken(_alice));
        expect(read.ok, isTrue);
        expect(read.fields, payload);
      }

      await client.clearData();
      await seedValidProfile();
      final merge = await client.commit(
        [client.mergeSet('users/$_alice', {'gender': 'female'})],
        token: mockIdToken(_alice),
      );
      expect(merge.ok, isTrue, reason: merge.body.toString());

      await client.clearData();
      final plain = await client.commit(
        [client.fullSet('users/$_alice', _bootstrapPayload())],
        token: mockIdToken(_alice),
      );
      expect(plain.ok, isTrue, reason: plain.body.toString());
    });

    test('F24_A37 invalid gender values denied as merge and in a full create, each paired with an allowed case', () async {
      for (final bad in <Object?>['other', '', 'Female', null, 1]) {
        // Merge-set onto a valid document: denied; paired allowed merge.
        await client.clearData();
        await seedValidProfile();
        final denied = await client.commit(
          [client.mergeSet('users/$_alice', {'gender': bad})],
          token: mockIdToken(_alice),
        );
        expect(denied.isPermissionDenied, isTrue, reason: 'merge $bad ${denied.body}');
        final allowed = await client.commit(
          [client.mergeSet('users/$_alice', {'gender': 'female'})],
          token: mockIdToken(_alice),
        );
        expect(allowed.ok, isTrue, reason: 'paired merge for $bad ${allowed.body}');

        // Full 13-key create with the bad value: denied; paired allowed create.
        await client.clearData();
        final deniedCreate = await client.commit(
          [client.fullSet('users/$_alice', {..._bootstrapPayload(), 'gender': bad})],
          token: mockIdToken(_alice),
        );
        expect(deniedCreate.isPermissionDenied, isTrue, reason: 'create $bad ${deniedCreate.body}');
        final allowedCreate = await client.commit(
          [client.fullSet('users/$_alice', {..._bootstrapPayload(), 'gender': 'male'})],
          token: mockIdToken(_alice),
        );
        expect(allowedCreate.ok, isTrue, reason: 'paired create for $bad ${allowedCreate.body}');
      }
    });

    test('F24_A38 27-write bootstrap with gender female commits; with other it is denied whole', () async {
      final writes = _bootstrapWrites(client, 'female');
      expect(writes.length, 27);
      final ok = await client.commit(writes, token: mockIdToken(_alice));
      expect(ok.ok, isTrue, reason: ok.body.toString());
      for (final path in _bootstrapPaths()) {
        final doc = await client.get(path, token: ownerToken);
        expect(doc.ok, isTrue, reason: 'missing $path');
      }
      final profile = await client.get('users/$_alice', token: ownerToken);
      expect(profile.fields['seeded'], isTrue);
      expect(profile.fields['gender'], 'female');

      await client.clearData();
      final denied = await client.commit(
        _bootstrapWrites(client, 'other'),
        token: mockIdToken(_alice),
      );
      expect(denied.isPermissionDenied, isTrue, reason: denied.body.toString());
      var existing = 0;
      for (final path in _bootstrapPaths()) {
        final doc = await client.get(path, token: ownerToken);
        if (!doc.isNotFound) existing++;
      }
      expect(existing, 0, reason: '0 of 27 documents may exist');
    });
  });
}
