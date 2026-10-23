import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/profile/cubit/profile_state.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/features/profile/repository/in_memory_profile_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

const _f18Keys = {
  'name',
  'email',
  'styles',
  'occasions',
  'dailyNotifications',
  'plannedNotifications',
  'productNotifications',
  'weatherConsent',
  'climate',
  'plan',
  'billingCycle',
  'wishlist',
  'seeded',
};

/// A fully populated, non-default users/{uid} document (F18-A01 shape).
const _fullDoc = <String, Object?>{
  'name': 'Sam Taylor',
  'email': 'sam@example.com',
  'styles': ['Edgy'],
  'occasions': ['Travel'],
  'dailyNotifications': false,
  'plannedNotifications': false,
  'productNotifications': true,
  'weatherConsent': false,
  'climate': '',
  'plan': 'Plus',
  'billingCycle': 'monthly',
  'seeded': true,
};

void _expectFullDocFields(ProfileState s) {
  expect(s.name, 'Sam Taylor');
  expect(s.email, 'sam@example.com');
  expect(s.styles, ['Edgy']);
  expect(s.occasions, ['Travel']);
  expect(s.dailyNotifications, isFalse);
  expect(s.plannedNotifications, isFalse);
  expect(s.productNotifications, isTrue);
  expect(s.weatherConsent, isFalse);
  expect(s.climate, '', reason: 'F18-A19 missing != empty');
  expect(s.plan, 'Plus');
  expect(s.billingCycle, 'monthly');
}

void main() {
  group('F24 ProfileState.gender', () {
    test('F24_A26 defaults null; copyWith keeps it; other defaults unchanged', () {
      const state = ProfileState();
      expect(state.gender, isNull);
      expect(
        const ProfileState(gender: 'female').copyWith(climate: 'Hot').gender,
        'female',
      );
      expect(const ProfileState(gender: 'female').copyWith().gender, 'female');

      expect(state.name, 'Alex Morgan');
      expect(state.email, 'alex@example.com');
      expect(state.styles, ['Minimal', 'Smart casual']);
      expect(state.occasions, ['Everyday', 'Office']);
      expect(state.dailyNotifications, isTrue);
      expect(state.plannedNotifications, isTrue);
      expect(state.productNotifications, isFalse);
      expect(state.weatherConsent, isTrue);
      expect(state.climate, 'Mild');
      expect(state.plan, 'Free');
      expect(state.billingCycle, 'yearly');
    });

    test('F24_A27 guest repository never stores gender; no interface method', () async {
      final repo = InMemoryProfileRepository();
      expect(repo.snapshot.gender, isNull);
      await repo.updateDetails('Sam', 'sam@example.com');
      await repo.setStyles(['Edgy']);
      await repo.setOccasions(['Travel']);
      await repo.setDailyNotifications(false);
      await repo.setPlannedNotifications(false);
      await repo.setProductNotifications(true);
      await repo.setWeatherConsent(false);
      await repo.setClimate('Hot');
      await repo.setPlan('Plus');
      await repo.setBillingCycle('monthly');
      expect(repo.snapshot.gender, isNull);

      for (final path in [
        'lib/features/profile/repository/profile_repository.dart',
        'lib/features/profile/repository/in_memory_profile_repository.dart',
      ]) {
        expect(File(path).readAsStringSync().contains('gender'), isFalse, reason: path);
      }
    });
  });

  group('F24 FirestoreProfileRepository gender', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreService service;
    late FirestoreProfileRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: firestore);
      repo = FirestoreProfileRepository(service, 'uid-1');
    });

    Future<Map<String, dynamic>> raw() async =>
        (await service.userDoc('uid-1').get()).data() ?? {};

    test('F24_A28 read: missing/null -> null, strings verbatim (incl. empty)', () async {
      final cases = <(Map<String, Object?>, String?)>[
        (const {}, null),
        (const {'gender': null}, null),
        (const {'gender': 'female'}, 'female'),
        (const {'gender': ''}, ''),
      ];
      for (final (extra, expected) in cases) {
        await firestore.collection('users').doc('uid-1').set({..._fullDoc, ...extra});
        final state = await repo.watchProfile().first;
        expect(state.gender, expected, reason: '$extra');
        _expectFullDocFields(state);
      }
    });

    test('F24_A29 bootstrap writes gender only for a valid value', () async {
      await repo.bootstrapIfNeeded(gender: 'female');
      final doc = await raw();
      expect(doc.keys.toSet(), {..._f18Keys, 'gender'});
      expect(doc['gender'], 'female');

      for (final gender in <String?>[null, 'other', '']) {
        final fs = FakeFirebaseFirestore();
        final svc = FirestoreService(firestore: fs);
        final r = FirestoreProfileRepository(svc, 'uid-1');
        if (gender == null) {
          await r.bootstrapIfNeeded();
        } else {
          await r.bootstrapIfNeeded(gender: gender);
        }
        final data = (await svc.userDoc('uid-1').get()).data()!;
        expect(data.keys.toSet(), _f18Keys, reason: '$gender');
        expect(data['seeded'], isTrue, reason: '$gender');
        expect(data['occasions'], const ProfileState().occasions, reason: '$gender');
      }
    });

    test('F24_A30 absent-keys-only and no backfill', () async {
      await firestore.collection('users').doc('uid-1').set({'gender': 'male'});
      await repo.bootstrapIfNeeded(gender: 'female');
      final doc = await raw();
      expect(doc['gender'], 'male');
      expect(doc['seeded'], isTrue);

      final fs = FakeFirebaseFirestore();
      final svc = FirestoreService(firestore: fs);
      await fs.collection('users').doc('uid-2').set({'seeded': true});
      final returning = FirestoreProfileRepository(svc, 'uid-2');
      await returning.bootstrapIfNeeded(gender: 'female');
      final data = (await svc.userDoc('uid-2').get()).data()!;
      expect(data, {'seeded': true}, reason: 'no write at all');
      expect(data.containsKey('gender'), isFalse);
    });

    test('F24_A31 no existing write method sends gender; bootstrap value survives', () async {
      await repo.updateDetails('Sam', 'sam@example.com');
      await repo.setStyles(['Edgy']);
      await repo.setOccasions(['Travel']);
      await repo.setDailyNotifications(false);
      await repo.setPlannedNotifications(false);
      await repo.setProductNotifications(true);
      await repo.setWeatherConsent(false);
      await repo.setClimate('Hot');
      await repo.setPlan('Plus');
      await repo.setBillingCycle('monthly');
      expect((await raw()).containsKey('gender'), isFalse);

      final fs = FakeFirebaseFirestore();
      final svc = FirestoreService(firestore: fs);
      final r = FirestoreProfileRepository(svc, 'uid-1');
      await r.bootstrapIfNeeded(gender: 'female');
      await r.setClimate('Hot');
      final data = (await svc.userDoc('uid-1').get()).data()!;
      expect(data['gender'], 'female');
      expect(data['climate'], 'Hot');
    });
  });
}
