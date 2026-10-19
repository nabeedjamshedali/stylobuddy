import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../repository/in_memory_outfits_repository.dart';
import '../repository/outfits_repository.dart';
import 'outfits_state.dart';

class OutfitsCubit extends Cubit<OutfitsState> {
  OutfitsCubit(this._wardrobe, this._repository, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
      super(
        OutfitsState(
          outfits: _initialOutfits(_repository),
          wearLog: _initialWearLog(_repository),
        ),
      ) {
    // Subscribes immediately so a Firestore reconciliation (or, for the
    // in-memory implementation, this repository's own write-driven
    // re-emit) reaches this Cubit's state — mirrors WardrobeCubit's own
    // constructor-time subscription (F15), torn down in [close].
    _outfitsSubscription = _repository.watchOutfits().listen(
      (outfits) => emit(state.copyWith(outfits: outfits)),
      // A snapshot error must not kill this subscription silently for the
      // rest of the Cubit's lifetime, nor propagate as an unhandled stream
      // error (F16-A22) — the last known state is kept.
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchOutfits() stream error', error, stackTrace);
      },
    );
    _wearEventsSubscription = _repository.watchWearEvents().listen(
      (wearLog) => emit(state.copyWith(wearLog: wearLog)),
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchWearEvents() stream error', error, stackTrace);
      },
    );
  }

  final WardrobeCubit _wardrobe;
  final OutfitsRepository _repository;
  final int Function() _clock;
  late final StreamSubscription<List<Outfit>> _outfitsSubscription;
  late final StreamSubscription<List<WearEvent>> _wearEventsSubscription;

  /// Non-fatal logging for a background write/stream failure — never
  /// rethrown, never left as an unhandled async error (which `main.dart`
  /// would otherwise report to Crashlytics as `fatal: true`).
  static void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('OutfitsCubit: $context: $error\n$stackTrace');
    }
  }

  /// Mirrors WardrobeCubit's `_initialItems`: a guest's very first frame
  /// must already show the seed outfits (today's synchronous behavior,
  /// F16-A15) rather than one empty frame before [OutfitsRepository.watchOutfits]'s
  /// always-asynchronous first event. A signed-in (Firestore) instance has
  /// no such synchronous snapshot — it legitimately starts empty until its
  /// first `watchOutfits()` event arrives.
  static List<Outfit> _initialOutfits(OutfitsRepository repository) {
    if (repository is InMemoryOutfitsRepository) {
      return repository.outfitsSnapshot;
    }
    return const [];
  }

  static List<WearEvent> _initialWearLog(OutfitsRepository repository) {
    if (repository is InMemoryOutfitsRepository) {
      return repository.wearEventsSnapshot;
    }
    return const [];
  }

  /// Timestamp-based id, bumped past any existing outfit/event id so two
  /// creations in the same millisecond never collide.
  int _newId() {
    var id = _clock();
    final used = <int>{
      ...state.outfits.map((o) => o.id),
      ...state.wearLog.map((e) => e.id),
    };
    while (used.contains(id)) {
      id++;
    }
    return id;
  }

  Outfit? byId(int id) {
    for (final o in state.outfits) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Prototype `ensureSavedResult`: reuse an outfit with identical item
  /// order. The match/id-generation decision stays here (unchanged from
  /// today) so this method can keep returning synchronously — see
  /// `OutfitsRepository`'s doc comment for why the repository call below is
  /// fire-and-forget rather than awaited.
  Outfit saveOrFind(Outfit draft) {
    for (final o in state.outfits) {
      if (listEquals(o.items, draft.items)) return o;
    }
    final previous = state.outfits;
    final saved = draft.copyWith(
      id: _newId(),
      worn: 0,
      items: List<String>.of(draft.items),
    );
    emit(state.copyWith(outfits: [saved, ...state.outfits]));
    unawaited(() async {
      try {
        await _repository.saveOrFind(saved, current: previous);
      } catch (error, stackTrace) {
        _logError('saveOrFind failed', error, stackTrace);
      }
    }());
    return saved;
  }

  /// Prototype `manualSave`; edits in place when [editingId] exists.
  Outfit upsertManual({
    int? editingId,
    required String name,
    required List<String> items,
    required String occasion,
  }) {
    final previous = state.outfits;
    if (editingId != null) {
      final existing = byId(editingId);
      if (existing != null) {
        final updated = existing.copyWith(
          name: name,
          items: List<String>.of(items),
          occasion: occasion,
        );
        emit(
          state.copyWith(
            outfits: [
              for (final o in state.outfits) o.id == editingId ? updated : o,
            ],
          ),
        );
        _persistUpsert(
          candidate: updated,
          editingId: editingId,
          current: previous,
        );
        return updated;
      }
    }
    final created = Outfit(
      id: _newId(),
      name: name,
      occasion: occasion,
      items: List<String>.of(items),
      why: 'A look you put together from your own wardrobe.',
    );
    emit(state.copyWith(outfits: [created, ...state.outfits]));
    _persistUpsert(candidate: created, editingId: null, current: previous);
    return created;
  }

  void _persistUpsert({
    required Outfit candidate,
    required int? editingId,
    required List<Outfit> current,
  }) {
    unawaited(() async {
      try {
        await _repository.upsertManual(
          candidate: candidate,
          editingId: editingId,
          current: current,
        );
      } catch (error, stackTrace) {
        _logError('upsertManual failed', error, stackTrace);
      }
    }());
  }

  void delete(int id) {
    emit(
      state.copyWith(outfits: state.outfits.where((o) => o.id != id).toList()),
    );
    unawaited(() async {
      try {
        await _repository.delete(id);
      } catch (error, stackTrace) {
        _logError('delete failed', error, stackTrace);
      }
    }());
  }

  void logWear(int outfitId) {
    final outfit = byId(outfitId);
    if (outfit == null) return;
    final event = WearEvent(
      id: _newId(),
      outfitId: outfitId,
      name: outfit.name,
      occasion: outfit.occasion,
      items: List<String>.of(outfit.items),
      timestamp: DateTime.fromMillisecondsSinceEpoch(_clock()),
    );
    emit(
      state.copyWith(
        outfits: [
          for (final o in state.outfits)
            o.id == outfitId ? o.copyWith(worn: o.worn + 1) : o,
        ],
        wearLog: [event, ...state.wearLog],
      ),
    );
    unawaited(() async {
      try {
        await _repository.logWear(outfitId, outfit: outfit, event: event);
        // The F15 cross-feature call contract (F16-A18): only called after
        // the repository write resolves, never before, never skipped.
        _wardrobe.adjustWears(outfit.items, 1);
      } catch (error, stackTrace) {
        _logError('logWear failed', error, stackTrace);
      }
    }());
  }

  void removeWear(int eventId) {
    WearEvent? event;
    for (final e in state.wearLog) {
      if (e.id == eventId) event = e;
    }
    if (event == null) return;
    final capturedEvent = event;
    final outfitId = capturedEvent.outfitId;
    emit(
      state.copyWith(
        outfits: [
          for (final o in state.outfits)
            o.id == outfitId
                ? o.copyWith(worn: o.worn > 0 ? o.worn - 1 : 0)
                : o,
        ],
        wearLog: state.wearLog.where((e) => e.id != eventId).toList(),
      ),
    );
    unawaited(() async {
      try {
        await _repository.removeWear(eventId, event: capturedEvent);
        // Same F15 cross-feature call contract as logWear (F16-A19).
        _wardrobe.adjustWears(capturedEvent.items, -1);
      } catch (error, stackTrace) {
        _logError('removeWear failed', error, stackTrace);
      }
    }());
  }

  /// Newest first, optionally filtered to one outfit.
  List<WearEvent> wearEvents({int? outfitId}) {
    final list =
        [
          for (final e in state.wearLog)
            if (outfitId == null || e.outfitId == outfitId) e,
        ]..sort((a, b) {
          final c = b.timestamp.compareTo(a.timestamp);
          return c != 0 ? c : b.id.compareTo(a.id);
        });
    return list;
  }

  @override
  Future<void> close() {
    unawaited(_outfitsSubscription.cancel());
    unawaited(_wearEventsSubscription.cancel());
    return super.close();
  }
}
