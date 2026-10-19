import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;

import '../../../shared/data/seed_data.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';
import 'outfits_repository.dart';

/// Guest-mode repository (architecture D2): today's `SeedData.outfits`/empty
/// wear log behavior moved behind [OutfitsRepository] verbatim — same seed
/// list, same synchronous-feeling writes (every write's `Future` is already
/// resolved by the time it's returned), no network call ever constructed on
/// this branch (F16-A16).
///
/// [watchOutfits]/[watchWearEvents] are deliberately **single-subscription**
/// (backed by plain, non-broadcast `StreamController`s): this repository has
/// exactly one caller in this codebase today ([OutfitsCubit]'s own
/// constructor), mirroring [InMemoryWardrobeRepository]'s own documented
/// stance.
class InMemoryOutfitsRepository implements OutfitsRepository {
  InMemoryOutfitsRepository() {
    _outfitsController = StreamController<List<Outfit>>();
    _wearEventsController = StreamController<List<WearEvent>>();
    _emitOutfits();
    _emitWearEvents();
  }

  final List<Outfit> _outfits = List.of(SeedData.outfits);
  final List<WearEvent> _wearLog = <WearEvent>[];
  late final StreamController<List<Outfit>> _outfitsController;
  late final StreamController<List<WearEvent>> _wearEventsController;

  /// Synchronous escape hatch used only by [OutfitsCubit]'s constructor, for
  /// the same reason [InMemoryWardrobeRepository.snapshot] exists: a guest's
  /// very first frame must already show the seed outfits rather than one
  /// empty frame before this stream's first (always-asynchronous) event.
  List<Outfit> get outfitsSnapshot => List.unmodifiable(_outfits);

  /// Synchronous escape hatch, mirror of [outfitsSnapshot] for wear history.
  List<WearEvent> get wearEventsSnapshot => List.unmodifiable(_wearLog);

  void _emitOutfits() {
    if (!_outfitsController.isClosed) {
      _outfitsController.add(List.unmodifiable(_outfits));
    }
  }

  void _emitWearEvents() {
    if (!_wearEventsController.isClosed) {
      _wearEventsController.add(List.unmodifiable(_wearLog));
    }
  }

  @override
  Stream<List<Outfit>> watchOutfits() => _outfitsController.stream;

  @override
  Stream<List<WearEvent>> watchWearEvents() => _wearEventsController.stream;

  @override
  Future<Outfit> saveOrFind(
    Outfit draft, {
    required List<Outfit> current,
  }) async {
    for (final o in _outfits) {
      if (listEquals(o.items, draft.items)) return o;
    }
    _outfits.insert(0, draft);
    _emitOutfits();
    return draft;
  }

  @override
  Future<Outfit> upsertManual({
    required Outfit candidate,
    int? editingId,
    required List<Outfit> current,
  }) async {
    if (editingId != null) {
      final index = _outfits.indexWhere((o) => o.id == editingId);
      if (index != -1) {
        _outfits[index] = candidate;
        _emitOutfits();
        return candidate;
      }
    }
    _outfits.insert(0, candidate);
    _emitOutfits();
    return candidate;
  }

  @override
  Future<void> delete(int id) async {
    _outfits.removeWhere((o) => o.id == id);
    _emitOutfits();
  }

  @override
  Future<void> logWear(
    int outfitId, {
    required Outfit outfit,
    required WearEvent event,
  }) async {
    final index = _outfits.indexWhere((o) => o.id == outfitId);
    if (index == -1) return;
    final current = _outfits[index];
    _outfits[index] = current.copyWith(worn: current.worn + 1);
    _wearLog.insert(
      0,
      WearEvent(
        id: event.id,
        outfitId: outfitId,
        name: current.name,
        occasion: current.occasion,
        items: List<String>.of(current.items),
        timestamp: event.timestamp,
      ),
    );
    _emitOutfits();
    _emitWearEvents();
  }

  @override
  Future<void> removeWear(int eventId, {required WearEvent event}) async {
    final eventIndex = _wearLog.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    final outfitId = _wearLog[eventIndex].outfitId;
    _wearLog.removeAt(eventIndex);
    final outfitIndex = _outfits.indexWhere((o) => o.id == outfitId);
    if (outfitIndex != -1) {
      final current = _outfits[outfitIndex];
      _outfits[outfitIndex] = current.copyWith(
        worn: current.worn > 0 ? current.worn - 1 : 0,
      );
    }
    _emitOutfits();
    _emitWearEvents();
  }
}
