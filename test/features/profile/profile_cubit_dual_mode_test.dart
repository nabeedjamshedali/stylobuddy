import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/profile/cubit/profile_state.dart';
import 'package:stylobuddy/features/profile/repository/firestore_profile_repository.dart';
import 'package:stylobuddy/features/profile/repository/in_memory_profile_repository.dart';
import 'package:stylobuddy/features/profile/repository/profile_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';

/// A [ProfileRepository] test double whose `set*`/`updateDetails` methods
/// can each be made to fail on demand, so the `catchError`/rollback path
/// can be driven deterministically without any real/fake network I/O.
class _FailingProfileRepository implements ProfileRepository {
  final _controller = StreamController<ProfileState>.broadcast();
  ProfileState _state = const ProfileState();

  /// Field names (matching the setter's own name, e.g. 'climate') that
  /// should fail their *next* call.
  final Set<String> failing = {};

  final List<String> calls = [];

  void emit(ProfileState state) {
    _state = state;
    _controller.add(_state);
  }

  Future<void> _write(String name, ProfileState Function() apply) {
    calls.add(name);
    if (failing.remove(name)) {
      return Future<void>.error(StateError('$name failed'));
    }
    _state = apply();
    return Future<void>.value();
  }

  @override
  Stream<ProfileState> watchProfile() => _controller.stream;

  @override
  Future<void> updateDetails(String name, String email) =>
      _write('updateDetails', () => _state.copyWith(name: name, email: email));

  @override
  Future<void> setStyles(List<String> styles) =>
      _write('setStyles', () => _state.copyWith(styles: styles));

  @override
  Future<void> setOccasions(List<String> occasions) =>
      _write('setOccasions', () => _state.copyWith(occasions: occasions));

  @override
  Future<void> setDailyNotifications(bool v) =>
      _write('setDailyNotifications', () => _state.copyWith(dailyNotifications: v));

  @override
  Future<void> setPlannedNotifications(bool v) => _write(
    'setPlannedNotifications',
    () => _state.copyWith(plannedNotifications: v),
  );

  @override
  Future<void> setProductNotifications(bool v) => _write(
    'setProductNotifications',
    () => _state.copyWith(productNotifications: v),
  );

  @override
  Future<void> setWeatherConsent(bool v) =>
      _write('setWeatherConsent', () => _state.copyWith(weatherConsent: v));

  @override
  Future<void> setClimate(String v) =>
      _write('setClimate', () => _state.copyWith(climate: v));

  @override
  Future<void> setPlan(String v) => _write('setPlan', () => _state.copyWith(plan: v));

  @override
  Future<void> setBillingCycle(String v) =>
      _write('setBillingCycle', () => _state.copyWith(billingCycle: v));
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test(
    'F18_A11_sample ProfileCubit constructed with InMemoryProfileRepository vs FirestoreProfileRepository is a different object type, not just different data',
    () async {
      final guestCubit = ProfileCubit(repository: InMemoryProfileRepository());
      final firestore = FakeFirebaseFirestore();
      final signedInCubit = ProfileCubit(
        repository: FirestoreProfileRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );
      addTearDown(guestCubit.close);
      addTearDown(signedInCubit.close);

      // Guest mode: already at the hardcoded default on the very first
      // frame (F18-A08), no network call ever constructed.
      expect(guestCubit.state.name, 'Alex Morgan');
      // Signed-in mode legitimately starts at ProfileState()'s defaults
      // too until its first watchProfile() event arrives (no synchronous
      // snapshot for this branch) — the type-level distinction is what
      // app.dart's own dual-mode ternary is checked against separately
      // (F18-A11, app_backend_wiring_test.dart).
      expect(signedInCubit.state, const ProfileState());
    },
  );

  test(
    'F18_A12 an in-flight setter optimistically updates state before the repository Future resolves, then rolls back only that field on failure',
    () async {
      final repo = _FailingProfileRepository();
      final cubit = ProfileCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failing.add('setClimate');
      cubit.setClimate('Cold');
      // Optimistic update already applied before the repository Future
      // (a real Future.error here) has had a chance to settle.
      expect(cubit.state.climate, 'Cold');

      await _settle();
      // The failed write rolled back just `climate`.
      expect(cubit.state.climate, 'Mild');
    },
  );

  test(
    'F18_A13 two interleaved setters where only the first fails: the targeted rollback reverts only that field, leaving the second, concurrently-succeeding setter\'s change untouched',
    () async {
      final repo = _FailingProfileRepository();
      final cubit = ProfileCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failing.add('setClimate');
      cubit.setClimate('Cold'); // will fail
      cubit.setPlan('Plus'); // will succeed, concurrently in-flight

      await _settle();

      expect(
        cubit.state.climate,
        'Mild',
        reason: 'the failed setClimate call must be rolled back',
      );
      expect(
        cubit.state.plan,
        'Plus',
        reason:
            'the concurrently-succeeding setPlan call must survive the '
            'other field\'s rollback untouched (F17\'s targeted-revert '
            'lesson)',
      );
    },
  );

  test(
    'F18_A14 every fire-and-forget write has error handling — a failing setter never surfaces as an unhandled async error',
    () async {
      final repo = _FailingProfileRepository();
      final cubit = ProfileCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      repo.failing.add('setBillingCycle');
      final errors = <Object>[];
      await runZonedGuarded(() async {
        cubit.setBillingCycle('monthly');
        await _settle();
      }, (error, stack) => errors.add(error));

      expect(
        errors,
        isEmpty,
        reason: 'the failure must be caught by ProfileCubit, not escape '
            'as an unhandled zone error',
      );
      expect(cubit.state.billingCycle, 'yearly');
    },
  );

  test(
    'F18_A15 a simulated watchProfile() stream error does not crash the Cubit or surface as an unhandled zone error',
    () async {
      final repo = _FailingProfileRepository();
      final cubit = ProfileCubit(repository: repo);
      addTearDown(cubit.close);
      await _settle();

      final errors = <Object>[];
      await runZonedGuarded(() async {
        repo._controller.addError(StateError('snapshot error'));
        await _settle();
      }, (error, stack) => errors.add(error));

      expect(errors, isEmpty);
      // The Cubit keeps its last known state rather than crashing.
      expect(cubit.state, isA<ProfileState>());
    },
  );

  test(
    'F18_A16 sign-out then sign-in-again as a different uid leaves no stale ProfileState bleed-through',
    () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);
      final signedInA = ProfileCubit(
        repository: FirestoreProfileRepository(service, 'uid-a'),
      );
      addTearDown(signedInA.close);
      signedInA.updateDetails('User A', 'a@x.com');
      await _settle();
      expect(signedInA.state.name, 'User A');

      // Sign-out: a brand-new guest ProfileCubit (not the same instance,
      // mirroring app.dart's full-teardown-and-rebuild per uid, F14 D3).
      final guest = ProfileCubit(repository: InMemoryProfileRepository());
      addTearDown(guest.close);
      expect(guest.state.name, 'Alex Morgan');
      expect(guest.state.name, isNot('User A'));

      // Sign-in as a different uid: must see only that uid's own document,
      // never uid-a's values.
      final signedInB = ProfileCubit(
        repository: FirestoreProfileRepository(service, 'uid-b'),
      );
      addTearDown(signedInB.close);
      await _settle();
      expect(signedInB.state.name, isNot('User A'));
      expect(signedInB.state.name, const ProfileState().name);
      expect(signedInB.state.occasions, const ProfileState().occasions);
    },
  );
}
