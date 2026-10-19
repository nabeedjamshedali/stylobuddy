import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture;

import '../cubit/profile_state.dart';
import 'profile_repository.dart';

/// Guest-mode repository (architecture D2): today's `ProfileCubit`-held
/// `ProfileState()`-default logic moved behind [ProfileRepository]
/// verbatim — same defaults, same synchronous-feeling writes
/// (`SynchronousFuture`, per the Task 2/F15, Task 3/F16, Task 4/F17
/// review lesson — not `async`), no network call ever constructed on this
/// branch (F18-A09/A10).
///
/// [watchProfile] is deliberately **single-subscription** (backed by a
/// plain, non-broadcast `StreamController`): this repository has exactly
/// one caller in this codebase today (`ProfileCubit`'s own constructor),
/// mirroring `InMemoryOutfitsRepository`'s/`InMemoryWardrobeRepository`'s
/// own documented stance.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository() {
    _controller = StreamController<ProfileState>();
    _emit();
  }

  ProfileState _state = const ProfileState();
  late final StreamController<ProfileState> _controller;

  /// Synchronous escape hatch used only by `ProfileCubit`'s constructor,
  /// for the same reason `InMemoryWardrobeRepository.snapshot` exists: a
  /// guest's very first frame must already show the default profile
  /// rather than one empty frame before this stream's first
  /// (always-asynchronous) event.
  ProfileState get snapshot => _state;

  void _emit() {
    if (!_controller.isClosed) _controller.add(_state);
  }

  @override
  Stream<ProfileState> watchProfile() => _controller.stream;

  @override
  Future<void> updateDetails(String name, String email) {
    _state = _state.copyWith(name: name, email: email);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setStyles(List<String> styles) {
    _state = _state.copyWith(styles: styles);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setOccasions(List<String> occasions) {
    _state = _state.copyWith(occasions: occasions);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setDailyNotifications(bool v) {
    _state = _state.copyWith(dailyNotifications: v);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setPlannedNotifications(bool v) {
    _state = _state.copyWith(plannedNotifications: v);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setProductNotifications(bool v) {
    _state = _state.copyWith(productNotifications: v);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setWeatherConsent(bool v) {
    _state = _state.copyWith(weatherConsent: v);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setClimate(String v) {
    _state = _state.copyWith(climate: v);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setPlan(String v) {
    _state = _state.copyWith(plan: v);
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> setBillingCycle(String v) {
    _state = _state.copyWith(billingCycle: v);
    _emit();
    return SynchronousFuture(null);
  }
}
