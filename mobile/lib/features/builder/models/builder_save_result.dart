/// Prototype `manualSave()` outcome: [message] is always a toast to show;
/// [outfitId] is set only when the save actually created or updated an
/// outfit (used to navigate to the saved-detail screen).
class BuilderSaveResult {
  const BuilderSaveResult({required this.message, this.outfitId});

  final String message;
  final int? outfitId;

  bool get succeeded => outfitId != null;
}
