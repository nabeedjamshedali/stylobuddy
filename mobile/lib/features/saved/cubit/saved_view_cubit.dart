import 'package:flutter_bloc/flutter_bloc.dart';

import 'saved_view_state.dart';

/// Prototype `savedFilter`/search state for `/saved`: which tab is active
/// and the current search text.
class SavedViewCubit extends Cubit<SavedViewState> {
  SavedViewCubit() : super(const SavedViewState());

  /// Prototype `savedFilter`: switching tabs also clears the search.
  void setTab(String tab) => emit(SavedViewState(tab: tab));

  void setSearch(String search) => emit(state.copyWith(search: search));
}
