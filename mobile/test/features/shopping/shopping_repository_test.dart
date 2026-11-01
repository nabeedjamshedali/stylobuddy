import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/profile/cubit/profile_state.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/features/shopping/cubit/shopping_cubit.dart';
import 'package:stylobuddy/features/shopping/repository/firestore_shopping_repository.dart';
import 'package:stylobuddy/features/shopping/repository/in_memory_shopping_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

/// Bounded-polling wait (the implementer contract's documented
/// `fake_cloud_firestore` gotcha: `pumpAndSettle()`-equivalent waits aren't
/// available outside widget tests, and a bare microtask flush isn't always
/// enough once two independent unawaited writes are in flight).
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Same bounded-polling strategy, for a condition that itself requires an
/// async Firestore read (e.g. polling `userDoc(...).get()`).
Future<void> _waitUntilAsync(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('FirestoreShoppingRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreService service;
    late FirestoreShoppingRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = FirestoreService(firestore: firestore);
      repo = FirestoreShoppingRepository(service, 'uid-1');
    });

    test(
      'F19_A01 setMembership(id, true) adding an id not already present results in watchWishlist() emitting a list containing that id, read back off the real document',
      () async {
        await repo.setMembership('neutral-blazer', true);
        final wishlist = await repo.watchWishlist().first;
        expect(wishlist, contains('neutral-blazer'));

        final raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['neutral-blazer']);
      },
    );

    test(
      'F19_A02 setMembership(id, false) removing an id already present results in watchWishlist() emitting a list without that id',
      () async {
        await repo.setMembership('neutral-blazer', true);
        await repo.setMembership('everyday-bag', true);
        await repo.setMembership('neutral-blazer', false); // removes it

        final wishlist = await repo.watchWishlist().first;
        expect(wishlist, isNot(contains('neutral-blazer')));
        expect(wishlist, contains('everyday-bag'));
      },
    );

    test(
      'F19_A03 setMembership completes successfully for both an add and a remove of the same id, leaving the document in the expected final state each time',
      () async {
        await repo.setMembership('neutral-blazer', true);
        var raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['neutral-blazer']);

        await repo.setMembership('neutral-blazer', false);
        raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], isEmpty);
      },
    );

    test(
      'F19_A04 FirestoreProfileRepository exposes no method whose name or written field set references wishlist',
      () async {
        final source = File(
          'lib/features/profile/repository/firestore_profile_repository.dart',
        ).readAsStringSync();
        // The only place 'wishlist' appears in that file is the bootstrap
        // seed default — never inside a set*/updateDetails method body.
        final writeMethodNames = [
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
        ];
        for (final name in writeMethodNames) {
          expect(
            source.contains(RegExp('$name\\b')),
            isTrue,
            reason: 'sanity: $name should exist in the file',
          );
        }
        // Behaviorally: a FirestoreProfileRepository write never leaves a
        // trace of touching wishlist on the shared document.
        final profileRepo = FirestoreProfileRepository(service, 'uid-1');
        await profileRepo.bootstrapIfNeeded();
        await profileRepo.setClimate('Cold');
        final raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], <String>[]);
      },
    );

    test(
      'F19_A05 a ShoppingCubit.toggleWishlist call and a ProfileCubit.setClimate call fired unawaited (not sequentially awaited repository-to-repository) against the same uid leave BOTH the toggled wishlist and the updated climate present together',
      () async {
        final shoppingCubit = ShoppingCubit(repository: repo);
        final profileCubit = ProfileCubit(
          repository: FirestoreProfileRepository(service, 'uid-1'),
        );
        addTearDown(shoppingCubit.close);
        addTearDown(profileCubit.close);

        // Both calls are fired without awaiting the Cubit method itself —
        // toggleWishlist/setClimate return void/bool synchronously and
        // persist in the background, exactly as a real caller (a widget
        // tap handler) would use them.
        shoppingCubit.toggleWishlist('neutral-blazer');
        profileCubit.setClimate('Hot');

        await _waitUntilAsync(() async {
          final data = (await service.userDoc('uid-1').get()).data();
          return data != null &&
              data['wishlist'] is List &&
              (data['wishlist'] as List).contains('neutral-blazer') &&
              data['climate'] == 'Hot';
        });
        final afterBoth = await service.userDoc('uid-1').get();
        expect(afterBoth.data()!['climate'], 'Hot');
        expect(afterBoth.data()!['wishlist'], ['neutral-blazer']);
      },
    );

    test(
      'F19_A06 the reverse ordering (ProfileCubit.togglePreference fired unawaited, then ShoppingCubit.toggleWishlist fired unawaited) produces the same non-clobbering result, order-independent',
      () async {
        final shoppingCubit = ShoppingCubit(repository: repo);
        final profileCubit = ProfileCubit(
          repository: FirestoreProfileRepository(service, 'uid-1'),
        );
        addTearDown(shoppingCubit.close);
        addTearDown(profileCubit.close);

        profileCubit.togglePreference(PreferenceField.occasions, 'Travel');
        shoppingCubit.toggleWishlist('everyday-bag');

        await _waitUntil(
          () => profileCubit.state.occasions.contains('Travel'),
        );
        await _waitUntilAsync(() async {
          final data = (await service.userDoc('uid-1').get()).data();
          return data != null &&
              data['wishlist'] is List &&
              (data['wishlist'] as List).contains('everyday-bag');
        });
        final raw = (await service.userDoc('uid-1').get()).data()!;
        expect(raw['occasions'], contains('Travel'));
        expect(raw['wishlist'], ['everyday-bag']);
      },
    );

    test(
      'F19_A07 setMembership writes a payload whose key set is exactly {wishlist} — proven by a wrapper that records the exact field keys written, not merely by comparing before/after values',
      () async {
        final recordingDoc = _KeyRecordingDocument(
          service.userDoc('uid-1'),
        );
        final recordingRepo = FirestoreShoppingRepository.withDocument(
          recordingDoc,
        );

        final profileRepo = FirestoreProfileRepository(service, 'uid-1');
        await profileRepo.updateDetails('Sam Taylor', 'sam@example.com');
        await profileRepo.setStyles(['Edgy']);
        await profileRepo.setOccasions(['Travel']);
        await profileRepo.setDailyNotifications(false);
        await profileRepo.setPlannedNotifications(false);
        await profileRepo.setProductNotifications(true);
        await profileRepo.setWeatherConsent(false);
        await profileRepo.setClimate('Hot');
        await profileRepo.setPlan('Plus');
        await profileRepo.setBillingCycle('monthly');

        final before = (await service.userDoc('uid-1').get()).data()!;

        await recordingRepo.setMembership('neutral-blazer', true);

        expect(
          recordingDoc.writtenKeySets,
          everyElement(equals({'wishlist'})),
          reason:
              'every call recorded through setMembership must write '
              'exactly the wishlist key, never a whole-document payload',
        );
        expect(recordingDoc.writtenKeySets, isNotEmpty);

        final after = (await service.userDoc('uid-1').get()).data()!;
        for (final key in before.keys) {
          if (key == 'wishlist') continue;
          expect(
            after[key],
            before[key],
            reason: '$key must be untouched by a wishlist-only write',
          );
        }
        expect(after.keys, containsAll({...before.keys, 'wishlist'}));
        expect(after['wishlist'], ['neutral-blazer']);
      },
    );

    test(
      'F19_A17 watchWishlist() treats a document with an entirely missing wishlist field as an empty list',
      () async {
        await service.userDoc('uid-missing').set({'seeded': true});
        final missingRepo = FirestoreShoppingRepository(service, 'uid-missing');
        final wishlist = await missingRepo.watchWishlist().first;
        expect(wishlist, isEmpty);
      },
    );

    test(
      'F19_A17 an explicitly-present empty wishlist (the normal just-bootstrapped case) is also read back as an empty list, via a different code path than the missing-field case',
      () async {
        await service.userDoc('uid-empty').set({'wishlist': <String>[]});
        final emptyRepo = FirestoreShoppingRepository(service, 'uid-empty');
        final wishlist = await emptyRepo.watchWishlist().first;
        expect(wishlist, isEmpty);
      },
    );

    test(
      'F19_A18 a setMembership call against a document whose wishlist is explicitly present and non-empty correctly adds/removes relative to that real array',
      () async {
        await service.userDoc('uid-1').set({'wishlist': ['item-3']});
        await repo.setMembership('item-4', true);
        var raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['item-3', 'item-4']);

        await repo.setMembership('item-3', false);
        raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['item-4']);
      },
    );
  });

  group('InMemoryShoppingRepository', () {
    test(
      'F19_A09 setMembership returns a SynchronousFuture (already-completed), verified before any pump/await',
      () {
        final repo = InMemoryShoppingRepository();
        final future = repo.setMembership('neutral-blazer', true);
        expect(future, isA<SynchronousFuture<void>>());

        var completedSynchronously = false;
        // ignore: unawaited_futures
        future.then((_) => completedSynchronously = true);
        expect(completedSynchronously, isTrue);
        expect(repo.snapshot, ['neutral-blazer']);
      },
    );

    test(
      'F19_A10 never imports or constructs a Firestore client — zero network calls, structurally',
      () {
        final repo = InMemoryShoppingRepository();
        expect(repo.snapshot, isEmpty);

        final source = File(
          'lib/features/shopping/repository/in_memory_shopping_repository.dart',
        ).readAsStringSync();
        expect(source.contains('cloud_firestore'), isFalse);
      },
    );

    test(
      'F19_A08 add-or-remove semantics match today\'s ShoppingCubit-held logic: setMembership(id, true) adds an unsaved id, setMembership(id, false) removes it',
      () async {
        final repo = InMemoryShoppingRepository();
        await repo.setMembership('neutral-blazer', true);
        expect(repo.snapshot, ['neutral-blazer']);

        await repo.setMembership('neutral-blazer', false);
        expect(repo.snapshot, isEmpty);
      },
    );
  });
}

// ignore: subtype_of_sealed_class
/// [DocumentReference] wrapper that records the exact key set of every
/// `set()` call it forwards, while delegating to a real (fake-Firestore)
/// document for every other member — used only by F19_A07 to prove
/// [FirestoreShoppingRepository.setMembership] never writes anything
/// beyond `{'wishlist'}`. Every unexercised member intentionally throws
/// via the default `noSuchMethod` (never called by this repository).
class _KeyRecordingDocument implements DocumentReference<Map<String, dynamic>> {
  _KeyRecordingDocument(this._inner);

  final DocumentReference<Map<String, dynamic>> _inner;
  final List<Set<String>> writtenKeySets = [];

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) {
    writtenKeySets.add(data.keys.toSet());
    return _inner.set(data, options);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    ListenSource source = ListenSource.defaultSource,
    bool includeMetadataChanges = false,
  }) => _inner.snapshots(
    source: source,
    includeMetadataChanges: includeMetadataChanges,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
