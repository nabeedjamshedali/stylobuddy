/// Who produced a look (F26): the real AI or today's algorithmic fallback.
enum StyleResultSource { ai, algorithm }

/// One generated look (prototype `S.results[i]`).
class StyleResult {
  const StyleResult({
    required this.id,
    required this.name,
    required this.items,
    required this.occasion,
    required this.why,
    this.source = StyleResultSource.algorithm,
  });

  final int id;
  final String name;
  final List<String> items;
  final String occasion;
  final String why;
  final StyleResultSource source;

  StyleResult copyWith({
    int? id,
    String? name,
    List<String>? items,
    String? occasion,
    String? why,
    StyleResultSource? source,
  }) => StyleResult(
    id: id ?? this.id,
    name: name ?? this.name,
    items: items ?? this.items,
    occasion: occasion ?? this.occasion,
    why: why ?? this.why,
    source: source ?? this.source,
  );
}
