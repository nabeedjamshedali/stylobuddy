class WardrobeBrowseState {
  const WardrobeBrowseState({this.filter = 'All', this.search = ''});

  final String filter;
  final String search;

  WardrobeBrowseState copyWith({String? filter, String? search}) =>
      WardrobeBrowseState(
        filter: filter ?? this.filter,
        search: search ?? this.search,
      );
}
