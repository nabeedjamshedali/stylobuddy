import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/backend/storage_repository.dart';
import '../../../shared/models/clothing_item.dart';
import 'import_state.dart';
import 'wardrobe_cubit.dart';

/// Prototype `S.importSource` / `S.importCount` / `S.importDrafts` /
/// `S.uploadIndex` / `S.showOriginal` plus `makeImportDrafts()` and
/// `confirmBatchItem()` (app.js:93-101). Gains a real picked-file path
/// (F15): [pickPhoto] attaches a real camera/gallery [XFile] to the
/// current draft; [confirmCurrent] uploads any picked file before the
/// batch's final save so the saved `ClothingItem.imageUrl` reflects a real
/// upload. A draft with no picked file keeps the existing
/// simulated/pool-art path unchanged (F06) — real photos are additive, not
/// a replacement.
class ImportCubit extends Cubit<ImportState> {
  ImportCubit(
    this._wardrobe, {
    int Function()? clock,
    ImagePicker? imagePicker,
    StorageRepository? storageRepository,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _imagePicker = imagePicker ?? ImagePicker(),
       _storage = storageRepository ?? StorageRepository(),
       super(const ImportState());

  final WardrobeCubit _wardrobe;
  final int Function() _clock;
  final ImagePicker _imagePicker;
  final StorageRepository _storage;

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
    emit(
      state.copyWith(
        drafts: drafts,
        uploadIndex: 0,
        showOriginal: false,
        pickedFiles: const {},
        lastImportHadUploadFailure: false,
      ),
    );
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

  /// Opens the camera or gallery (per [ImportState.source]) and attaches
  /// the picked file to the current draft. No current draft, or the user
  /// backing out of the picker (no file ever picked), is a no-op — not an
  /// error path (F15 §12: identical to the existing no-photo simulated
  /// path).
  Future<void> pickPhoto() async {
    final current = state.current;
    if (current == null) return;
    final source = state.source == 'camera'
        ? ImageSource.camera
        : ImageSource.gallery;
    final XFile? file = await _imagePicker.pickImage(source: source);
    if (file == null) return;
    emit(
      state.copyWith(
        pickedFiles: {...state.pickedFiles, current.id: file},
      ),
    );
  }

  /// Prototype `confirmBatchItem()`: validates [name], merges the edited
  /// fields into the current draft and advances. Saves the whole batch via
  /// `WardrobeCubit.addItems` once the last draft is confirmed — for any
  /// draft with a real picked file (F15-A10), that draft is uploaded via
  /// [StorageRepository.uploadWardrobePhoto] first so the saved item's
  /// `imageUrl` reflects the real upload; an upload failure never blocks
  /// the save (F15-A12) and is surfaced via
  /// [ImportState.lastImportHadUploadFailure] (F15-A13). Returns an error
  /// message to toast, or null on success (including when there is no
  /// current draft to confirm) — synchronous-validation shape unchanged,
  /// only the return type is now `Future<String?>` to allow awaiting the
  /// upload step before the save completes.
  Future<String?> confirmCurrent({
    required String name,
    required String category,
    required String color,
    required String occasion,
    required String season,
  }) async {
    // Guards against a double-tap re-entering this method across the real
    // upload's `await` gap below: without this, a second call landing while
    // the first is still mid-upload could both save the batch twice and
    // race the first call's own final `emit` (including wiping
    // `pickedFiles`/`drafts` the first call is still reading). No-ops
    // (returns null, as if the tap were simply dropped) rather than
    // queuing — the first call's own result is what the UI already awaits.
    if (state.saving) return null;
    final current = state.current;
    if (current == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name is required';
    emit(state.copyWith(saving: true));
    try {
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
        final pickedFiles = state.pickedFiles;
        var hadUploadFailure = false;
        final finalized = <ClothingItem>[];
        for (final draft in drafts) {
          final file = pickedFiles[draft.id];
          if (file == null) {
            // No real photo for this draft — existing simulated/pool-art
            // path, unchanged (F15-A11).
            finalized.add(draft);
            continue;
          }
          try {
            final url = await _storage.uploadWardrobePhoto(
              itemId: draft.id,
              file: file,
            );
            finalized.add(draft.copyWith(imageUrl: url));
          } catch (_) {
            // Never blocks the save (F15-A12); imageUrl stays null for this
            // item and the batch-level failure flag is raised (F15-A13).
            hadUploadFailure = true;
            finalized.add(draft);
          }
        }
        _wardrobe.addItems(finalized);
        emit(
          state.copyWith(
            drafts: const [],
            uploadIndex: 0,
            showOriginal: false,
            lastImportCount: finalized.length,
            pickedFiles: const {},
            lastImportHadUploadFailure: hadUploadFailure,
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
    } finally {
      if (!isClosed) {
        emit(state.copyWith(saving: false));
      }
    }
  }
}
