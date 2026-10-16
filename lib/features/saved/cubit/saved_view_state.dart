class SavedViewState {
  const SavedViewState({this.tab = 'Saved', this.search = ''});

  /// 'Saved' | 'History'.
  final String tab;
  final String search;

  SavedViewState copyWith({String? tab, String? search}) => SavedViewState(
    tab: tab ?? this.tab,
    search: search ?? this.search,
  );
}
