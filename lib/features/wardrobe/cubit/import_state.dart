import 'package:image_picker/image_picker.dart';

import '../../../shared/models/clothing_item.dart';

class ImportState {
  const ImportState({
    this.source = 'camera',
    this.count = 3,
    this.drafts = const [],
    this.uploadIndex = 0,
    this.showOriginal = false,
    this.lastImportCount = 0,
    this.pickedFiles = const {},
    this.lastImportHadUploadFailure = false,
    this.saving = false,
  });

  final String source;
  final int count;
  final List<ClothingItem> drafts;
  final int uploadIndex;
  final bool showOriginal;

  /// Size of the batch that was most recently saved (prototype overwrites
  /// `S.importCount` with the draft count on save); drives `/add-confirm`.
  final int lastImportCount;

  /// Real picked photos (F15), keyed by draft id. A draft with no entry
  /// here uses the existing simulated/pool-art path (F06), kept unchanged
  /// as the fallback — not every draft in a batch needs a picked file.
  final Map<String, XFile> pickedFiles;

  /// Set on the most recent save when at least one draft with a picked
  /// file failed to upload (network, expired signed URL, Edge Function
  /// down, missing/invalid token) — the save still proceeds with
  /// `imageUrl: null` for that item (F15-A12/A13); this flag is the
  /// distinguishable signal that a photo upload failed, as opposed to the
  /// user simply not having picked a photo for that draft at all. Reset to
  /// `false` at the start of every new batch ([makeDrafts]).
  final bool lastImportHadUploadFailure;

  /// True only while a batch-completing `confirmCurrent` call is between its
  /// upload loop and the final `WardrobeCubit.addItems` save (set at the
  /// very start of that call, cleared once the save/emit completes). Guards
  /// against a double-tap re-entering `confirmCurrent` across the `await`
  /// gap the real upload introduces — without this, a second tap before the
  /// first save lands could both save the batch a second time and race the
  /// first call's own final `emit`, including wiping `pickedFiles`/drafts
  /// the first call is still mid-upload against.
  final bool saving;

  /// The draft currently under review, or null when there is nothing left
  /// (missing, not an empty draft).
  ClothingItem? get current =>
      uploadIndex >= 0 && uploadIndex < drafts.length
      ? drafts[uploadIndex]
      : null;

  ImportState copyWith({
    String? source,
    int? count,
    List<ClothingItem>? drafts,
    int? uploadIndex,
    bool? showOriginal,
    int? lastImportCount,
    Map<String, XFile>? pickedFiles,
    bool? lastImportHadUploadFailure,
    bool? saving,
  }) => ImportState(
    source: source ?? this.source,
    count: count ?? this.count,
    drafts: drafts ?? this.drafts,
    uploadIndex: uploadIndex ?? this.uploadIndex,
    showOriginal: showOriginal ?? this.showOriginal,
    lastImportCount: lastImportCount ?? this.lastImportCount,
    pickedFiles: pickedFiles ?? this.pickedFiles,
    lastImportHadUploadFailure:
        lastImportHadUploadFailure ?? this.lastImportHadUploadFailure,
    saving: saving ?? this.saving,
  );
}
