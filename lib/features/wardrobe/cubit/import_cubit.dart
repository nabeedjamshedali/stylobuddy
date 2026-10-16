import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/models/clothing_item.dart';
import 'import_state.dart';
import 'wardrobe_cubit.dart';

/// Prototype `S.importSource` / `S.importCount` / `S.importDrafts` /
/// `S.uploadIndex` / `S.showOriginal` plus `makeImportDrafts()` and
/// `confirmBatchItem()` (app.js:93-101).
class ImportCubit extends Cubit<ImportState> {
  ImportCubit(this._wardrobe, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
      super(const ImportState());

  final WardrobeCubit _wardrobe;
  final int Function() _clock;

  /// Prototype `importPool`; import counts (1/3/6) slice into this list, so
  /// 6 is the maximum a batch can ever contain.
  static const pool = [
    'cream-blouse',
    'denim-jacket',
    'tan-belt',
    'black-heels',
    'floral-dress',
    'cream-cardigan',
  ];

  void setSource(String source) => emit(state.copyWith(source: source));

  void setCount(int count) => emit(state.copyWith(count: count));

  /// Prototype `makeImportDrafts()`: builds one draft per pool item, copying
  /// name/category/color/occasion from the pool source.
  void makeDrafts() {
    final ids = pool.take(state.count).toList();
    final drafts = [
      for (var i = 0; i < ids.length; i++) _draftFor(ids[i], i),
    ];
    emit(state.copyWith(drafts: drafts, uploadIndex: 0, showOriginal: false));
  }

  ClothingItem _draftFor(String sourceId, int index) {
    final source = _wardrobe.itemOrFallback(sourceId);
    return ClothingItem(
      id: 'new-${_clock()}-$index',
      sourceId: sourceId,
      name: source.name,
      category: source.category,
      color: source.color,
      occasion: source.occasion,
      season: 'All season',
    );
  }

  void toggleShowOriginal() =>
      emit(state.copyWith(showOriginal: !state.showOriginal));

  /// Prototype `confirmBatchItem()`: validates [name], merges the edited
  /// fields into the current draft and advances. Saves the whole batch via
  /// `WardrobeCubit.addItems` once the last draft is confirmed. Returns an
  /// error message to toast, or null on success (including when there is no
  /// current draft to confirm).
  String? confirmCurrent({
    required String name,
    required String category,
    required String color,
    required String occasion,
    required String season,
  }) {
    final current = state.current;
    if (current == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name is required';
    final updated = current.copyWith(
      name: trimmed,
      category: category,
      color: color,
      occasion: occasion,
      season: season,
    );
    final drafts = [
      for (var i = 0; i < state.drafts.length; i++)
        i == state.uploadIndex ? updated : state.drafts[i],
    ];
    final nextIndex = state.uploadIndex + 1;
    if (nextIndex >= drafts.length) {
      _wardrobe.addItems(drafts);
      emit(
        state.copyWith(
          drafts: const [],
          uploadIndex: 0,
          showOriginal: false,
          lastImportCount: drafts.length,
        ),
      );
    } else {
      emit(
        state.copyWith(
          drafts: drafts,
          uploadIndex: nextIndex,
          showOriginal: false,
        ),
      );
    }
    return null;
  }
}
