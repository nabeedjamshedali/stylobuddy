import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/auth/cubit/auth_cubit.dart';
import 'package:stylobuddy/features/auth/cubit/auth_state.dart';
import 'package:stylobuddy/features/profile/cubit/profile_state.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/features/profile/repository/in_memory_profile_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

void main() {
  group('FirestoreProfileRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreService service;
    late FirestoreProfileRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: firestore);
      repo = FirestoreProfileRepository(service, 'uid-1');
    });

    test(
      'F18_A01 round-trips every ProfileState field unchanged through a write-then-watchProfile() read',
      () async {
        await repo.updateDetails('Sam Taylor', 'sam@example.com');
        await repo.setStyles(['Edgy']);
        await repo.setOccasions(['Travel', 'Wedding']);
        await repo.setDailyNotifications(false);
        await repo.setPlannedNotifications(false);
        await repo.setProductNotifications(true);
        await repo.setWeatherConsent(false);
        await repo.setClimate('Hot');
        await repo.setPlan('Plus');
        await repo.setBillingCycle('monthly');

        final state = await repo.watchProfile().first;

        expect(state.name, 'Sam Taylor');
        expect(state.email, 'sam@example.com');
        expect(state.styles, ['Edgy']);
        expect(state.occasions, ['Travel', 'Wedding']);
        expect(state.dailyNotifications, isFalse);
        expect(state.plannedNotifications, isFalse);
        expect(state.productNotifications, isTrue);
        expect(state.weatherConsent, isFalse);
        expect(state.climate, 'Hot');
        expect(state.plan, 'Plus');
        expect(state.billingCycle, 'monthly');
      },
    );

    test(
      'F18_A02 the raw document carries exactly the 11 ProfileState fields plus wishlist and seeded, never a stray extra field, and watchProfile() never exposes wishlist/seeded itself',
      () async {
        await repo.bootstrapIfNeeded();
        await repo.setClimate('Cold'); // a subsequent, unrelated write

        final raw = await service.userDoc('uid-1').get();
        final keys = raw.data()!.keys.toSet();
        expect(
          keys,
          {
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
          },
        );

        final state = await repo.watchProfile().first;
        // Strengthened per fix-round Minor #3: a bare isA<ProfileState>()
        // only checked the runtime type, not that wishlist/seeded are
        // actually excluded from the type's own shape. Rebuilding the
        // exact same ProfileState from only its 11 known public fields
        // must round-trip identically — if ProfileState ever grew a
        // wishlist/seeded field, this reconstruction would need updating
        // to still compile, making a silent shape drift impossible to
        // miss.
        final rebuilt = ProfileState(
          name: state.name,
          email: state.email,
          styles: state.styles,
          occasions: state.occasions,
          dailyNotifications: state.dailyNotifications,
          plannedNotifications: state.plannedNotifications,
          productNotifications: state.productNotifications,
          weatherConsent: state.weatherConsent,
          climate: state.climate,
          plan: state.plan,
          billingCycle: state.billingCycle,
        );
        expect(rebuilt.name, state.name);
        expect(rebuilt.email, state.email);
        expect(rebuilt.styles, state.styles);
        expect(rebuilt.occasions, state.occasions);

        // Structural guarantee (matches F14-A14/F15-A08's precedent): the
        // type's own source never declares a wishlist/seeded field at all.
        final source = File(
          'lib/features/profile/cubit/profile_state.dart',
        ).readAsStringSync();
        expect(source.contains('wishlist'), isFalse);
        expect(source.contains('seeded'), isFalse);
      },
    );

    test(
      'F18_A03 the D5 bootstrap sets wishlist: [] alongside seeded: true on first sign-in; a second call performs no further seed write',
      () async {
        await repo.bootstrapIfNeeded(pendingOccasions: {'Travel'});
        var raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], <String>[]);
        expect(raw.data()!['seeded'], true);
        expect(raw.data()!['occasions'], ['Travel']);

        // A second bootstrap call (e.g. a re-sign-in) must not overwrite
        // anything — F14's existing guard, reaffirmed not reimplemented.
        await repo.setOccasions(['Edited']);
        await repo.bootstrapIfNeeded(pendingOccasions: {'ShouldNotApply'});
        raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['occasions'], ['Edited']);
      },
    );

    test(
      'F18_A04 no FirestoreProfileRepository write method ever invokes runTransaction',
      () async {
        var transactionCalls = 0;
        final recordingFirestore = _RecordingFirestore(
          FakeFirebaseFirestore(),
          onTransaction: () => transactionCalls++,
        );
        final recordingRepo = FirestoreProfileRepository(
          FirestoreService(firestore: recordingFirestore),
          'uid-rec',
        );

        await recordingRepo.updateDetails('A', 'a@b.co');
        await recordingRepo.setStyles(['X']);
        await recordingRepo.setOccasions(['Y']);
        await recordingRepo.setDailyNotifications(false);
        await recordingRepo.setPlannedNotifications(false);
        await recordingRepo.setProductNotifications(true);
        await recordingRepo.setWeatherConsent(false);
        await recordingRepo.setClimate('Cold');
        await recordingRepo.setPlan('Plus');
        await recordingRepo.setBillingCycle('monthly');

        expect(
          transactionCalls,
          0,
          reason:
              'every set*/updateDetails call is a plain merge-set, never a '
              'runTransaction, unlike F16 logWear/removeWear',
        );
      },
    );

    test(
      'F18_A07 no onboarding selections (empty pendingOccasions) bootstraps with the hardcoded default occasions, never an empty list',
      () async {
        await repo.bootstrapIfNeeded(pendingOccasions: const {});
        final state = await repo.watchProfile().first;
        expect(state.occasions, ['Everyday', 'Office']);
      },
    );

    test(
      'F18_A17 a seedWriter is never invoked with an empty name for a real signup validated through AuthCubit.submitSignup',
      () {
        final cubit = AuthCubit();
        // AuthCubit.submitSignup's own existing validation rejects a name
        // shorter than 2 chars (trimmed) — never even reaches "success",
        // so no caller of this task's bootstrap seedWriter could be
        // driven with an empty name through that validated path. This
        // task changes nothing about that validation; it only confirms
        // the invariant still holds.
        final blocked = cubit.submitSignup(
          name: '',
          email: 'x@y.com',
          password: 'longenough',
          confirm: 'longenough',
        );
        expect(blocked, AuthResult.failure);

        final accepted = cubit.submitSignup(
          name: 'Jo',
          email: 'x@y.com',
          password: 'longenough',
          confirm: 'longenough',
        );
        expect(accepted, AuthResult.success);
        cubit.close();

        // FirestoreProfileRepository's own seedWriter (the no-op passed to
        // runBootstrapIfNeeded) never reads/writes a 'name' field at all —
        // name/email seeding for a real signup goes through
        // ProfileCubit.updateDetails, not the bootstrap seed, so there is
        // no seedWriter call site that could ever be handed an empty name.
        expect(ProfileState().name, isNotEmpty);
      },
    );

    test(
      'fix_round_Important5 the bootstrap seed never clobbers a profile field already present before the seeded flag commits (e.g. an offline-then-edit-then-retry race)',
      () async {
        // Simulate the race: a profile edit (e.g. a queued offline write
        // that just synced) landed on the document BEFORE the 'seeded'
        // flag was ever committed.
        await service.userDoc('uid-race').set({'name': 'Edited Name'});
        final raceRepo = FirestoreProfileRepository(service, 'uid-race');

        await raceRepo.bootstrapIfNeeded();

        final raw = await service.userDoc('uid-race').get();
        expect(
          raw.data()!['name'],
          'Edited Name',
          reason: 'a field already present must survive the seed, never be '
              'stomped back to the hardcoded default',
        );
        expect(raw.data()!['seeded'], true);
        // Every OTHER field (genuinely absent before this call) still gets
        // seeded normally — this isn't a case of the seed doing nothing.
        expect(raw.data()!['email'], const ProfileState().email);
        expect(raw.data()!['wishlist'], <String>[]);
      },
    );

    test(
      'fix_round_Important4 bootstrapIfNeeded seeds the real FirebaseAuth-sourced name/email when supplied, falling back to defaults only when unavailable',
      () async {
        final withAuthInfo = FirestoreProfileRepository(service, 'uid-auth');
        await withAuthInfo.bootstrapIfNeeded(
          name: 'Jordan Real',
          email: 'jordan.real@example.com',
        );
        final raw = await service.userDoc('uid-auth').get();
        expect(raw.data()!['name'], 'Jordan Real');
        expect(raw.data()!['email'], 'jordan.real@example.com');

        // null/empty name/email (e.g. unavailable) falls back to the
        // hardcoded placeholder defaults, never writes an empty string.
        final withoutAuthInfo = FirestoreProfileRepository(
          service,
          'uid-noauth',
        );
        await withoutAuthInfo.bootstrapIfNeeded(name: null, email: '');
        final rawNoAuth = await service.userDoc('uid-noauth').get();
        expect(rawNoAuth.data()!['name'], const ProfileState().name);
        expect(rawNoAuth.data()!['email'], const ProfileState().email);
      },
    );

    test(
      'fix_round_combined_bootstrap_seedWriter a custom seedWriter supplied to bootstrapIfNeeded runs inside the same transaction as the profile extraFields commit',
      () async {
        var seedWriterCalls = 0;
        final repoWithSeedWriter = FirestoreProfileRepository(
          service,
          'uid-combined',
        );
        await repoWithSeedWriter.bootstrapIfNeeded(
          seedWriter: (tx, userDoc) async {
            seedWriterCalls++;
            tx.set(userDoc.collection('wardrobeItems').doc('seed-item'), {
              'id': 'seed-item',
            });
          },
        );
        expect(seedWriterCalls, 1);
        final seededItem = await service
            .userDoc('uid-combined')
            .collection('wardrobeItems')
            .doc('seed-item')
            .get();
        expect(seededItem.exists, isTrue);
        final raw = await service.userDoc('uid-combined').get();
        expect(raw.data()!['seeded'], true);
      },
    );

    test(
      'F18_A18 watchProfile() treats a missing occasions/styles field as the hardcoded default, and an explicitly-present empty array as a genuinely empty list, verbatim',
      () async {
        // Legacy doc written before this task's fields existed: entirely
        // missing occasions/styles.
        await service.userDoc('uid-legacy').set({'seeded': true});
        final legacy = await FirestoreProfileRepository(
          service,
          'uid-legacy',
        ).watchProfile().first;
        expect(legacy.occasions, ['Everyday', 'Office']);
        expect(legacy.styles, ['Minimal', 'Smart casual']);

        // Explicitly-present-but-empty array, written directly (no current
        // ProfileCubit call site ever produces this) — read back verbatim.
        await service.userDoc('uid-empty').set({
          'occasions': <String>[],
          'styles': <String>[],
        });
        final empty = await FirestoreProfileRepository(
          service,
          'uid-empty',
        ).watchProfile().first;
        expect(empty.occasions, isEmpty);
        expect(empty.styles, isEmpty);
      },
    );

    test(
      'F18_A19 watchProfile() treats a missing climate/plan/billingCycle field as the hardcoded default, and an explicitly-present empty string as "" verbatim',
      () async {
        await service.userDoc('uid-legacy2').set({'seeded': true});
        final legacy = await FirestoreProfileRepository(
          service,
          'uid-legacy2',
        ).watchProfile().first;
        expect(legacy.climate, 'Mild');
        expect(legacy.plan, 'Free');
        expect(legacy.billingCycle, 'yearly');

        await service.userDoc('uid-empty2').set({
          'climate': '',
          'plan': '',
          'billingCycle': '',
        });
        final empty = await FirestoreProfileRepository(
          service,
          'uid-empty2',
        ).watchProfile().first;
        expect(empty.climate, '');
        expect(empty.plan, '');
        expect(empty.billingCycle, '');
      },
    );
  });

  // F18-A08 ("InMemoryProfileRepository's behavior is unchanged from
  // today's ProfileCubit-held logic") has no dedicated test in this file
  // (fix round, Minor #1): the previous placeholder here was a bare
  // `expect(true, isTrue)` that asserted nothing. The real coverage
  // already lives in test/features/profile/profile_cubit_test.dart, which
  // this task leaves byte-for-byte unedited and still green against
  // ProfileCubit's new repository-backed constructor (its default
  // argument) — see that file for A08's actual verification.
  group('InMemoryProfileRepository', () {
    test(
      'F18_A09 every write method returns an already-completed (SynchronousFuture) Future, verified before any pump/await',
      () {
        final repo = InMemoryProfileRepository();
        final future = repo.setClimate('Cold');
        expect(future, isA<SynchronousFuture<void>>());

        var completedSynchronously = false;
        // ignore: unawaited_futures
        future.then((_) => completedSynchronously = true);
        // SynchronousFuture's `.then` callback runs inline, before this
        // line, with no microtask hop — so it must already be true here,
        // with zero await/pump in between.
        expect(completedSynchronously, isTrue);
      },
    );

    test(
      'F18_A10 never imports or constructs a Firestore client — zero network calls, structurally',
      () {
        final repo = InMemoryProfileRepository();
        expect(repo.snapshot, const ProfileState());

        // Strengthened per fix-round Minor #2 (matching F14-A14/F15-A08's
        // established source-text-grep pattern): actually read the
        // source file and assert it never imports cloud_firestore, rather
        // than only asserting synchronous behavior and claiming the
        // import-free guarantee "by inspection".
        final source = File(
          'lib/features/profile/repository/in_memory_profile_repository.dart',
        ).readAsStringSync();
        expect(source.contains('cloud_firestore'), isFalse);
      },
    );
  });
}

/// Minimal transaction-call recorder wrapping a real [FakeFirebaseFirestore]
/// — [FirestoreProfileRepository]/[FirestoreService] only ever call
/// [collection] (via `userDoc`) and [runTransaction] on the injected
/// `FirebaseFirestore`, so only those two are forwarded here (every other
/// member throws [UnimplementedError] if ever reached, which would itself
/// surface as a loud test failure rather than a silent pass). Counts every
/// [runTransaction] call before forwarding it, to prove F18-A04 ("no
/// FirestoreProfileRepository write method ever invokes runTransaction")
/// against the actual call path rather than by code inspection alone.
class _RecordingFirestore implements FirebaseFirestore {
  _RecordingFirestore(this._delegate, {required this.onTransaction});

  final FakeFirebaseFirestore _delegate;
  final void Function() onTransaction;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _delegate.collection(path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    onTransaction();
    return _delegate.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
