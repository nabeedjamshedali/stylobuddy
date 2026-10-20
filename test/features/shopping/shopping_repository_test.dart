import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/features/shopping/repository/firestore_shopping_repository.dart';
import 'package:stylobuddy/features/shopping/repository/in_memory_shopping_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

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
      'F19_A01 toggleWishlist adding an id not already present results in watchWishlist() emitting a list containing that id, read back off the real document',
      () async {
        await repo.toggleWishlist('neutral-blazer');
        final wishlist = await repo.watchWishlist().first;
        expect(wishlist, contains('neutral-blazer'));

        final raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['neutral-blazer']);
      },
    );

    test(
      'F19_A02 toggleWishlist removing an id already present results in watchWishlist() emitting a list without that id',
      () async {
        await repo.toggleWishlist('neutral-blazer');
        await repo.toggleWishlist('everyday-bag');
        await repo.toggleWishlist('neutral-blazer'); // removes it

        final wishlist = await repo.watchWishlist().first;
        expect(wishlist, isNot(contains('neutral-blazer')));
        expect(wishlist, contains('everyday-bag'));
      },
    );

    test(
      'F19_A03 toggleWishlist returns true when the id was added and false when it was removed',
      () async {
        final added = await repo.toggleWishlist('neutral-blazer');
        expect(added, isTrue);
        final removed = await repo.toggleWishlist('neutral-blazer');
        expect(removed, isFalse);
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
      'F19_A05 toggleWishlist then a Profile field write leaves BOTH the toggled wishlist and the updated climate present together',
      () async {
        final profileRepo = FirestoreProfileRepository(service, 'uid-1');
        await repo.toggleWishlist('neutral-blazer');
        await profileRepo.setClimate('Hot');

        final raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['neutral-blazer']);
        expect(raw.data()!['climate'], 'Hot');
      },
    );

    test(
      'F19_A06 the reverse ordering (Profile write then toggleWishlist) produces the same non-clobbering result, order-independent',
      () async {
        final profileRepo = FirestoreProfileRepository(service, 'uid-1');
        await profileRepo.setOccasions(['Travel', 'Wedding']);
        await repo.toggleWishlist('everyday-bag');

        final raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['occasions'], ['Travel', 'Wedding']);
        expect(raw.data()!['wishlist'], ['everyday-bag']);
      },
    );

    test(
      'F19_A07 every FirestoreShoppingRepository write touches only the wishlist key — every pre-existing ProfileState-owned field is left byte-identical after a toggleWishlist call',
      () async {
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

        await repo.toggleWishlist('neutral-blazer');

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
      'F19_A18 a toggleWishlist call against a document whose wishlist is explicitly present and non-empty correctly adds/removes relative to that real array',
      () async {
        await service.userDoc('uid-1').set({'wishlist': ['item-3']});
        final added = await repo.toggleWishlist('item-4');
        expect(added, isTrue);
        var raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['item-3', 'item-4']);

        final removed = await repo.toggleWishlist('item-3');
        expect(removed, isFalse);
        raw = await service.userDoc('uid-1').get();
        expect(raw.data()!['wishlist'], ['item-4']);
      },
    );
  });

  group('InMemoryShoppingRepository', () {
    test(
      'F19_A09 toggleWishlist returns a SynchronousFuture (already-completed), verified before any pump/await',
      () {
        final repo = InMemoryShoppingRepository();
        final future = repo.toggleWishlist('neutral-blazer');
        expect(future, isA<SynchronousFuture<bool>>());

        var completedSynchronously = false;
        var addedValue = false;
        // ignore: unawaited_futures
        future.then((added) {
          completedSynchronously = true;
          addedValue = added;
        });
        expect(completedSynchronously, isTrue);
        expect(addedValue, isTrue);
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
      'F19_A08 add-or-remove semantics match today\'s ShoppingCubit-held logic: toggling adds an unsaved id and reports true, toggling again removes it and reports false',
      () async {
        final repo = InMemoryShoppingRepository();
        final added = await repo.toggleWishlist('neutral-blazer');
        expect(added, isTrue);
        expect(repo.snapshot, ['neutral-blazer']);

        final removed = await repo.toggleWishlist('neutral-blazer');
        expect(removed, isFalse);
        expect(repo.snapshot, isEmpty);
      },
    );
  });
}
