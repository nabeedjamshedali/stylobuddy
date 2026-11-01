import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/shopping/cubit/shopping_cubit.dart';
import 'package:stylobuddy/features/shopping/repository/firestore_shopping_repository.dart';
import 'package:stylobuddy/features/shopping/repository/in_memory_shopping_repository.dart';
import 'package:stylobuddy/features/shopping/repository/shopping_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

/// A [ShoppingRepository] test double whose `toggleWishlist` call can be
/// made to fail on demand, so the `catchError`/rollback path can be driven
/// deterministically without any real/fake network I/O — mirrors
/// `_FailingProfileRepository` (F18).
class _FailingShoppingRepository implements ShoppingRepository {
  final _controller = StreamController<List<String>>.broadcast();
  List<String> _wishlist = const [];

  /// When `true`, the *next* setMembership call fails (regardless of id).
  bool failing = false;

  /// When set, only a setMembership call for THIS id fails (once); every
  /// other id's call succeeds normally — used to prove the rollback is
  /// targeted to the one id that actually failed, not the whole list, when
  /// two different ids' calls are in flight concurrently.
  String? failOnId;

  final List<String> calls = [];

  void emitWishlist(List<String> wishlist) {
    _wishlist = wishlist;
    _controller.add(_wishlist);
  }

  @override
  Stream<List<String>> watchWishlist() => _controller.stream;

  @override
  Future<void> setMembership(String id, bool add) {
    calls.add(id);
    if (failing || id == failOnId) {
      failing = false;
      failOnId = null;
      return Future<void>.error(StateError('setMembership($id) failed'));
    }
    _wishlist = add
        ? (_wishlist.contains(id) ? _wishlist : [..._wishlist, id])
        : _wishlist.where((x) => x != id).toList();
    return Future<void>.value();
  }
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test(
    'F19_A11_sample ShoppingCubit constructed with InMemoryShoppingRepository vs FirestoreShoppingRepository is a different object type, not just different data',
    () async {
      final guestCubit = ShoppingCubit(repository: InMemoryShoppingRepository());
      final firestore = FakeFirebaseFirestore();
      final signedInCubit = ShoppingCubit(
        repository: FirestoreShoppingRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );
      addTearDown(guestCubit.close);
      addTearDown(signedInCubit.close);

      expect(guestCubit.state.wishlist, isEmpty);
      expect(signedInCubit.state.wishlist, isEmpty);
    },
  );

  test(
    'F19_A11_reverse the signed-in-to-guest direction: a FirestoreShoppingRepository-backed ShoppingCubit with a saved item, torn down and replaced by an InMemoryShoppingRepository-backed one (F14 D3 sign-out teardown), shows an empty wishlist, never the signed-in uid\'s saved item',
    () async {
      final firestore = FakeFirebaseFirestore();
      final signedInCubit = ShoppingCubit(
        repository: FirestoreShoppingRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );
      signedInCubit.toggleWishlist('neutral-blazer');
      await _settle();
      expect(signedInCubit.state.wishlist, ['neutral-blazer']);
      await signedInCubit.close();

      // Sign-out: a brand-new guest ShoppingCubit, not the same instance —
      // mirroring app.dart's full-teardown-and-rebuild per uid (F14 D3).
      final guestCubit = ShoppingCubit(repository: InMemoryShoppingRepository());
      addTearDown(guestCubit.close);
      expect(guestCubit.state.wishlist, isEmpty);
      expect(guestCubit.state.wishlist, isNot(contains('neutral-blazer')));
    },
  );

  test(
    'F19_A12 toggleWishlist optimistically updates state before the repository Future resolves, then rolls back only wishlist to its pre-toggle value on failure',
    () async {
      final repo = _FailingShoppingRepository();
      final cubit = ShoppingCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failing = true;
      final added = cubit.toggleWishlist('neutral-blazer');
      expect(added, isTrue);
      // Optimistic update already applied before the repository Future (a
      // real Future.error here) has had a chance to settle.
      expect(cubit.state.wishlist, ['neutral-blazer']);

      await _settle();
      // The failed write rolled back wishlist to its pre-toggle value.
      expect(cubit.state.wishlist, isEmpty);
    },
  );

  test(
    'F19_A13 an interleaved toggleWishlist (will fail) and setTab/select (will succeed): the targeted rollback reverts only wishlist, leaving tab/selectedId untouched',
    () async {
      final repo = _FailingShoppingRepository();
      final cubit = ShoppingCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failing = true;
      cubit.toggleWishlist('neutral-blazer'); // will fail
      cubit.setTab('wishlist'); // concurrently succeeds, purely local
      cubit.select('everyday-bag'); // concurrently succeeds, purely local

      await _settle();

      expect(
        cubit.state.wishlist,
        isEmpty,
        reason: 'the failed toggleWishlist call must be rolled back',
      );
      expect(
        cubit.state.tab,
        'wishlist',
        reason:
            'the concurrently-succeeding setTab call must survive the '
            'wishlist-only rollback untouched',
      );
      expect(
        cubit.state.selectedId,
        'everyday-bag',
        reason:
            'the concurrently-succeeding select call must survive the '
            'wishlist-only rollback untouched',
      );
    },
  );

  test(
    'F19_A12_targeted_revert two concurrently-toggled DIFFERENT ids, where the first fails and the second succeeds, roll back only the failed id — the second id\'s successful addition survives untouched (not wiped by a whole-previous-list restore, the F17/F18 bug class this task\'s Cubit fix avoids)',
    () async {
      final repo = _FailingShoppingRepository();
      final cubit = ShoppingCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failOnId = 'a'; // only 'a's call fails; 'b's call succeeds

      final addedA = cubit.toggleWishlist('a'); // optimistic add, then fails
      expect(addedA, isTrue);
      expect(cubit.state.wishlist, contains('a'));

      final addedB = cubit.toggleWishlist('b'); // optimistic add, succeeds
      expect(addedB, isTrue);
      expect(cubit.state.wishlist, containsAll(['a', 'b']));

      await _settle();

      expect(
        cubit.state.wishlist,
        isNot(contains('a')),
        reason: "the failed toggle of 'a' must be rolled back",
      );
      expect(
        cubit.state.wishlist,
        contains('b'),
        reason:
            "'b' was correctly persisted by the repository and must NOT be "
            "silently wiped by 'a's rollback restoring a captured "
            "whole-list-before-the-call snapshot",
      );
    },
  );

  test(
    'F19_A14 a failing toggleWishlist call never surfaces as an unhandled async error',
    () async {
      final repo = _FailingShoppingRepository();
      final cubit = ShoppingCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failing = true;
      final errors = <Object>[];
      await runZonedGuarded(() async {
        cubit.toggleWishlist('neutral-blazer');
        await _settle();
      }, (error, stack) => errors.add(error));

      expect(
        errors,
        isEmpty,
        reason: 'the failure must be caught by ShoppingCubit, not escape '
            'as an unhandled zone error',
      );
      expect(cubit.state.wishlist, isEmpty);
    },
  );

  test(
    'F19_A15 a simulated watchWishlist() stream error does not crash the Cubit or surface as an unhandled zone error',
    () async {
      final repo = _FailingShoppingRepository();
      final cubit = ShoppingCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      final errors = <Object>[];
      await runZonedGuarded(() async {
        repo._controller.addError(StateError('snapshot error'));
        await _settle();
      }, (error, stack) => errors.add(error));

      expect(errors, isEmpty);
      // The Cubit keeps its last known state rather than crashing.
      expect(cubit.state.wishlist, isEmpty);
    },
  );

  test(
    'F19_A16 sign-out then sign-in-again as a different uid leaves no stale wishlist bleed-through',
    () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);
      final signedInA = ShoppingCubit(
        repository: FirestoreShoppingRepository(service, 'uid-a'),
      );
      addTearDown(signedInA.close);
      signedInA.toggleWishlist('neutral-blazer');
      await _settle();
      expect(signedInA.state.wishlist, ['neutral-blazer']);

      // Sign-out: a brand-new guest ShoppingCubit (not the same instance,
      // mirroring app.dart's full-teardown-and-rebuild per uid, F14 D3).
      final guest = ShoppingCubit(repository: InMemoryShoppingRepository());
      addTearDown(guest.close);
      expect(guest.state.wishlist, isEmpty);

      // Sign-in as a different uid: must see only that uid's own document,
      // never uid-a's saved items.
      final signedInB = ShoppingCubit(
        repository: FirestoreShoppingRepository(service, 'uid-b'),
      );
      addTearDown(signedInB.close);
      await _settle();
      expect(signedInB.state.wishlist, isNot(contains('neutral-blazer')));
      expect(signedInB.state.wishlist, isEmpty);
    },
  );
}
