/// One generated look (prototype `S.results[i]`).
class StyleResult {
  const StyleResult({
    required this.id,
    required this.name,
    required this.items,
    required this.occasion,
    required this.why,
  });

  final int id;
  final String name;
  final List<String> items;
  final String occasion;
  final String why;

  StyleResult copyWith({
    int? id,
    String? name,
    List<String>? items,
    String? occasion,
    String? why,
  }) => StyleResult(
    id: id ?? this.id,
    name: name ?? this.name,
    items: items ?? this.items,
    occasion: occasion ?? this.occasion,
    why: why ?? this.why,
  );
}
