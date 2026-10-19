import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/calendar/cubit/planner_cubit.dart';
import 'package:stylobuddy/features/calendar/repository/firestore_planner_repository.dart';
import 'package:stylobuddy/features/calendar/repository/in_memory_planner_repository.dart';
import 'package:stylobuddy/features/calendar/repository/planner_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';

/// Bounded polling wait, per the implementer contract's "Known gotcha":
/// a bare microtask flush alone is not reliable when asserting
/// Firestore-backed Cubit state with nothing actively listening via a
/// `BlocBuilder`.
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

/// Repository double whose every method rejects — used to prove F17-A15:
/// a fire-and-forget write that fails must be caught, logged, and never
/// surface as an unhandled Future error.
class _ThrowingPlannerRepository implements PlannerRepository {
  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() => const Stream.empty();

  @override
  Future<void> plan(String key, PlannedEntry entry) =>
      Future<void>.error(Exception('boom'));

  @override
  Future<void> remove(String key) => Future<void>.error(Exception('boom'));
}

/// Repository double that delegates to a real [InMemoryPlannerRepository]
/// (so watchPlanned() behaves normally and the Cubit's initial snapshot
/// isn't empty) except [plan]/[remove], which can be made to always
/// reject — used to prove the controller ruling (D6 "reconcile on
/// failure"): on a plan/remove failure, PlannerCubit must roll its own
/// optimistic `state.planned` change back to the pre-call value.
class _FailingPlannerRepository implements PlannerRepository {
  _FailingPlannerRepository(
    this._delegate, {
    this.failPlan = false,
    this.failRemove = false,
  });

  final InMemoryPlannerRepository _delegate;
  final bool failPlan;
  final bool failRemove;

  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() => _delegate.watchPlanned();

  @override
  Future<void> plan(String key, PlannedEntry entry) => failPlan
      ? Future<void>.error(Exception('write failed (offline)'))
      : _delegate.plan(key, entry);

  @override
  Future<void> remove(String key) => failRemove
      ? Future<void>.error(Exception('write failed (offline)'))
      : _delegate.remove(key);
}

/// Repository double that delegates every call to a real
/// [InMemoryPlannerRepository] except [plan] for one specific [failingKey],
/// which rejects after [failDelay] — used to prove the targeted (per-key)
/// rollback ruling: a concurrent `plan()` for a *different* key that
/// resolves successfully while the failing key's write is still pending
/// must survive the failing key's rollback untouched.
class _KeySpecificFailingPlannerRepository implements PlannerRepository {
  _KeySpecificFailingPlannerRepository(
    this._delegate, {
    required this.failingKey,
    required this.failDelay,
  });

  final InMemoryPlannerRepository _delegate;
  final String failingKey;
  final Duration failDelay;

  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() => _delegate.watchPlanned();

  @override
  Future<void> plan(String key, PlannedEntry entry) async {
    if (key == failingKey) {
      await Future<void>.delayed(failDelay);
      throw Exception('write failed (offline)');
    }
    return _delegate.plan(key, entry);
  }

  @override
  Future<void> remove(String key) => _delegate.remove(key);
}

/// Repository double that fails the test if [plan]/[remove] is ever
/// invoked — used to prove F17-A18: the transient-field Cubit methods
/// never touch the repository. [watchPlanned] itself must still return a
/// benign stream (PlannerCubit's own constructor always subscribes to it,
/// which is expected/required behavior, not part of what this assertion
/// is checking).
class _FailOnAnyCallPlannerRepository implements PlannerRepository {
  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() => const Stream.empty();

  @override
  Future<void> plan(String key, PlannedEntry entry) {
    fail('plan() must not be called by a transient-field-only method');
  }

  @override
  Future<void> remove(String key) {
    fail('remove() must not be called by a transient-field-only method');
  }
}

void main() {
  test(
    'F17_A11_cubit a signed-in PlannerCubit (FirestorePlannerRepository) '
    'never shows the guest-mode seed plan — it starts empty, not merely '
    'different data from the guest Cubit',
    () async {
      final guestCubit = PlannerCubit(
        repository: InMemoryPlannerRepository(),
      );

      final firestore = FakeFirebaseFirestore();
      final signedInCubit = PlannerCubit(
        repository: FirestorePlannerRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );

      addTearDown(guestCubit.close);
      addTearDown(signedInCubit.close);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(guestCubit.state.planned, isNotEmpty);
      expect(signedInCubit.state.planned, isEmpty);
      // Not just empty in aggregate — none of the guest-mode seed plan's
      // own keys leaked into the signed-in Cubit's state either.
      for (final key in SeedData.planned.keys) {
        expect(signedInCubit.state.planned.containsKey(key), isFalse);
      }
    },
  );

  test(
    'F17_A12_cubit sign-in -> plan -> sign-out -> sign-in-again leaves no stale planned-entry data bleeding between sessions',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository1 = FirestorePlannerRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final cubit1 = PlannerCubit(repository: repository1);

      cubit1.plan(
        '2026-12-01',
        const PlannedEntry(outfitId: 5, occasion: 'Holiday'),
      );
      await _waitUntil(
        () => cubit1.state.planned.containsKey('2026-12-01'),
      );
      await cubit1.close();

      // Sign-out: a brand-new guest Cubit, backed by a fresh in-memory
      // repository, must show only the seed plan, never the signed-in
      // user's plans, and never an empty map either.
      final guestCubit = PlannerCubit(
        repository: InMemoryPlannerRepository(),
      );
      expect(
        guestCubit.state.planned.containsKey('2026-12-01'),
        isFalse,
      );
      expect(guestCubit.state.planned, isNotEmpty);
      await guestCubit.close();

      // Sign-in-again as the same uid: the newly-constructed Cubit must
      // re-subscribe from scratch and see that uid's own Firestore data.
      final repository2 = FirestorePlannerRepository(
        FirestoreService(firestore: firestore),
        'uid-1',
      );
      final cubit2 = PlannerCubit(repository: repository2);
      addTearDown(cubit2.close);

      await _waitUntil(
        () => cubit2.state.planned.containsKey('2026-12-01'),
      );
      expect(cubit2.state.planned['2026-12-01']!.outfitId, 5);
      // Same guarantee as F17_A11_cubit: no guest-mode seed-plan key ever
      // bleeds into a signed-in Cubit's state.
      for (final key in SeedData.planned.keys) {
        expect(cubit2.state.planned.containsKey(key), isFalse);
      }
    },
  );

  test(
    'F17_A13 plan optimistically updates state.planned before the repository Future resolves, then rolls back to the pre-call value on a simulated failure',
    () async {
      final cubit = PlannerCubit(
        repository: _FailingPlannerRepository(
          InMemoryPlannerRepository(),
          failPlan: true,
        ),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final before = cubit.state.planned;
      expect(before.containsKey('2026-10-20'), isFalse);

      cubit.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 2, occasion: 'Casual'),
      );
      // Immediately after the call, the optimistic update is visible.
      expect(cubit.state.planned['2026-10-20']!.outfitId, 2);

      // Once the rejected repository Future resolves, the ruling requires
      // this to be rolled back to the pre-call value.
      await _waitUntil(
        () => !cubit.state.planned.containsKey('2026-10-20'),
      );
      expect(cubit.state.planned, before);
    },
  );

  test(
    'F17_A14 remove optimistically removes the key from state.planned before the repository Future resolves, then restores it on a simulated failure',
    () async {
      final cubit = PlannerCubit(
        repository: _FailingPlannerRepository(
          InMemoryPlannerRepository(),
          failRemove: true,
        ),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final before = cubit.state.planned;
      expect(before.containsKey('2026-10-15'), isTrue);

      cubit.remove('2026-10-15');
      // Immediately after the call, the optimistic removal is visible.
      expect(cubit.state.planned.containsKey('2026-10-15'), isFalse);

      // Once the rejected repository Future resolves, the removed entry
      // must be restored rather than left permanently missing.
      await _waitUntil(
        () => cubit.state.planned.containsKey('2026-10-15'),
      );
      expect(cubit.state.planned, before);
    },
  );

  test(
    'F17_A13_targeted_revert a plan(A) rollback after a slower failing write '
    'reverts only key A and never clobbers a concurrent plan(B) that '
    'succeeded in the meantime',
    () async {
      final delegate = InMemoryPlannerRepository();
      final cubit = PlannerCubit(
        repository: _KeySpecificFailingPlannerRepository(
          delegate,
          failingKey: '2026-10-20',
          failDelay: const Duration(milliseconds: 40),
        ),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // A: optimistic write that will fail after a delay.
      cubit.plan(
        '2026-10-20',
        const PlannedEntry(outfitId: 2, occasion: 'Casual'),
      );
      // B: issued before A's write resolves, and succeeds quickly.
      cubit.plan(
        '2026-10-21',
        const PlannedEntry(outfitId: 3, occasion: 'Formal'),
      );

      await _waitUntil(
        () => cubit.state.planned.containsKey('2026-10-21'),
      );
      // B must have landed before A's rollback fires.
      expect(cubit.state.planned['2026-10-21']!.outfitId, 3);

      // Wait for A's rollback to fire.
      await _waitUntil(
        () => !cubit.state.planned.containsKey('2026-10-20'),
      );

      // B's entry must still be present — a full-map rollback of A's
      // failure would have wiped it out.
      expect(cubit.state.planned['2026-10-21']!.outfitId, 3);
    },
  );

  test(
    'F17_A15 a fire-and-forget write that fails inside PlannerCubit does not surface as an unhandled Future error',
    () async {
      final cubit = PlannerCubit(
        repository: _ThrowingPlannerRepository(),
      );
      addTearDown(cubit.close);

      final errors = <Object>[];
      await runZonedGuarded(() async {
        cubit.plan(
          '2026-10-20',
          const PlannedEntry(outfitId: 2, occasion: 'Casual'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        cubit.remove('2026-10-20');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stackTrace) => errors.add(error));

      expect(errors, isEmpty);
    },
  );

  test(
    'F17_A16 a simulated watchPlanned() stream error does not crash PlannerCubit or surface as an unhandled zone error',
    () async {
      final controller = StreamController<Map<String, PlannedEntry>>();
      addTearDown(controller.close);
      final repository = _StreamPlannerRepository(controller.stream);

      final errors = <Object>[];
      PlannerCubit? cubit;
      await runZonedGuarded(() async {
        cubit = PlannerCubit(repository: repository);
        controller.add(const {
          '2026-10-20': PlannedEntry(outfitId: 2, occasion: 'Casual'),
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));
        controller.addError(Exception('stream boom'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stackTrace) => errors.add(error));

      expect(errors, isEmpty);
      // The Cubit survives and keeps its last-known-good state.
      expect(cubit!.state.planned['2026-10-20']!.outfitId, 2);
      await cubit!.close();
    },
  );

  test(
    'F17_A17 state.planned[key] missing is distinct from a present PlannedEntry whose occasion is empty — both are constructible and never confused',
    () async {
      final cubit = PlannerCubit(repository: InMemoryPlannerRepository());
      addTearDown(cubit.close);

      expect(cubit.state.planned['2026-10-20'], isNull);

      cubit.plan('2026-10-20', const PlannedEntry(outfitId: 3, occasion: ''));
      final entry = cubit.state.planned['2026-10-20'];
      expect(entry, isNotNull);
      expect(entry!.occasion, '');
      // A present entry with an empty occasion must never equal "missing".
      expect(cubit.state.planned.containsKey('2026-10-20'), isTrue);

      cubit.remove('2026-10-20');
      expect(cubit.state.planned.containsKey('2026-10-20'), isFalse);
      expect(cubit.state.planned['2026-10-20'], isNull);
    },
  );

  test(
    'F17_A18 startScheduling/clearEditing/select/selectDate/navigate never call any PlannerRepository method',
    () {
      final cubit = PlannerCubit(
        repository: _FailOnAnyCallPlannerRepository(),
      );
      addTearDown(cubit.close);

      // If any of these five calls reached PlannerRepository.plan/remove,
      // the double above would call fail() and this test would report
      // that failure immediately.
      cubit.startScheduling(2, 'Casual');
      cubit.clearEditing();
      cubit.select(20);
      cubit.selectDate(DateTime(2026, 11, 2));
      cubit.navigate(1);

      expect(cubit.state.editingOutfitId, isNull);
    },
  );
}

/// Minimal repository double that only implements [watchPlanned] from a
/// given stream; [plan]/[remove] are never expected to be called by
/// `F17_A16`'s test.
class _StreamPlannerRepository implements PlannerRepository {
  _StreamPlannerRepository(this._stream);

  final Stream<Map<String, PlannedEntry>> _stream;

  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() => _stream;

  @override
  Future<void> plan(String key, PlannedEntry entry) =>
      Future<void>.value();

  @override
  Future<void> remove(String key) => Future<void>.value();
}
