import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture;

import '../models/packing_item.dart';
import '../models/trip.dart';
import 'packing_repository.dart';

/// Guest-mode repository (architecture D2): today's `PackingCubit` trip-list
/// logic (`_replaceTrip`, the create/edit branching in `saveDraft`,
/// `deleteSelectedTrip`'s filter) moved behind [PackingRepository] verbatim
/// — same semantics, every write returns a [SynchronousFuture] (not an
/// `async`-declared method, F20-A12), no network call ever constructed on
/// this branch (F20-A13). `trips` starts empty, matching
/// `PackingState()`'s own default (F10's original "0 trips on first open").
///
/// [watchTrips] is deliberately **single-subscription** (backed by a plain,
/// non-broadcast `StreamController`): this repository has exactly one
/// caller in this codebase today (`PackingCubit`'s own constructor),
/// mirroring [InMemoryOutfitsRepository]'s/[InMemoryWardrobeRepository]'s
/// own documented stance.
class InMemoryPackingRepository implements PackingRepository {
  InMemoryPackingRepository() {
    _controller = StreamController<List<Trip>>();
    _emit();
  }

  final List<Trip> _trips = <Trip>[];
  late final StreamController<List<Trip>> _controller;

  /// Synchronous escape hatch used only by `PackingCubit`'s constructor, for
  /// the same reason [InMemoryOutfitsRepository.outfitsSnapshot] exists: a
  /// guest's very first frame must already show the current trip list
  /// rather than one empty frame before this stream's first
  /// (always-asynchronous) event.
  List<Trip> get snapshot => List.unmodifiable(_trips);

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_trips));
    }
  }

  @override
  Stream<List<Trip>> watchTrips() => _controller.stream;

  int _indexOf(String tripId) => _trips.indexWhere((t) => t.id == tripId);

  @override
  Future<void> saveTrip(Trip trip, {required bool isNew}) {
    final index = _indexOf(trip.id);
    if (isNew || index == -1) {
      _trips.insert(0, trip);
    } else {
      _trips[index] = trip;
    }
    _emit();
    return SynchronousFuture(null);
  }

  /// Shared read-modify-write helper every items-mutating method below
  /// delegates to — mirrors [FirestorePackingRepository]'s own
  /// `runTransaction`-based helper (same public-five-methods-share-one-
  /// private-helper shape named by the controller ruling), just without an
  /// actual transaction since there is no concurrent writer in guest mode.
  /// A no-op (not a crash) when [tripId] no longer exists (F20-A15
  /// precedent, re-verified at this implementation too).
  Future<void> _mutateItems(
    String tripId,
    List<PackingItem> Function(List<PackingItem> current) transform,
  ) {
    final index = _indexOf(tripId);
    if (index == -1) return SynchronousFuture(null);
    final trip = _trips[index];
    _trips[index] = trip.copyWith(items: transform(trip.items));
    _emit();
    return SynchronousFuture(null);
  }

  @override
  Future<void> toggle(String tripId, String key) => _mutateItems(
    tripId,
    (items) => [
      for (final i in items) i.key == key ? i.copyWith(packed: !i.packed) : i,
    ],
  );

  @override
  Future<void> removeItem(String tripId, String key) =>
      _mutateItems(tripId, (items) => items.where((i) => i.key != key).toList());

  @override
  Future<void> addWardrobe(String tripId, PackingItem item) => _mutateItems(
    tripId,
    (items) => items.any((i) => i.wardrobeId == item.wardrobeId)
        ? items
        : [...items, item],
  );

  @override
  Future<void> addCustom(String tripId, PackingItem item) =>
      _mutateItems(tripId, (items) => [...items, item]);

  @override
  Future<void> generateChecklist(String tripId, List<PackingItem> suggested) =>
      _mutateItems(tripId, (items) => items.isEmpty ? suggested : items);

  @override
  Future<void> deleteTrip(String tripId) {
    _trips.removeWhere((t) => t.id == tripId);
    _emit();
    return SynchronousFuture(null);
  }
}
