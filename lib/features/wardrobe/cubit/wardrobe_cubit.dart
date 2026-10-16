import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/models/clothing_item.dart';
import '../repository/wardrobe_repository.dart';
import 'wardrobe_state.dart';

class WardrobeCubit extends Cubit<WardrobeState> {
  WardrobeCubit(WardrobeRepository repository)
      : super(WardrobeState(items: repository.loadItems()));

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

  void addItems(List<ClothingItem> added) =>
      emit(state.copyWith(items: [...state.items, ...added]));

  void updateItem(ClothingItem updated) => emit(state.copyWith(
        items: [for (final i in state.items) i.id == updated.id ? updated : i],
      ));

  void removeItem(String id) => emit(
      state.copyWith(items: state.items.where((i) => i.id != id).toList()));

  void adjustWears(List<String> ids, int delta) => emit(state.copyWith(items: [
        for (final i in state.items)
          ids.contains(i.id)
              ? i.copyWith(wears: (i.wears + delta).clamp(0, 1 << 30))
              : i,
      ]));
}
