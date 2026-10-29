import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/backend/analytics_service.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../repository/in_memory_outfits_repository.dart';
import '../repository/outfits_repository.dart';
import 'outfits_state.dart';

class OutfitsCubit extends Cubit<OutfitsState> {
  // [repository] defaults to a fresh InMemoryOutfitsRepository() (guest
  // mode) so every pre-existing test/call site that only ever constructed
  // this Cubit for guest mode needs no edit to keep compiling (review
  // finding on Task 3: minimizes test churn from this task's constructor
  // shape change). Dart does not allow mixing an optional-positional
  // parameter with named parameters in one signature, and [clock] must
  // stay named for the same no-edit reason, so [repository] is named too.
  // The default is resolved once in this forwarding factory (never twice)
  // so the same resolved instance backs both this Cubit's initial
  // snapshot and its live watchOutfits()/watchWearEvents() subscription.
  factory OutfitsCubit(
    WardrobeCubit wardrobe, {
    OutfitsRepository? repository,
    int Function()? clock,
    AnalyticsService? analytics,
  }) => OutfitsCubit._(
    wardrobe,
    repository ?? InMemoryOutfitsRepository(),
    clock: clock,
    analytics: analytics ?? const AnalyticsService.noop(),
  );

  OutfitsCubit._(
    this._wardrobe,
    this._repository, {
    int Function()? clock,
    required this._analytics,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
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
  final AnalyticsService _analytics;
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
    _analytics.outfitSaved(
      source: OutfitSaveSource.generated,
      itemCount: saved.items.length,
    );
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
    _analytics.outfitSaved(
      source: OutfitSaveSource.builder,
      itemCount: created.items.length,
    );
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
      } catch (error, stackTrace) {
        _logError('logWear repository write failed', error, stackTrace);
        // Controller ruling (D6 "reconcile on failure"): a Firestore
        // transaction either commits or never happens at all — it does
        // not queue offline like set() does — so a failure here means
        // nothing was ever persisted and no future watchOutfits()/
        // watchWearEvents() snapshot will ever correct this optimistic
        // update on its own. Roll the Cubit's own state back to its
        // pre-call value as a best-effort local reconciliation, reading
        // the *current* state (not a stale snapshot) so an unrelated
        // concurrent update isn't clobbered.
        emit(
          state.copyWith(
            outfits: [
              for (final o in state.outfits)
                o.id == outfitId ? o.copyWith(worn: outfit.worn) : o,
            ],
            wearLog: state.wearLog.where((e) => e.id != event.id).toList(),
          ),
        );
        return;
      }
      try {
        // The F15 cross-feature call contract (F16-A18): only called
        // after the repository write resolves, never before, never
        // skipped. This is a separate try/catch from the repository
        // write above so a failure here is never misreported as a
        // "logWear repository write failed" when the write itself
        // already succeeded.
        _wardrobe.adjustWears(outfit.items, 1);
      } catch (error, stackTrace) {
        _logError(
          'logWear: WardrobeCubit.adjustWears failed after a successful '
          'repository write',
          error,
          stackTrace,
        );
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
    // Captured before the optimistic update below, so a rollback can
    // restore the exact pre-call value rather than re-deriving it.
    final previousWorn = byId(outfitId)?.worn;
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
      } catch (error, stackTrace) {
        _logError('removeWear repository write failed', error, stackTrace);
        // Same controller ruling as logWear's catch block above: a
        // transaction failure means nothing was ever persisted, so roll
        // this Cubit's own state back to its pre-call value (worn
        // restored, the event re-added) off the *current* state.
        emit(
          state.copyWith(
            outfits: [
              for (final o in state.outfits)
                o.id == outfitId && previousWorn != null
                    ? o.copyWith(worn: previousWorn)
                    : o,
            ],
            wearLog: [
              if (!state.wearLog.any((e) => e.id == capturedEvent.id))
                capturedEvent,
              ...state.wearLog,
            ],
          ),
        );
        return;
      }
      try {
        // Same F15 cross-feature call contract as logWear (F16-A19),
        // kept in its own try/catch for the same misattribution reason.
        _wardrobe.adjustWears(capturedEvent.items, -1);
      } catch (error, stackTrace) {
        _logError(
          'removeWear: WardrobeCubit.adjustWears failed after a successful '
          'repository write',
          error,
          stackTrace,
        );
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
