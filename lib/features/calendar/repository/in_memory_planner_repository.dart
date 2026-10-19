import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture;

import '../../../shared/data/seed_data.dart';
import '../../../shared/models/planned_entry.dart';
import 'planner_repository.dart';

/// Guest-mode repository (architecture D2): today's `SeedData.planned`
/// behavior moved behind [PlannerRepository] verbatim — same seed map, same
/// synchronous-feeling writes (`SynchronousFuture`, per the Task 2/F15 and
/// Task 3/F16 review lesson — not `async`, so guest-mode write timing stays
/// byte-identical to today), no network call ever constructed on this
/// branch (F17-A09/A10).
///
/// [watchPlanned] is deliberately **single-subscription** (backed by a
/// plain, non-broadcast `StreamController`), mirroring
/// [InMemoryWardrobeRepository]'s/`InMemoryOutfitsRepository`'s own
/// documented stance: this repository has exactly one caller in this
/// codebase today ([PlannerCubit]'s own constructor).
class InMemoryPlannerRepository implements PlannerRepository {
  InMemoryPlannerRepository() {
    _controller = StreamController<Map<String, PlannedEntry>>();
    _emit();
  }

  final Map<String, PlannedEntry> _planned = Map.of(SeedData.planned);
  late final StreamController<Map<String, PlannedEntry>> _controller;

  /// Synchronous escape hatch used only by [PlannerCubit]'s constructor, for
  /// the same reason [InMemoryWardrobeRepository.snapshot] exists: a
  /// guest's very first frame must already show the seed plan map rather
  /// than one empty frame before this stream's first (always-asynchronous)
  /// event.
  Map<String, PlannedEntry> get snapshot => Map.unmodifiable(_planned);

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(Map.unmodifiable(_planned));
    }
  }

  @override
  Stream<Map<String, PlannedEntry>> watchPlanned() => _controller.stream;

  @override
  Future<void> plan(String key, PlannedEntry entry) {
    _planned[key] = entry;
    _emit();
    return SynchronousFuture<void>(null);
  }

  @override
  Future<void> remove(String key) {
    _planned.remove(key);
    _emit();
    return SynchronousFuture<void>(null);
  }
}
