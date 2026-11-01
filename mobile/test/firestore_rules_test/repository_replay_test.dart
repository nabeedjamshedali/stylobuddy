@Tags(['firestore-rules'])
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/calendar/repository/firestore_planner_repository.dart';
import 'package:stylobuddy/features/packing/models/packing_item.dart';
import 'package:stylobuddy/features/packing/models/trip.dart';
import 'package:stylobuddy/features/packing/repository/firestore_packing_repository.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/features/saved/repository/firestore_outfits_repository.dart';
import 'package:stylobuddy/features/shopping/repository/firestore_shopping_repository.dart';
import 'package:stylobuddy/features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';
import 'package:stylobuddy/shared/models/outfit.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';
import 'package:stylobuddy/shared/models/wear_event.dart';

import 'support/firestore_values.dart';
import 'support/rules_test_client.dart';

const _alice = 'alice';

/// Converts a raw value read back from `fake_cloud_firestore` (which may
/// contain real `Timestamp`/`List`/`Map` instances) into the shape
/// [RulesTestClient]'s write builders understand.
Object? _toReplayValue(Object? value) {
  if (value is Timestamp) {
    return TimestampValue(value.toDate().toUtc().toIso8601String());
  }
  if (value is List) return value.map(_toReplayValue).toList();
  if (value is Map) {
    return value.map((key, v) => MapEntry(key as String, _toReplayValue(v)));
  }
  return value;
}

Map<String, Object?> _replayFields(Map<String, dynamic> raw) =>
    raw.map((key, value) => MapEntry(key, _toReplayValue(value)));

Future<Map<String, dynamic>> _rawDoc(FakeFirebaseFirestore fake, String path) async {
  final snap = await fake.doc(path).get();
  return snap.data() ?? (throw StateError('missing doc at $path'));
}

/// Replays a document's current state as a full owner write, and asserts the
/// rules allow it (F22_A46: "rules not stricter than the real code").
Future<void> _expectAllowedFullSet(
  RulesTestClient client,
  FakeFirebaseFirestore fake,
  String path, {
  String label = '',
}) async {
  final raw = await _rawDoc(fake, path);
  final result = await client.commit(
    [client.fullSet(path, _replayFields(raw))],
    token: mockIdToken(_alice),
  );
  expect(result.ok, isTrue, reason: '$label full-set replay of $path denied: ${result.body}');
}

/// Replays a merge-set (`.set(value, SetOptions(merge: true))`) using the
/// FULL current post-write document from `fake_cloud_firestore` as the
/// field set — never a hand-picked subset of keys. `request.resource.data`
/// in the rules is the complete resultant document either way (merge
/// semantics only affect which keys Firestore writes, not what the rule
/// sees), so replaying every real key preserves the merge *operation kind*
/// (relevant to other, dedicated assertions) while making it impossible for
/// a stray key the real repository call wrote to be silently dropped from
/// the replay the way a hard-coded key list could (the bug this guards
/// against).
Future<void> _expectAllowedMergeSet(
  RulesTestClient client,
  FakeFirebaseFirestore fake,
  String path, {
  String label = '',
}) async {
  final raw = await _rawDoc(fake, path);
  final result = await client.commit(
    [client.mergeSet(path, _replayFields(raw))],
    token: mockIdToken(_alice),
  );
  expect(result.ok, isTrue, reason: '$label merge-set replay of $path denied: ${result.body}');
}

/// Same as [_expectAllowedMergeSet] but for `.update(fields)` (requires the
/// document to already exist) — replays the full current document, not a
/// hand-picked key subset, for the same reason.
Future<void> _expectAllowedUpdateExisting(
  RulesTestClient client,
  FakeFirebaseFirestore fake,
  String path, {
  String label = '',
}) async {
  final raw = await _rawDoc(fake, path);
  final result = await client.commit(
    [client.updateExisting(path, _replayFields(raw))],
    token: mockIdToken(_alice),
  );
  expect(result.ok, isTrue, reason: '$label update replay of $path denied: ${result.body}');
}

Future<void> _expectAllowedDelete(RulesTestClient client, String path, {String label = ''}) async {
  final result = await client.commit([client.deleteDoc(path)], token: mockIdToken(_alice));
  expect(result.ok, isTrue, reason: '$label delete replay of $path denied: ${result.body}');
}

/// Enumerates the public, `Future`-returning write methods declared on a
/// repository source file (excludes private helpers and `watch*`
/// Stream-returning reads) — the static half of F22_A46b: the method list
/// this test replays must equal this set, so a future write method can't go
/// silently uncovered.
Set<String> _publicFutureMethods(String path) {
  final content = File(path).readAsStringSync();
  // Anchored at exactly 2-space class-member indentation (method
  // declarations), so a `Future<void> Function(...)` *parameter type*
  // nested deeper inside a method's own parameter list (e.g.
  // ProfileRepository.bootstrapIfNeeded's `seedWriter`) is never mistaken
  // for a method named "Function".
  final matches = RegExp(
    r'^ {2}Future<[^(\n]*>\s+(\w+)\(',
    multiLine: true,
  ).allMatches(content);
  return {
    for (final m in matches)
      if (!m.group(1)!.startsWith('_')) m.group(1)!,
  };
}

void main() {
  late RulesTestClient client;
  late FakeFirebaseFirestore fake;
  late FirestoreService service;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
    fake = FakeFirebaseFirestore();
    service = FirestoreService(firestore: fake);
  });

  group('F22_A46 repository replay', () {
    test('WardrobeRepository write methods replay as allowed', () async {
      final repo = FirestoreWardrobeRepository(service, _alice);

      const withPhoto = ClothingItem(
        id: 'white-shirt',
        name: 'White Oxford Shirt',
        category: 'Shirts',
        color: 'White',
        occasion: 'Office',
        imageUrl: 'alice/white-shirt.jpg',
      );
      await repo.addItem(withPhoto);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/white-shirt', label: 'addItem(photo)');

      const noPhoto = ClothingItem(
        id: 'black-shirt',
        name: 'Black Shirt',
        category: 'Shirts',
        color: 'Black',
        occasion: 'Party',
      );
      await repo.addItem(noPhoto);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/black-shirt', label: 'addItem(no photo)');

      const batchA = ClothingItem(id: 'batch-a', name: 'A', category: 'Shirts', color: 'White', occasion: 'Office');
      const batchB = ClothingItem(id: 'batch-b', name: 'B', category: 'Pants', color: 'Navy', occasion: 'Office');
      await repo.addItems([batchA, batchB]);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/batch-a', label: 'addItems[0]');
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/batch-b', label: 'addItems[1]');

      await repo.updateItem(withPhoto.copyWith(name: 'Renamed Shirt'));
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/white-shirt', label: 'updateItem');

      await repo.adjustWears(['white-shirt'], 1);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/white-shirt', label: 'adjustWears(+1)');

      await repo.adjustWears(['black-shirt'], -1);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wardrobeItems/black-shirt', label: 'adjustWears(-1 at 0)');

      await repo.removeItem('batch-a');
      await _expectAllowedDelete(client, 'users/$_alice/wardrobeItems/batch-a', label: 'removeItem');
    });

    test('OutfitsRepository write methods replay as allowed', () async {
      final repo = FirestoreOutfitsRepository(service, _alice);

      const draft = Outfit(id: 1000, name: 'Draft', occasion: 'Everyday', items: ['white-shirt'], why: 'why');
      await repo.saveOrFind(draft, current: const []);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/outfits/1000', label: 'saveOrFind');

      const createCandidate = Outfit(id: 1001, name: 'New', occasion: 'Casual', items: ['black-shirt'], why: 'why');
      await repo.upsertManual(candidate: createCandidate, current: const []);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/outfits/1001', label: 'upsertManual(create)');

      const editCandidate = Outfit(id: 1001, name: 'Edited', occasion: 'Casual', items: ['black-shirt'], why: 'why');
      await repo.upsertManual(candidate: editCandidate, editingId: 1001, current: const []);
      await _expectAllowedUpdateExisting(
        client,
        fake,
        'users/$_alice/outfits/1001',
        label: 'upsertManual(edit)',
      );

      const fallbackCandidate = Outfit(id: 1002, name: 'Fallback', occasion: 'Casual', items: [], why: 'why');
      await repo.upsertManual(candidate: fallbackCandidate, editingId: 1002, current: const []);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/outfits/1002', label: 'upsertManual(not-found fallback)');

      await repo.delete(1000);
      await _expectAllowedDelete(client, 'users/$_alice/outfits/1000', label: 'delete');

      const wornOutfit = Outfit(id: 1003, name: 'Worn', occasion: 'Everyday', items: ['white-shirt'], why: 'why');
      await fake.doc('users/$_alice/outfits/1003').set(FirestoreOutfitsRepository.seedFieldsForOutfit(wornOutfit));
      final wearEvent = WearEvent(
        id: 2000,
        outfitId: 1003,
        name: '',
        occasion: '',
        items: const [],
        timestamp: DateTime.utc(2026, 10, 20),
      );
      await repo.logWear(1003, outfit: wornOutfit, event: wearEvent);
      await _expectAllowedFullSet(client, fake, 'users/$_alice/outfits/1003', label: 'logWear(outfit)');
      await _expectAllowedFullSet(client, fake, 'users/$_alice/wearEvents/2000', label: 'logWear(event)');

      await repo.removeWear(2000, event: wearEvent);
      await _expectAllowedDelete(client, 'users/$_alice/wearEvents/2000', label: 'removeWear(event)');
      await _expectAllowedFullSet(client, fake, 'users/$_alice/outfits/1003', label: 'removeWear(outfit)');
    });

    test('PlannerRepository write methods replay as allowed', () async {
      final repo = FirestorePlannerRepository(service, _alice);

      await repo.plan('2026-11-01', const PlannedEntry(outfitId: 1, occasion: 'Everyday'));
      await _expectAllowedFullSet(client, fake, 'users/$_alice/plannedEntries/2026-11-01', label: 'plan');

      await repo.remove('2026-11-01');
      await _expectAllowedDelete(client, 'users/$_alice/plannedEntries/2026-11-01', label: 'remove');
    });

    test('ProfileRepository write methods replay as allowed', () async {
      final repo = FirestoreProfileRepository(service, _alice);
      const path = 'users/$_alice';

      await repo.updateDetails('Alice', 'alice@example.com');
      await _expectAllowedMergeSet(client, fake, path, label: 'updateDetails');

      await repo.setStyles(['Casual']);
      await _expectAllowedMergeSet(client, fake, path, label: 'setStyles');

      await repo.setOccasions(['Everyday']);
      await _expectAllowedMergeSet(client, fake, path, label: 'setOccasions');

      await repo.setDailyNotifications(false);
      await _expectAllowedMergeSet(client, fake, path, label: 'setDailyNotifications');

      await repo.setPlannedNotifications(false);
      await _expectAllowedMergeSet(client, fake, path, label: 'setPlannedNotifications');

      await repo.setProductNotifications(true);
      await _expectAllowedMergeSet(client, fake, path, label: 'setProductNotifications');

      await repo.setWeatherConsent(true);
      await _expectAllowedMergeSet(client, fake, path, label: 'setWeatherConsent');

      await repo.setClimate('Hot');
      await _expectAllowedMergeSet(client, fake, path, label: 'setClimate');

      await repo.setPlan('pro');
      await _expectAllowedMergeSet(client, fake, path, label: 'setPlan');

      await repo.setBillingCycle('yearly');
      await _expectAllowedMergeSet(client, fake, path, label: 'setBillingCycle');

      await client.clearData();
      await fake.doc(path).delete();
      final freshRepo = FirestoreProfileRepository(service, 'bootstrap-uid');
      await freshRepo.bootstrapIfNeeded();
      final rawBootstrap = await _rawDoc(fake, 'users/bootstrap-uid');
      final result = await client.commit(
        [client.mergeSet('users/alice', _replayFields(rawBootstrap))],
        token: mockIdToken(_alice),
      );
      expect(result.ok, isTrue, reason: 'bootstrapIfNeeded replay denied: ${result.body}');
    });

    test('ShoppingRepository.setMembership replays as allowed (add + remove)', () async {
      final repo = FirestoreShoppingRepository(service, _alice);
      const path = 'users/$_alice';

      // Replays the fake's actual post-call document state (a full `set`),
      // not a hand-built `arrayUnion`/`arrayRemove` transform — the rule
      // evaluates `request.resource.data` as the complete resultant
      // document regardless of write kind, so this proves the rules allow
      // whatever `setMembership` really produced rather than a
      // hand-reconstructed guess at it.
      await repo.setMembership('shop-1', true);
      await _expectAllowedFullSet(client, fake, path, label: 'setMembership(add)');

      await repo.setMembership('shop-1', false);
      await _expectAllowedFullSet(client, fake, path, label: 'setMembership(remove)');
    });

    test('PackingRepository write methods replay as allowed', () async {
      final repo = FirestorePackingRepository(service, _alice);
      const tripPath = 'users/$_alice/packingTrips/trip-1';

      const newTrip = Trip(
        id: 'trip-1',
        name: 'Weekend',
        destination: 'Lahore',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Leisure',
        notes: '',
        days: 3,
        items: [],
      );
      await repo.saveTrip(newTrip, isNew: true);
      await _expectAllowedFullSet(client, fake, tripPath, label: 'saveTrip(isNew: true)');

      final editedTrip = newTrip.copyWith(name: 'Weekend (edited)', days: 4);
      await repo.saveTrip(editedTrip, isNew: false);
      await _expectAllowedMergeSet(client, fake, tripPath, label: 'saveTrip(isNew: false)');

      const wardrobeItem = PackingItem(key: 'white-shirt', label: 'White Shirt', wardrobeId: 'white-shirt');
      await repo.addWardrobe('trip-1', wardrobeItem);
      await _expectAllowedUpdateExisting(client, fake, tripPath, label: 'addWardrobe');

      const customItem = PackingItem(key: 'extra-1', label: 'Passport');
      await repo.addCustom('trip-1', customItem);
      await _expectAllowedUpdateExisting(client, fake, tripPath, label: 'addCustom');

      await repo.toggle('trip-1', 'white-shirt');
      await _expectAllowedUpdateExisting(client, fake, tripPath, label: 'toggle');

      await repo.generateChecklist('trip-1', [customItem]);
      await _expectAllowedUpdateExisting(client, fake, tripPath, label: 'generateChecklist');

      await repo.removeItem('trip-1', 'extra-1');
      await _expectAllowedUpdateExisting(client, fake, tripPath, label: 'removeItem');

      await repo.deleteTrip('trip-1');
      await _expectAllowedDelete(client, tripPath, label: 'deleteTrip');
    });
  });

  group('F22_A46b method-list completeness', () {
    test('enumerated replay coverage equals each repository\'s public write methods', () {
      final repoDir = _repoLibDir();
      final expected = <String, Set<String>>{
        'wardrobe': _publicFutureMethods('$repoDir/features/wardrobe/repository/firestore_wardrobe_repository.dart'),
        'outfits': _publicFutureMethods('$repoDir/features/saved/repository/firestore_outfits_repository.dart'),
        'planner': _publicFutureMethods('$repoDir/features/calendar/repository/firestore_planner_repository.dart'),
        'profile': _publicFutureMethods('$repoDir/features/profile/repository/firestore_profile_repository.dart'),
        'shopping': _publicFutureMethods('$repoDir/features/shopping/repository/firestore_shopping_repository.dart'),
        'packing': _publicFutureMethods('$repoDir/features/packing/repository/firestore_packing_repository.dart'),
      };

      final replayed = <String, Set<String>>{
        'wardrobe': {'addItem', 'addItems', 'updateItem', 'adjustWears', 'removeItem'},
        'outfits': {'saveOrFind', 'upsertManual', 'delete', 'logWear', 'removeWear'},
        'planner': {'plan', 'remove'},
        'profile': {
          'updateDetails',
          'setStyles',
          'setOccasions',
          'setDailyNotifications',
          'setPlannedNotifications',
          'setProductNotifications',
          'setWeatherConsent',
          'setClimate',
          'setPlan',
          'setBillingCycle',
          'bootstrapIfNeeded',
        },
        'shopping': {'setMembership'},
        'packing': {
          'saveTrip',
          'toggle',
          'removeItem',
          'addWardrobe',
          'addCustom',
          'generateChecklist',
          'deleteTrip',
        },
      };

      for (final repoName in expected.keys) {
        final missing = expected[repoName]!.difference(replayed[repoName]!);
        expect(
          missing,
          isEmpty,
          reason: '$repoName declares write method(s) not replayed by F22_A46: $missing',
        );
        final stale = replayed[repoName]!.difference(expected[repoName]!);
        expect(
          stale,
          isEmpty,
          reason: '$repoName: replayed method(s) no longer exist on the repository: $stale',
        );
      }
    });
  });
}

String _repoLibDir() {
  var dir = Directory.current;
  while (!File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
  return '${dir.path}${Platform.pathSeparator}lib'.replaceAll(Platform.pathSeparator, '/');
}
