import '../models/style_result.dart';

class StylistState {
  const StylistState({
    this.occasion = 'Everyday',
    this.styleDirection = 'Smart casual',
    this.weather = 'Mild / all season',
    this.results = const [],
    this.activeIndex = 0,
    this.selected = const [],
    this.locked = const [],
    this.accessories = true,
    this.category = 'All',
    this.isMatchMode = false,
    this.isGenerating = false,
  });

  final String occasion;
  final String styleDirection;
  final String weather;
  final List<StyleResult> results;
  final int activeIndex;
  final List<String> selected;
  final List<String> locked;
  final bool accessories;
  final String category;
  final bool isMatchMode;
  final bool isGenerating;

  /// The look shown on result detail; falls back to the first like the
  /// prototype's `S.results[S.activeOutfit]||S.results[0]`. Null when there
  /// are no results (missing, not empty).
  StyleResult? get activeResult {
    if (results.isEmpty) return null;
    if (activeIndex >= 0 && activeIndex < results.length) {
      return results[activeIndex];
    }
    return results.first;
  }

  StylistState copyWith({
    String? occasion,
    String? styleDirection,
    String? weather,
    List<StyleResult>? results,
    int? activeIndex,
    List<String>? selected,
    List<String>? locked,
    bool? accessories,
    String? category,
    bool? isMatchMode,
    bool? isGenerating,
  }) => StylistState(
    occasion: occasion ?? this.occasion,
    styleDirection: styleDirection ?? this.styleDirection,
    weather: weather ?? this.weather,
    results: results ?? this.results,
    activeIndex: activeIndex ?? this.activeIndex,
    selected: selected ?? this.selected,
    locked: locked ?? this.locked,
    accessories: accessories ?? this.accessories,
    category: category ?? this.category,
    isMatchMode: isMatchMode ?? this.isMatchMode,
    isGenerating: isGenerating ?? this.isGenerating,
  );
}
