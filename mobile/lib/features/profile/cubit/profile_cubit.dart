import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/in_memory_profile_repository.dart';
import '../repository/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  // [repository] defaults to a fresh InMemoryProfileRepository() (guest
  // mode) so the pre-existing `ProfileCubit()` call site in lib/app.dart
  // and every pre-existing test needs no edit (same no-churn precedent as
  // F16/F17's Cubit constructors). The default is resolved once in this
  // forwarding factory (never twice) so the same resolved instance backs
  // both this Cubit's initial snapshot and its live watchProfile()
  // subscription.
  factory ProfileCubit({ProfileRepository? repository}) =>
      ProfileCubit._(repository ?? InMemoryProfileRepository());

  ProfileCubit._(this._repository) : super(_initial(_repository)) {
    // Subscribes immediately so a Firestore reconciliation (or, for the
    // in-memory implementation, this repository's own write-driven
    // re-emit) reaches this Cubit's state — mirrors WardrobeCubit's/
    // OutfitsCubit's/PlannerCubit's own constructor-time subscription
    // (F15/F16/F17), torn down in [close].
    _subscription = _repository.watchProfile().listen(
      (profile) => emit(profile),
      // A snapshot error must not kill this subscription silently for the
      // rest of the Cubit's lifetime, nor propagate as an unhandled stream
      // error (F18-A15) — the last known state is kept.
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchProfile() stream error', error, stackTrace);
      },
    );
  }

  final ProfileRepository _repository;
  late final StreamSubscription<ProfileState> _subscription;

  /// Non-fatal logging for a background write/stream failure — never
  /// rethrown, never left as an unhandled async error (which `main.dart`
  /// would otherwise report to Crashlytics as `fatal: true`).
  static void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('ProfileCubit: $context: $error\n$stackTrace');
    }
  }

  /// Mirrors WardrobeCubit's/OutfitsCubit's/PlannerCubit's
  /// `_initialItems`/`_initialOutfits`/`_initialPlanned`: a guest's very
  /// first frame must already show the default profile (today's
  /// synchronous behavior, F18-A08) rather than one empty frame before
  /// [ProfileRepository.watchProfile]'s always-asynchronous first event.
  /// A signed-in (Firestore) instance has no such synchronous snapshot —
  /// it legitimately starts at `ProfileState()`'s defaults until its
  /// first `watchProfile()` event arrives.
  static ProfileState _initial(ProfileRepository repository) {
    if (repository is InMemoryProfileRepository) return repository.snapshot;
    return const ProfileState();
  }

  // Every setter below applies its optimistic local update synchronously
  // (matching today's instant-feeling UX and keeping the existing F13
  // guest-mode test suite's synchronous assertions unaffected, F18-A08)
  // and fires the repository's own persistence call in the background. If
  // that call fails, it rolls back ONLY the field(s) that call was
  // writing, evaluated against the Cubit's *current* state at failure
  // time — never a captured-whole-state-before-the-call restore, which
  // would clobber a different, concurrently in-flight, independently
  // succeeding setter's already-applied change (F17's own review-round
  // fix, baked in here from the start — F18-A12/A13).

  void updateDetails(String name, String email) {
    final previousName = state.name;
    final previousEmail = state.email;
    emit(state.copyWith(name: name, email: email));
    unawaited(
      _repository.updateDetails(name, email).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('updateDetails failed', error, stackTrace);
        if (!isClosed) {
          emit(state.copyWith(name: previousName, email: previousEmail));
        }
      }),
    );
  }

  void togglePreference(PreferenceField field, String value) {
    final current = field == PreferenceField.styles
        ? state.styles
        : state.occasions;
    final previous = current;
    final next = current.contains(value)
        ? current.where((v) => v != value).toList()
        : [...current, value];
    emit(
      field == PreferenceField.styles
          ? state.copyWith(styles: next)
          : state.copyWith(occasions: next),
    );
    final future = field == PreferenceField.styles
        ? _repository.setStyles(next)
        : _repository.setOccasions(next);
    unawaited(
      future.catchError((Object error, StackTrace stackTrace) {
        _logError('togglePreference failed', error, stackTrace);
        if (!isClosed) {
          emit(
            field == PreferenceField.styles
                ? state.copyWith(styles: previous)
                : state.copyWith(occasions: previous),
          );
        }
      }),
    );
  }

  void setDailyNotifications(bool v) {
    final previous = state.dailyNotifications;
    emit(state.copyWith(dailyNotifications: v));
    unawaited(
      _repository.setDailyNotifications(v).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('setDailyNotifications failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(dailyNotifications: previous));
      }),
    );
  }

  void setPlannedNotifications(bool v) {
    final previous = state.plannedNotifications;
    emit(state.copyWith(plannedNotifications: v));
    unawaited(
      _repository.setPlannedNotifications(v).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('setPlannedNotifications failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(plannedNotifications: previous));
      }),
    );
  }

  void setProductNotifications(bool v) {
    final previous = state.productNotifications;
    emit(state.copyWith(productNotifications: v));
    unawaited(
      _repository.setProductNotifications(v).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('setProductNotifications failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(productNotifications: previous));
      }),
    );
  }

  void setWeatherConsent(bool v) {
    final previous = state.weatherConsent;
    emit(state.copyWith(weatherConsent: v));
    unawaited(
      _repository.setWeatherConsent(v).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('setWeatherConsent failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(weatherConsent: previous));
      }),
    );
  }

  void setClimate(String v) {
    final previous = state.climate;
    emit(state.copyWith(climate: v));
    unawaited(
      _repository.setClimate(v).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('setClimate failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(climate: previous));
      }),
    );
  }

  void setPlan(String v) {
    final previous = state.plan;
    emit(state.copyWith(plan: v));
    unawaited(
      _repository.setPlan(v).catchError((Object error, StackTrace stackTrace) {
        _logError('setPlan failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(plan: previous));
      }),
    );
  }

  void setBillingCycle(String v) {
    final previous = state.billingCycle;
    emit(state.copyWith(billingCycle: v));
    unawaited(
      _repository.setBillingCycle(v).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        _logError('setBillingCycle failed', error, stackTrace);
        if (!isClosed) emit(state.copyWith(billingCycle: previous));
      }),
    );
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
