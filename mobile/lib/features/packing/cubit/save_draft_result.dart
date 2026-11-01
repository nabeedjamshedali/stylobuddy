/// Outcome of [PackingCubit.saveDraft]. Prototype `pkSaveDraft`: a failed
/// validation only toasts (no trip change); a success never toasts, it
/// navigates (to `/packing-preview` for a new trip, `/packing-list` for an
/// edit).
class SaveDraftResult {
  const SaveDraftResult.failure(this.errorMessage)
    : success = false,
      tripId = null,
      wasEditing = false;

  const SaveDraftResult.success({required this.tripId, required this.wasEditing})
    : success = true,
      errorMessage = null;

  final bool success;
  final String? errorMessage;
  final String? tripId;
  final bool wasEditing;
}
