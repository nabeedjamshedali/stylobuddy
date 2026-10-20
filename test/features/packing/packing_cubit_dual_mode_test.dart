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

/// Repository double whose [watchTrips] deliberately NEVER emits
/// (`Stream.empty()`) — used to prove the targeted-rollback requirements
/// (F20-A09/A10) without the confound the reviewer identified in the first
/// round: delegating to a real [InMemoryPackingRepository] meant its
/// write-driven re-emission reset `PackingCubit.state` regardless of what
/// the rollback code under test actually did (disabling the rollback
/// entirely, or substituting a whole-list restore, both still passed). By
/// construction, the *only* thing that can ever change
/// `PackingCubit.state.trips` while this double backs it is (a) this
/// Cubit's own optimistic update, or (b) this Cubit's own targeted
/// rollback on a failure — never a snapshot "arriving from the backend",
/// because none ever does.
///
/// [saveTrip]'s edit branch (`isNew: false`) fails, after [failDelay], for
/// any trip id in [failingSaveTripIds]; every other call succeeds
/// immediately with no side effect on any stream.
///
/// [toggle] fails, after [failDelay], the next N times it is called for a
/// given `tripId:key` pair, where N is set via [failToggleOnce] (or
/// [failToggleTimes]) — this lets a test arm exactly the FIRST of two
/// rapid, same-key toggle calls to fail while a SECOND call for the same
/// key succeeds immediately, deterministically landing before the first
/// call's delayed failure/rollback fires.
class _ControllableFailRepository implements PackingRepository {
  _ControllableFailRepository({
    this.failDelay = const Duration(milliseconds: 40),
  });

  final Duration failDelay;
  final Set<String> failingSaveTripIds = {};
  final Map<String, int> _toggleFailuresRemaining = {};

  void failToggleOnce(String tripId, String key) =>
      failToggleTimes(tripId, key, 1);

  void failToggleTimes(String tripId, String key, int times) =>
      _toggleFailuresRemaining['$tripId:$key'] = times;

  @override
  Stream<List<Trip>> watchTrips() => const Stream.empty();

  @override
  Future<void> saveTrip(Trip trip, {required bool isNew}) async {
    if (!isNew && failingSaveTripIds.contains(trip.id)) {
      await Future<void>.delayed(failDelay);
      throw Exception('saveTrip failed (offline)');
    }
  }

  @override
  Future<void> toggle(String tripId, String key) async {
    final mapKey = '$tripId:$key';
    final remaining = _toggleFailuresRemaining[mapKey] ?? 0;
    if (remaining > 0) {
      _toggleFailuresRemaining[mapKey] = remaining - 1;
      await Future<void>.delayed(failDelay);
      throw Exception('toggle failed (offline)');
    }
  }

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
    'F20_A04 PackingCubit() with no repository argument defaults to '
    'InMemoryPackingRepository, preserving the pre-existing guest-mode '
    'behavior this task must leave unchanged — the full pre-existing '
    'packing suite (packing_cubit_test.dart, packing_screens_test.dart) '
    'exercises exactly this default construction path, unmodified, '
    'against this same default',
    () {
      final cubit = PackingCubit();
      addTearDown(cubit.close);
      // Pre-existing, pre-this-task default: a guest's very first frame
      // shows zero trips, synchronously (no repository argument supplied).
      expect(cubit.state.trips, isEmpty);
      expect(cubit.state.selectedTripId, isNull);
    },
  );

  test(
    'F20_A11_cubit a signed-in PackingCubit (FirestorePackingRepository) '
    'shows a trip seeded directly in that uid\'s Firestore data, while a '
    'guest PackingCubit (InMemoryPackingRepository) never shows it — not '
    'merely "different data from each other", but the specific seeded '
    'document only ever surfacing through the signed-in Cubit',
    () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users/uid-1/packingTrips')
          .doc('seeded-trip')
          .set({
            'id': 'seeded-trip',
            'name': 'Seeded Firestore Trip',
            'destination': 'Rome',
            'start': '2026-12-01',
            'end': '2026-12-05',
            'type': 'Vacation',
            'notes': '',
            'days': 5,
            'items': <Map<String, dynamic>>[],
          });

      final guestCubit = PackingCubit(repository: InMemoryPackingRepository());
      addTearDown(guestCubit.close);

      final signedInCubit = PackingCubit(
        repository: FirestorePackingRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );
      addTearDown(signedInCubit.close);

      await _waitUntil(() => signedInCubit.state.trips.isNotEmpty);

      expect(
        guestCubit.state.trips.any((t) => t.id == 'seeded-trip'),
        isFalse,
      );
      expect(
        signedInCubit.state.trips.any((t) => t.id == 'seeded-trip'),
        isTrue,
      );
    },
  );

  test(
    'F20_A09 PackingCubit.toggle optimistically updates state before the '
    'repository Future resolves, then rolls back ONLY that one item\'s '
    'packed flag on that one trip when the call fails — proven confound-free '
    '(the repository double\'s watchTrips() never emits, so nothing but the '
    'Cubit\'s own optimistic update/rollback can ever change state) against '
    'a second, concurrently-succeeding toggle on a DIFFERENT trip',
    () async {
      final repository = _ControllableFailRepository();
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
      repository.failToggleOnce(trip1Id, key1);

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
    'F20_A09_captured_value toggle\'s rollback restores the value CAPTURED '
    'before the failing call, not a re-flip of whatever the current value '
    'happens to be at failure time — proven by a second toggle of the SAME '
    'key landing and succeeding before the first (slower, failing) call\'s '
    'rollback fires: the old `packed: !i.packed` re-flip would wrongly '
    'invert the second call\'s already-correct result, while restoring the '
    'captured original value is a correct no-op here',
    () async {
      final repository = _ControllableFailRepository(
        failDelay: const Duration(milliseconds: 40),
      );
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
      final tripId = cubit.state.selectedTripId!;
      cubit.generateChecklist(SeedData.items);
      final key = cubit.state.selectedTrip!.items.first.key;
      final originalPacked = cubit.state.selectedTrip!.items.first.packed;
      expect(originalPacked, isFalse);

      // Only the FIRST call to toggle(tripId, key) fails (after a delay);
      // any subsequent call for the same key succeeds immediately.
      repository.failToggleOnce(tripId, key);

      cubit.toggle(key); // call 1: false -> true, will fail after 40ms.
      expect(
        cubit.state.selectedTrip!.items
            .firstWhere((i) => i.key == key)
            .packed,
        isTrue,
      );

      cubit.toggle(key); // call 2: true -> false, succeeds immediately.
      expect(
        cubit.state.selectedTrip!.items
            .firstWhere((i) => i.key == key)
            .packed,
        isFalse,
      );

      // Wait comfortably past call 1's failDelay so its rollback has
      // unambiguously already run.
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Must still be false: call 1's captured pre-call value was false.
      // The old `packed: !i.packed` re-flip would instead invert the
      // CURRENT value (false, from call 2's successful result) to true —
      // silently undoing call 2's already-correct, already-succeeded
      // change with no further correction ever arriving.
      expect(
        cubit.state.trips
            .firstWhere((t) => t.id == tripId)
            .items
            .firstWhere((i) => i.key == key)
            .packed,
        isFalse,
      );
    },
  );

  test(
    'F20_A10 an interleaved saveDraft (edit) call that will fail, '
    'concurrent with a DIFFERENT trip\'s successful toggle, reverts only '
    'the failed trip\'s detail fields — the other trip\'s concurrently-'
    'succeeding items change survives untouched — proven confound-free',
    () async {
      final repository = _ControllableFailRepository();
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
      repository.failingSaveTripIds.add(trip1Id);

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
    'F20_A10_same_trip a failed saveDraft (edit) on trip 1, concurrent with '
    'a SUCCESSFUL toggle on that SAME trip 1, reverts only the edit\'s '
    'detail fields and leaves trip 1\'s items (including the concurrent '
    'toggle) completely untouched — the whole-trip-restore bug class '
    'reproduced: the old `existing` (captured BEFORE the edit call, so '
    'before the toggle too) would wipe the toggle out entirely',
    () async {
      final repository = _ControllableFailRepository();
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
      final tripId = cubit.state.selectedTripId!;
      cubit.generateChecklist(SeedData.items);
      final key = cubit.state.selectedTrip!.items.first.key;
      final beforePacked = cubit.state.selectedTrip!.items.first.packed;

      repository.failingSaveTripIds.add(tripId);

      // The edit call captures `existing` (trip 1, with its current items)
      // synchronously here, before the concurrent toggle below ever runs.
      cubit.editTrip(tripId);
      cubit.saveDraft(
        name: 'Trip 1 renamed',
        destination: 'Changed',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      // Still selected on the same trip — toggle its item right after,
      // before the edit's delayed failure/rollback fires.
      cubit.selectTrip(tripId);
      cubit.toggle(key);
      expect(
        cubit.state.selectedTrip!.items.firstWhere((i) => i.key == key).packed,
        !beforePacked,
      );

      await _waitUntil(
        () => cubit.state.trips.firstWhere((t) => t.id == tripId).name == 'Trip 1',
      );

      final after = cubit.state.trips.firstWhere((t) => t.id == tripId);
      // The edit's detail fields are reverted...
      expect(after.destination, 'Original');
      // ...but the concurrent, already-succeeded toggle on this SAME trip
      // must survive the edit's rollback — never wiped by restoring the
      // whole pre-edit `existing` trip (items included).
      expect(after.items.firstWhere((i) => i.key == key).packed, !beforePacked);
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

  test(
    'F20_A08_cubit saveDraft (edit) and toggle issued THROUGH PackingCubit '
    '(not repository-to-repository) concurrently against the SAME trip '
    'both persist: a fresh FirestorePackingRepository instance, reading '
    'directly off the same backing Firestore data, shows the edited detail '
    'fields AND the toggled item together',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestorePackingRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final cubit = PackingCubit(repository: repository);
      addTearDown(cubit.close);

      cubit.newTrip();
      cubit.saveDraft(
        name: 'Lisbon getaway',
        destination: 'Lisbon',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      final tripId = cubit.state.selectedTripId!;
      await _waitUntil(() => cubit.state.trips.isNotEmpty);

      cubit.generateChecklist(SeedData.items);
      // Let generateChecklist's own transaction land before arming the
      // concurrent edit+toggle below.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final key = cubit.state.selectedTrip!.items.first.key;

      // Concurrent, both fire-and-forget from the Cubit's perspective:
      // one edits name/destination, the other toggles an item.
      cubit.editTrip(tripId);
      cubit.saveDraft(
        name: 'Lisbon renamed',
        destination: 'Porto',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      cubit.selectTrip(tripId);
      cubit.toggle(key);

      // Give both underlying Firestore writes time to land, then read
      // directly off the backing Firestore data via a brand-new repository
      // instance — proving the ACTUAL persisted document, not merely the
      // Cubit's own optimistic local state.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final freshRepository = FirestorePackingRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final trips = await freshRepository.watchTrips().first;
      final trip = trips.single;
      expect(trip.name, 'Lisbon renamed');
      expect(trip.destination, 'Porto');
      expect(trip.items.firstWhere((i) => i.key == key).packed, isTrue);
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
