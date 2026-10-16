import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/data/seed_data.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import 'outfits_state.dart';

class OutfitsCubit extends Cubit<OutfitsState> {
  OutfitsCubit(this._wardrobe, {int Function()? clock})
      : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
        super(OutfitsState(outfits: SeedData.outfits));

  final WardrobeCubit _wardrobe;
  final int Function() _clock;

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

  /// Prototype `ensureSavedResult`: reuse an outfit with identical item order.
  Outfit saveOrFind(Outfit draft) {
    for (final o in state.outfits) {
      if (listEquals(o.items, draft.items)) return o;
    }
    final saved = draft.copyWith(
      id: _newId(),
      worn: 0,
      items: List<String>.of(draft.items),
    );
    emit(state.copyWith(outfits: [saved, ...state.outfits]));
    return saved;
  }

  /// Prototype `manualSave`; edits in place when [editingId] exists.
  Outfit upsertManual({
    int? editingId,
    required String name,
    required List<String> items,
    required String occasion,
  }) {
    if (editingId != null) {
      final existing = byId(editingId);
      if (existing != null) {
        final updated = existing.copyWith(
          name: name,
          items: List<String>.of(items),
          occasion: occasion,
        );
        emit(state.copyWith(outfits: [
          for (final o in state.outfits) o.id == editingId ? updated : o,
        ]));
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
    return created;
  }

  void delete(int id) => emit(state.copyWith(
        outfits: state.outfits.where((o) => o.id != id).toList(),
      ));

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
    emit(state.copyWith(
      outfits: [
        for (final o in state.outfits)
          o.id == outfitId ? o.copyWith(worn: o.worn + 1) : o,
      ],
      wearLog: [event, ...state.wearLog],
    ));
    _wardrobe.adjustWears(outfit.items, 1);
  }

  void removeWear(int eventId) {
    WearEvent? event;
    for (final e in state.wearLog) {
      if (e.id == eventId) event = e;
    }
    if (event == null) return;
    final outfitId = event.outfitId;
    emit(state.copyWith(
      outfits: [
        for (final o in state.outfits)
          o.id == outfitId
              ? o.copyWith(worn: o.worn > 0 ? o.worn - 1 : 0)
              : o,
      ],
      wearLog: state.wearLog.where((e) => e.id != eventId).toList(),
    ));
    _wardrobe.adjustWears(event.items, -1);
  }

  /// Newest first, optionally filtered to one outfit.
  List<WearEvent> wearEvents({int? outfitId}) {
    final list = [
      for (final e in state.wearLog)
        if (outfitId == null || e.outfitId == outfitId) e,
    ]..sort((a, b) {
        final c = b.timestamp.compareTo(a.timestamp);
        return c != 0 ? c : b.id.compareTo(a.id);
      });
    return list;
  }
}
