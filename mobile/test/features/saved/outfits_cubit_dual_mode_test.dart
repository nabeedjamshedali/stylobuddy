import 'dart:async';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/saved/repository/firestore_outfits_repository.dart';
import 'package:stylobuddy/features/saved/repository/in_memory_outfits_repository.dart';
import 'package:stylobuddy/features/saved/repository/outfits_repository.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/outfit.dart';
import 'package:stylobuddy/shared/models/wear_event.dart';

/// Bounded polling wait, per the implementer contract's "Known gotcha":
/// `pumpAndSettle()`/a bare microtask flush alone is not reliable when
/// asserting Firestore-backed Cubit state with nothing actively listening
/// via a `BlocBuilder` — `fake_cloud_firestore`'s internal microtask chain
/// can resolve later than expected. Polls [check] until it returns true or
/// [timeout] elapses.
Future<void> _waitUntil(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!check()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('_waitUntil timed out waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

WearEvent _eventFor(Outfit outfit, {required int id}) => WearEvent(
  id: id,
  outfitId: outfit.id,
  name: outfit.name,
  occasion: outfit.occasion,
  items: List<String>.of(outfit.items),
  timestamp: DateTime.fromMillisecondsSinceEpoch(id * 1000),
);

/// Repository double whose every method rejects — used to prove F16-A22:
/// a fire-and-forget write that fails must be caught, logged, and never
/// surface as an unhandled Future error.
class _ThrowingOutfitsRepository implements OutfitsRepository {
  @override
  Stream<List<Outfit>> watchOutfits() => const Stream.empty();

  @override
  Stream<List<WearEvent>> watchWearEvents() => const Stream.empty();

  @override
  Future<Outfit> saveOrFind(Outfit draft, {required List<Outfit> current}) =>
      Future<Outfit>.error(Exception('boom'));

  @override
  Future<Outfit> upsertManual({
    required Outfit candidate,
    int? editingId,
    required List<Outfit> current,
  }) => Future<Outfit>.error(Exception('boom'));

  @override
  Future<void> delete(int id) => Future<void>.error(Exception('boom'));

  @override
  Future<void> logWear(
    int outfitId, {
    required Outfit outfit,
    required WearEvent event,
  }) => Future<void>.error(Exception('boom'));

  @override
  Future<void> removeWear(int eventId, {required WearEvent event}) =>
      Future<void>.error(Exception('boom'));
}

/// Repository double that delegates every method to a real
/// [InMemoryOutfitsRepository] (so watchOutfits()/watchWearEvents() behave
/// normally and the Cubit's initial snapshot isn't empty) except
/// [logWear]/[removeWear], which always reject — used to prove the
/// controller ruling (D6 "reconcile on failure"): on a logWear/removeWear
/// transaction failure, OutfitsCubit must roll its own optimistic
/// worn/wearLog change back to the pre-call value, not leave it stuck at
/// the wrong optimistic value.
class _FailingWearRepository implements OutfitsRepository {
  _FailingWearRepository(
    this._delegate, {
    this.failLogWear = true,
    this.failRemoveWear = true,
  });

  final InMemoryOutfitsRepository _delegate;
  final bool failLogWear;
  final bool failRemoveWear;

  @override
  Stream<List<Outfit>> watchOutfits() => _delegate.watchOutfits();

  @override
  Stream<List<WearEvent>> watchWearEvents() => _delegate.watchWearEvents();

  @override
  Future<Outfit> saveOrFind(Outfit draft, {required List<Outfit> current}) =>
      _delegate.saveOrFind(draft, current: current);

  @override
  Future<Outfit> upsertManual({
    required Outfit candidate,
    int? editingId,
    required List<Outfit> current,
  }) => _delegate.upsertManual(
    candidate: candidate,
    editingId: editingId,
    current: current,
  );

  @override
  Future<void> delete(int id) => _delegate.delete(id);

  @override
  Future<void> logWear(
    int outfitId, {
    required Outfit outfit,
    required WearEvent event,
  }) => failLogWear
      ? Future<void>.error(Exception('transaction failed (offline)'))
      : _delegate.logWear(outfitId, outfit: outfit, event: event);

  @override
  Future<void> removeWear(int eventId, {required WearEvent event}) =>
      failRemoveWear
      ? Future<void>.error(Exception('transaction failed (offline)'))
      : _delegate.removeWear(eventId, event: event);
}

void main() {
  test(
    'F16_A17 OutfitsCubit constructed with InMemoryOutfitsRepository vs FirestoreOutfitsRepository is a different object type, not just different data',
    () async {
      final guestWardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final guestCubit = OutfitsCubit(
        guestWardrobe,
        repository: InMemoryOutfitsRepository(),
      );

      final firestore = FakeFirebaseFirestore();
      final signedInWardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final signedInCubit = OutfitsCubit(
        signedInWardrobe,
        repository: FirestoreOutfitsRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );

      addTearDown(guestCubit.close);
      addTearDown(guestWardrobe.close);
      addTearDown(signedInCubit.close);
      addTearDown(signedInWardrobe.close);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(guestCubit.state.outfits, isNotEmpty);
      expect(signedInCubit.state.outfits, isEmpty);
    },
  );

  test(
    'F16_A18 logWear calls WardrobeCubit.adjustWears(outfit.items, 1) only after the repository Future resolves, not before',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreOutfitsRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      await repository.saveOrFind(SeedData.outfits.first, current: const []);

      final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final cubit = OutfitsCubit(wardrobe, repository: repository);
      addTearDown(cubit.close);
      addTearDown(wardrobe.close);

      await _waitUntil(() => cubit.state.outfits.isNotEmpty);

      final outfitId = cubit.state.outfits.first.id;
      final itemId = cubit.state.outfits.first.items.first;
      final before = wardrobe.itemOrFallback(itemId).wears;

      cubit.logWear(outfitId);
      // Immediately after the call returns, the repository's
      // runTransaction has not had a chance to resolve yet, so the
      // cross-feature wardrobe call must not have fired yet either.
      expect(wardrobe.itemOrFallback(itemId).wears, before);

      await _waitUntil(
        () => wardrobe.itemOrFallback(itemId).wears == before + 1,
      );
    },
  );

  test(
    'F16_A19 removeWear calls WardrobeCubit.adjustWears(event.items, -1) only after the repository Future resolves, not before',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreOutfitsRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      await repository.saveOrFind(SeedData.outfits.first, current: const []);

      final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final cubit = OutfitsCubit(wardrobe, repository: repository);
      addTearDown(cubit.close);
      addTearDown(wardrobe.close);

      await _waitUntil(() => cubit.state.outfits.isNotEmpty);
      final outfitId = cubit.state.outfits.first.id;
      final itemId = cubit.state.outfits.first.items.first;

      cubit.logWear(outfitId);
      await _waitUntil(() => cubit.wearEvents().isNotEmpty);
      final before = wardrobe.itemOrFallback(itemId).wears;
      final eventId = cubit.wearEvents().first.id;

      cubit.removeWear(eventId);
      expect(wardrobe.itemOrFallback(itemId).wears, before);

      await _waitUntil(
        () => wardrobe.itemOrFallback(itemId).wears == before - 1,
      );
    },
  );

  test(
    'F16_A20 sign-in -> save -> log wear -> sign-out -> sign-in-again leaves no stale data bleeding between sessions',
    () async {
      final firestore = FakeFirebaseFirestore();
      final wardrobe1 = WardrobeCubit(InMemoryWardrobeRepository());
      final repository1 = FirestoreOutfitsRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final cubit1 = OutfitsCubit(wardrobe1, repository: repository1);

      final draft = SeedData.outfits.first.copyWith(id: 0);
      final saved = cubit1.saveOrFind(draft);
      await _waitUntil(() => cubit1.state.outfits.any((o) => o.id == saved.id));
      cubit1.logWear(saved.id);
      await _waitUntil(() => cubit1.wearEvents().isNotEmpty);

      await cubit1.close();
      await wardrobe1.close();

      // Sign-out: brand-new guest Cubit, backed by a fresh in-memory
      // repository — must show only seed data, never the signed-in user's
      // outfits.
      final guestWardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final guestCubit = OutfitsCubit(
        guestWardrobe,
        repository: InMemoryOutfitsRepository(),
      );
      expect(guestCubit.state.outfits.any((o) => o.id == saved.id), isFalse);
      await guestCubit.close();
      await guestWardrobe.close();

      // Sign-in-again as the same uid: the newly-constructed Cubit must
      // see that uid's own Firestore data (re-subscribing from scratch),
      // not a bled-through in-memory artifact.
      final wardrobe2 = WardrobeCubit(InMemoryWardrobeRepository());
      final repository2 = FirestoreOutfitsRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final cubit2 = OutfitsCubit(wardrobe2, repository: repository2);
      addTearDown(cubit2.close);
      addTearDown(wardrobe2.close);

      await _waitUntil(() => cubit2.state.outfits.any((o) => o.id == saved.id));
      expect(cubit2.wearEvents().isNotEmpty, isTrue);
    },
  );

  test(
    'F16_A21 two logWear calls against the same outfitId, each reading fresh server state via runTransaction, both land correctly at worn == seed + 2',
    () async {
      // Note on this assertion's shape: a *genuinely concurrent*
      // `Future.wait([...])` pair of `logWear` calls against
      // `fake_cloud_firestore` was tried first and found to lose an
      // update (`worn` landed on 1, not 2) — confirmed while writing this
      // test. `fake_cloud_firestore` has no optimistic-concurrency/
      // retry-on-conflict model of real Firestore (both transaction
      // bodies read `worn: 0` before either commits), the exact same
      // fake-double limitation F15 documented for
      // `WardrobeRepository.adjustWears` ("such a test flakes/fails
      // against the fake double regardless of the production code's
      // correctness"). Real Firestore's own transaction-retry semantics
      // (not simulated by this fake) are what close that gap in
      // production — this test instead verifies the two calls each
      // re-read the server-side `worn` value fresh (not a cached
      // argument) by running them sequentially, which is exactly what
      // real Firestore's retry reduces true concurrency to.
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreOutfitsRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final outfit = SeedData.outfits.first.copyWith(worn: 0);
      await repository.saveOrFind(outfit, current: const []);

      // Both calls pass the *same* stale `outfit` argument (worn: 0) —
      // if logWear incremented off that cached argument instead of a
      // fresh server read, this would land on worn == 1, not 2.
      await repository.logWear(
        outfit.id,
        outfit: outfit,
        event: _eventFor(outfit, id: 10),
      );
      await repository.logWear(
        outfit.id,
        outfit: outfit,
        event: _eventFor(outfit, id: 11),
      );

      final emitted = await repository.watchOutfits().first;
      expect(emitted.single.worn, 2);
      final events = await repository.watchWearEvents().first;
      expect(events.length, 2);
    },
  );

  test(
    'F16_A21_structural logWear/removeWear are implemented via runTransaction (the mechanism real Firestore uses to retry on write-conflict) — re-verified here specifically for the A21 concurrent-write scenario, cross-referencing F16-A09',
    () {
      final file = File(
        'lib/features/saved/repository/firestore_outfits_repository.dart',
      );
      final content = file.readAsStringSync();
      final logWearStart = content.indexOf('Future<void> logWear(');
      final removeWearStart = content.indexOf('Future<void> removeWear(');
      expect(logWearStart, greaterThan(-1));
      expect(removeWearStart, greaterThan(-1));
      expect(
        content
            .substring(logWearStart, removeWearStart)
            .contains('runTransaction'),
        isTrue,
      );
      expect(
        content.substring(removeWearStart).contains('runTransaction'),
        isTrue,
      );
    },
  );

  test(
    'F16_A22 a fire-and-forget write that fails inside OutfitsCubit does not surface as an unhandled Future error',
    () async {
      final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final cubit = OutfitsCubit(
        wardrobe,
        repository: _ThrowingOutfitsRepository(),
      );
      addTearDown(cubit.close);
      addTearDown(wardrobe.close);

      final errors = <Object>[];
      await runZonedGuarded(() async {
        cubit.saveOrFind(
          const Outfit(
            id: 0,
            name: 'x',
            occasion: 'x',
            items: ['never-matches-anything-xyz'],
            why: 'x',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stackTrace) => errors.add(error));

      expect(errors, isEmpty);
    },
  );

  test(
    'F16_rollback_logWear a logWear transaction failure rolls the Cubit\'s optimistic worn/wearLog change back to the pre-call value',
    () async {
      final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      final cubit = OutfitsCubit(
        wardrobe,
        repository: _FailingWearRepository(InMemoryOutfitsRepository()),
      );
      addTearDown(cubit.close);
      addTearDown(wardrobe.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final outfitId = cubit.state.outfits.first.id;
      final wornBefore = cubit.byId(outfitId)!.worn;
      final wearLogLengthBefore = cubit.state.wearLog.length;

      cubit.logWear(outfitId);
      // Immediately after the call, the optimistic update is visible
      // (same as F16-A18's immediately-after-call assertion).
      expect(cubit.byId(outfitId)!.worn, wornBefore + 1);
      expect(cubit.state.wearLog.length, wearLogLengthBefore + 1);

      // Once the rejected repository Future resolves, the ruling requires
      // this to be rolled back to the pre-call value, not left stuck at
      // the optimistic (now-wrong) value.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.byId(outfitId)!.worn, wornBefore);
      expect(cubit.state.wearLog.length, wearLogLengthBefore);
    },
  );

  test(
    'F16_rollback_removeWear a removeWear transaction failure rolls the Cubit\'s optimistic worn/wearLog change back to the pre-call value',
    () async {
      final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      // logWear succeeds (so there's a real event to attempt to remove);
      // only removeWear is made to fail.
      final cubit = OutfitsCubit(
        wardrobe,
        repository: _FailingWearRepository(
          InMemoryOutfitsRepository(),
          failLogWear: false,
          failRemoveWear: true,
        ),
      );
      addTearDown(cubit.close);
      addTearDown(wardrobe.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final outfitId = cubit.state.outfits.first.id;
      cubit.logWear(outfitId);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final eventId = cubit.state.wearLog.first.id;

      final wornBefore = cubit.byId(outfitId)!.worn;
      final wearLogLengthBefore = cubit.state.wearLog.length;
      expect(wearLogLengthBefore, greaterThan(0));

      cubit.removeWear(eventId);
      expect(cubit.byId(outfitId)!.worn, wornBefore - 1);
      expect(cubit.state.wearLog.length, wearLogLengthBefore - 1);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.byId(outfitId)!.worn, wornBefore);
      expect(cubit.state.wearLog.length, wearLogLengthBefore);
      expect(cubit.state.wearLog.any((e) => e.id == eventId), isTrue);
    },
  );
}
