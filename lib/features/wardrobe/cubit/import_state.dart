import '../../../shared/models/clothing_item.dart';

class ImportState {
  const ImportState({
    this.source = 'camera',
    this.count = 3,
    this.drafts = const [],
    this.uploadIndex = 0,
    this.showOriginal = false,
    this.lastImportCount = 0,
  });

  final String source;
  final int count;
  final List<ClothingItem> drafts;
  final int uploadIndex;
  final bool showOriginal;

  /// Size of the batch that was most recently saved (prototype overwrites
  /// `S.importCount` with the draft count on save); drives `/add-confirm`.
  final int lastImportCount;

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
  }) => ImportState(
    source: source ?? this.source,
    count: count ?? this.count,
    drafts: drafts ?? this.drafts,
    uploadIndex: uploadIndex ?? this.uploadIndex,
    showOriginal: showOriginal ?? this.showOriginal,
    lastImportCount: lastImportCount ?? this.lastImportCount,
  );
}
