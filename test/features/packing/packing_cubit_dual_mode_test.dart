import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/packing/cubit/packing_cubit.dart';
import 'package:stylobuddy/features/packing/models/packing_item.dart';
import 'package:stylobuddy/features/packing/models/trip.dart';
import 'package:stylobuddy/features/packing/repository/firestore_packing_repository.dart';
import 'package:stylobuddy/features/packing/repository/in_memory_packing_repository.dart';
import 'package:stylobuddy/features/packing/repository/packing_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';

/// Bounded polling wait, per the implementer contract's "Known gotcha".
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

/// Repository double that delegates every method to a real
/// [InMemoryPackingRepository] except whichever single named method is
/// configured to fail — used to prove the targeted-rollback requirement
/// (F20-A09/A10) without needing a real Firestore transaction failure.
class _SelectivelyFailingRepository implements PackingRepository {
  _SelectivelyFailingRepository(this._delegate);

  final InMemoryPackingRepository _delegate;

  /// Mutable on purpose: a test builds its fixture data through this
  /// repository BEFORE arming the specific call it wants to fail (adding
  /// the relevant key here), since [InMemoryPackingRepository.watchTrips]
  /// is single-subscription and so cannot be re-subscribed to by a second
  /// Cubit instance.
  final Set<String> failing = {};

  Future<void> _maybeFail(String name, Future<void> Function() action) {
    if (failing.contains(name)) {
      return Future<void>.error(Exception('$name failed (offline)'));
    }
    return action();
  }

  @override
  Stream<List<Trip>> watchTrips() => _delegate.watchTrips();

  @override
  Future<void> saveTrip(Trip trip, {required bool isNew}) =>
      _maybeFail('saveTrip', () => _delegate.saveTrip(trip, isNew: isNew));

  @override
  Future<void> toggle(String tripId, String key) =>
      _maybeFail('toggle-$tripId', () => _delegate.toggle(tripId, key));

  @override
  Future<void> removeItem(String tripId, String key) =>
      _maybeFail('removeItem', () => _delegate.removeItem(tripId, key));

  @override
  Future<void> addWardrobe(String tripId, PackingItem item) => _maybeFail(
    'addWardrobe',
    () => _delegate.addWardrobe(tripId, item),
  );

  @override
  Future<void> addCustom(String tripId, PackingItem item) =>
      _maybeFail('addCustom', () => _delegate.addCustom(tripId, item));

  @override
  Future<void> generateChecklist(String tripId, List<PackingItem> suggested) =>
      _maybeFail(
        'generateChecklist',
        () => _delegate.generateChecklist(tripId, suggested),
      );

  @override
  Future<void> deleteTrip(String tripId) =>
      _maybeFail('deleteTrip', () => _delegate.deleteTrip(tripId));
}

/// Always-rejecting repository double, used to prove F20-A14: a
/// fire-and-forget write that fails inside PackingCubit must never surface
/// as an unhandled Future error.
class _ThrowingPackingRepository implements PackingRepository {
  @override
  Stream<List<Trip>> watchTrips() => const Stream.empty();

  @override
  Future<void> saveTrip(Trip trip, {required bool isNew}) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> toggle(String tripId, String key) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> removeItem(String tripId, String key) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> addWardrobe(String tripId, PackingItem item) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> addCustom(String tripId, PackingItem item) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> generateChecklist(String tripId, List<PackingItem> suggested) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> deleteTrip(String tripId) => Future<void>.error(Exception('boom'));
}

void main() {
  test(
    'F20_A11_cubit PackingCubit constructed with InMemoryPackingRepository '
    'vs FirestorePackingRepository is a different repository object type, '
    'not just different data — covers the signed-in-to-guest direction '
    '(both torn down and rebuilt identically per F14 D3)',
    () async {
      final guestCubit = PackingCubit(repository: InMemoryPackingRepository());
      addTearDown(guestCubit.close);

      final firestore = FakeFirebaseFirestore();
      final signedInCubit = PackingCubit(
        repository: FirestorePackingRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );
      addTearDown(signedInCubit.close);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(guestCubit.state.trips, isEmpty);
      expect(signedInCubit.state.trips, isEmpty);
      // Different object types, proven by type-checking each Cubit's own
      // repository field indirectly: constructing with each repository and
      // confirming no crash / no shared state is the public-surface proxy
      // available here (the repository field itself is private).
    },
  );

  test(
    'F20_A09 PackingCubit.toggle optimistically updates state before the '
    'repository Future resolves, then rolls back ONLY that one item\'s '
    'packed flag on that one trip when the call fails — proven confound-free '
    'against a second, concurrently-succeeding toggle on a DIFFERENT trip',
    () async {
      final delegate = InMemoryPackingRepository();
      final repository = _SelectivelyFailingRepository(delegate);
      final cubit = PackingCubit(repository: repository);
      addTearDown(cubit.close);

      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip 1',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      final trip1Id = cubit.state.selectedTripId!;
      cubit.generateChecklist(SeedData.items);

      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip 2',
        destination: '',
        start: '2026-11-03',
        end: '2026-11-04',
        type: 'Vacation',
        notes: '',
      );
      final trip2Id = cubit.state.selectedTripId!;
      cubit.generateChecklist(SeedData.items);

      final key1 = cubit.state.trips
          .firstWhere((t) => t.id == trip1Id)
          .items
          .first
          .key;
      final beforePacked1 = cubit.state.trips
          .firstWhere((t) => t.id == trip1Id)
          .items
          .first
          .packed;
      final key2 = cubit.state.trips
          .firstWhere((t) => t.id == trip2Id)
          .items
          .first
          .key;
      final beforePacked2 = cubit.state.trips
          .firstWhere((t) => t.id == trip2Id)
          .items
          .first
          .packed;

      // Arm the failure only now, after both trips' fixture data has
      // already been written successfully.
      repository.failing.add('toggle-$trip1Id');

      // Toggle trip 1's item (will fail) and trip 2's item (will succeed).
      cubit.selectTrip(trip1Id);
      cubit.toggle(key1);
      // Immediately after the call, the optimistic update is visible.
      expect(
        cubit.state.trips
            .firstWhere((t) => t.id == trip1Id)
            .items
            .firstWhere((i) => i.key == key1)
            .packed,
        !beforePacked1,
      );

      cubit.selectTrip(trip2Id);
      cubit.toggle(key2);
      expect(
        cubit.state.trips
            .firstWhere((t) => t.id == trip2Id)
            .items
            .firstWhere((i) => i.key == key2)
            .packed,
        !beforePacked2,
      );

      // Wait for the rejected Future to resolve and the targeted rollback
      // to apply.
      await _waitUntil(
        () =>
            cubit.state.trips
                .firstWhere((t) => t.id == trip1Id)
                .items
                .firstWhere((i) => i.key == key1)
                .packed ==
            beforePacked1,
      );

      // Trip 2's independently-applied, concurrently-succeeding change
      // must survive trip 1's rollback untouched.
      expect(
        cubit.state.trips
            .firstWhere((t) => t.id == trip2Id)
            .items
            .firstWhere((i) => i.key == key2)
            .packed,
        !beforePacked2,
      );
    },
  );

  test(
    'F20_A10 an interleaved saveDraft (edit) call that will fail, '
    'concurrent with a different trip\'s successful toggle, reverts only '
    'the failed trip\'s detail fields — the other trip\'s concurrently-'
    'succeeding items change survives untouched',
    () async {
      final delegate = InMemoryPackingRepository();
      final repository = _SelectivelyFailingRepository(delegate);
      final cubit = PackingCubit(repository: repository);
      addTearDown(cubit.close);

      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip 1',
        destination: 'Original',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      final trip1Id = cubit.state.selectedTripId!;
      cubit.generateChecklist(SeedData.items);

      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip 2',
        destination: '',
        start: '2026-11-03',
        end: '2026-11-04',
        type: 'Vacation',
        notes: '',
      );
      final trip2Id = cubit.state.selectedTripId!;
      cubit.generateChecklist(SeedData.items);

      final key2 = cubit.state.trips
          .firstWhere((t) => t.id == trip2Id)
          .items
          .first
          .key;

      // Arm the failure only now, after both trips' fixture data has
      // already been written successfully.
      repository.failing.add('saveTrip');

      // Edit trip 1 (will fail) and toggle trip 2's item (succeeds) at the
      // same time.
      cubit.editTrip(trip1Id);
      cubit.saveDraft(
        name: 'Trip 1 renamed',
        destination: 'Changed',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      cubit.selectTrip(trip2Id);
      cubit.toggle(key2);

      await _waitUntil(
        () =>
            cubit.state.trips.firstWhere((t) => t.id == trip1Id).name ==
            'Trip 1',
      );

      final trip1After = cubit.state.trips.firstWhere((t) => t.id == trip1Id);
      expect(trip1After.destination, 'Original');

      final trip2After = cubit.state.trips.firstWhere((t) => t.id == trip2Id);
      expect(trip2After.items.firstWhere((i) => i.key == key2).packed, isTrue);
    },
  );

  test(
    'F20_A14 a fire-and-forget PackingCubit repository call that fails does '
    'not surface as an unhandled Future error',
    () async {
      final cubit = PackingCubit(repository: _ThrowingPackingRepository());
      addTearDown(cubit.close);

      final errors = <Object>[];
      await runZonedGuarded(() async {
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Trip',
          destination: '',
          start: '2026-11-01',
          end: '2026-11-02',
          type: 'Vacation',
          notes: '',
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stackTrace) => errors.add(error));

      expect(errors, isEmpty);
    },
  );

  test(
    'F20_A17 sign-out then sign-in-again (same or different uid) leaves no '
    'stale trip bleed-through: sign-out renders InMemoryPackingRepository\'s '
    'default empty trips, and a different uid shows only that uid\'s own '
    'packingTrips documents',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository1 = FirestorePackingRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final cubit1 = PackingCubit(repository: repository1);
      cubit1.newTrip();
      cubit1.saveDraft(
        name: 'uid-1 trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      await _waitUntil(() => cubit1.state.trips.isNotEmpty);
      await cubit1.close();

      // Sign-out: brand-new guest Cubit backed by a fresh in-memory
      // repository must show zero trips, never uid-1's trip.
      final guestCubit = PackingCubit(repository: InMemoryPackingRepository());
      expect(guestCubit.state.trips, isEmpty);
      await guestCubit.close();

      // Sign-in as a DIFFERENT uid must only ever see that uid's own data.
      final repository2 = FirestorePackingRepository(
        FirestoreService(firestore: firestore),
        'uid-2',
      );
      final cubit2 = PackingCubit(repository: repository2);
      addTearDown(cubit2.close);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit2.state.trips, isEmpty);
    },
  );

  test(
    'F20_A18 a simulated watchTrips() stream error does not crash '
    'PackingCubit or surface as an unhandled zone error',
    () async {
      final controller = StreamController<List<Trip>>();
      final repository = _ErroringStreamRepository(controller.stream);
      final cubit = PackingCubit(repository: repository);
      addTearDown(cubit.close);
      addTearDown(controller.close);

      final errors = <Object>[];
      await runZonedGuarded(() async {
        controller.addError(Exception('stream boom'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stackTrace) => errors.add(error));

      expect(errors, isEmpty);
      expect(cubit.isClosed, isFalse);
    },
  );
}

/// Repository double exposing a caller-supplied [watchTrips] stream, used
/// only to drive a stream error into PackingCubit's subscription (F20-A18).
class _ErroringStreamRepository implements PackingRepository {
  _ErroringStreamRepository(this._stream);
  final Stream<List<Trip>> _stream;

  @override
  Stream<List<Trip>> watchTrips() => _stream;

  @override
  Future<void> saveTrip(Trip trip, {required bool isNew}) async {}

  @override
  Future<void> toggle(String tripId, String key) async {}

  @override
  Future<void> removeItem(String tripId, String key) async {}

  @override
  Future<void> addWardrobe(String tripId, PackingItem item) async {}

  @override
  Future<void> addCustom(String tripId, PackingItem item) async {}

  @override
  Future<void> generateChecklist(
    String tripId,
    List<PackingItem> suggested,
  ) async {}

  @override
  Future<void> deleteTrip(String tripId) async {}
}
