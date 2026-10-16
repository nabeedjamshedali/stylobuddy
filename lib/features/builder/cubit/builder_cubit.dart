import 'package:flutter_bloc/flutter_bloc.dart';

import '../../saved/cubit/outfits_cubit.dart';
import '../models/builder_save_result.dart';
import 'builder_state.dart';

/// Prototype `manualStart/toggleManual/manualRemove/manualSetCategory/
/// manualSave`. Provided at the app root so Saved's "Edit look" action
/// (F08) can call [start] before pushing `/builder`.
class BuilderCubit extends Cubit<BuilderState> {
  BuilderCubit(this._outfits) : super(const BuilderState());

  final OutfitsCubit _outfits;

  /// Seeds a fresh draft, or an existing outfit's items/name/occasion when
  /// [editId] is given. A stale/nonexistent id still records `editingId`
  /// (matching the prototype), so [save] falls back to creating a new
  /// outfit instead of throwing.
  void start({int? editId}) {
    final existing = editId != null ? _outfits.byId(editId) : null;
    emit(
      BuilderState(
        picked: existing != null ? List<String>.of(existing.items) : const [],
        category: 'All',
        editingId: editId,
        name: existing?.name ?? '',
        occasion: existing?.occasion ?? 'Everyday',
      ),
    );
  }

  void setCategory(String category) =>
      emit(state.copyWith(category: category));

  void setName(String name) => emit(state.copyWith(name: name));

  void setOccasion(String occasion) => emit(state.copyWith(occasion: occasion));

  void remove(String id) => emit(
    state.copyWith(picked: state.picked.where((x) => x != id).toList()),
  );

  void toggle(String id) {
    if (state.picked.contains(id)) {
      remove(id);
    } else {
      emit(state.copyWith(picked: [...state.picked, id]));
    }
  }

  /// Prototype `manualSave()`: validates, upserts via [OutfitsCubit], then
  /// clears the draft (name message wins over the items message).
  BuilderSaveResult save() {
    final name = state.name.trim();
    if (name.isEmpty) {
      return const BuilderSaveResult(message: 'Give your outfit a name');
    }
    if (state.picked.isEmpty) {
      return const BuilderSaveResult(message: 'Choose at least one item');
    }
    final outfit = _outfits.upsertManual(
      editingId: state.editingId,
      name: name,
      items: state.picked,
      occasion: state.occasion,
    );
    emit(
      BuilderState(
        picked: const [],
        category: state.category,
        editingId: null,
        name: '',
        occasion: state.occasion,
      ),
    );
    return BuilderSaveResult(message: 'Outfit saved', outfitId: outfit.id);
  }
}
