import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/models/clothing_item.dart';
import '../repository/in_memory_wardrobe_repository.dart';
import '../repository/wardrobe_repository.dart';
import 'wardrobe_state.dart';

class WardrobeCubit extends Cubit<WardrobeState> {
  WardrobeCubit(this._repository)
    : super(WardrobeState(items: _initialItems(_repository))) {
    // Subscribes immediately so an ongoing write/reconciliation reaches
    // this Cubit's state. For the in-memory implementation, the initial
    // seed is already set above (synchronously); this listener's first
    // delivery of that same seed is a harmless, no-visible-effect re-emit.
    // For the Firestore implementation this is the long-lived
    // `snapshots()` listener (architecture D6), torn down in [close]
    // rather than left subscribed past this Cubit's lifetime.
    _subscription = _repository.watchItems().listen(
      (items) {
        emit(state.copyWith(items: items));
      },
      // A snapshot error (e.g. a `permission-denied` mid-session) must not
      // kill this subscription silently for the rest of the Cubit's
      // lifetime, nor propagate as an unhandled stream error (`main.dart`
      // routes those to Crashlytics as `fatal: true`, which this is not —
      // the last known in-memory state is kept and reconciliation simply
      // stops until the next successful snapshot).
      onError: (Object error, StackTrace stackTrace) {
        _logError('watchItems() stream error', error, stackTrace);
      },
    );
  }

  /// Non-fatal logging for a background write/stream failure — never
  /// rethrown, never left as an unhandled async error (which `main.dart`
  /// would otherwise report to Crashlytics as `fatal: true`).
  static void _logError(String context, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('WardrobeCubit: $context: $error\n$stackTrace');
    }
  }

  final WardrobeRepository _repository;
  late final StreamSubscription<List<ClothingItem>> _subscription;

  /// Dart's `Stream` contract never delivers an event synchronously to a
  /// just-attached listener (confirmed: even a single-subscription
  /// controller seeded before anyone listens only delivers on the next
  /// microtask) — so a signed-out guest's *very first* frame would
  /// otherwise render zero items for a tick before the real seed data
  /// appears, a regression against today's synchronous
  /// `super(WardrobeState(items: repository.loadItems()))` behavior
  /// (F15-A07's "zero existing assertion edited"). [InMemoryWardrobeRepository]
  /// exposes a synchronous `snapshot` getter specifically for this; a
  /// signed-in (`FirestoreWardrobeRepository`) instance has no such
  /// synchronous snapshot — it legitimately starts empty until its first
  /// `watchItems()` event arrives, which is new, expected behavior for
  /// that mode, not a regression.
  static List<ClothingItem> _initialItems(WardrobeRepository repository) {
    if (repository is InMemoryWardrobeRepository) return repository.snapshot;
    return const [];
  }

  /// Prototype `get()`: unknown ids still render as a placeholder item.
  ClothingItem itemOrFallback(String id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return ClothingItem(
      id: id,
      name: id.replaceAll('-', ' '),
      category: 'Shirts',
      color: 'Unknown',
      occasion: 'Everyday',
    );
  }

  // Every write below applies its optimistic local update synchronously
  // (matching today's instant-feeling UX and keeping the existing F06
  // guest-mode test suite's synchronous assertions unaffected, F15-A07)
  // and fires the repository's own persistence call in the background
  // (fire-and-forget from this method's perspective) — for a signed-in
  // user the later Firestore `watchItems()` snapshot reconciles the same
  // data moments later (architecture D6's "optimistic-then-reconcile").

  void addItems(List<ClothingItem> added) {
    emit(state.copyWith(items: [...state.items, ...added]));
    unawaited(
      _repository.addItems(added).catchError((Object error, StackTrace st) {
        _logError('addItems failed', error, st);
      }),
    );
  }

  void updateItem(ClothingItem updated) {
    emit(
      state.copyWith(
        items: [for (final i in state.items) i.id == updated.id ? updated : i],
      ),
    );
    unawaited(
      _repository.updateItem(updated).catchError((Object error, StackTrace st) {
        _logError('updateItem failed', error, st);
      }),
    );
  }

  void removeItem(String id) {
    emit(
      state.copyWith(items: state.items.where((i) => i.id != id).toList()),
    );
    unawaited(
      _repository.removeItem(id).catchError((Object error, StackTrace st) {
        _logError('removeItem failed', error, st);
      }),
    );
  }

  void adjustWears(List<String> ids, int delta) {
    emit(
      state.copyWith(
        items: [
          for (final i in state.items)
            ids.contains(i.id)
                ? i.copyWith(wears: (i.wears + delta).clamp(0, 1 << 30))
                : i,
        ],
      ),
    );
    unawaited(
      _repository.adjustWears(ids, delta).catchError((
        Object error,
        StackTrace st,
      ) {
        _logError('adjustWears failed', error, st);
      }),
    );
  }

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
