import 'package:flutter_bloc/flutter_bloc.dart';

import 'wardrobe_browse_state.dart';

/// Prototype `S.wardrobeFilter` / `S.search`: the category filter and live
/// search driving the wardrobe grid (and the `/filter` screen).
class WardrobeBrowseCubit extends Cubit<WardrobeBrowseState> {
  WardrobeBrowseCubit() : super(const WardrobeBrowseState());

  void setFilter(String filter) => emit(state.copyWith(filter: filter));

  void setSearch(String search) => emit(state.copyWith(search: search));

  void clearSearch() => emit(state.copyWith(search: ''));
}
