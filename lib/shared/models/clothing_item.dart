class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.occasion,
    this.season = 'All season',
    this.wears = 0,
    this.sourceId,
  });

  final String id;
  final String name;
  final String category;
  final String color;
  final String occasion;
  final String season;
  final int wears;

  /// Id of the seed garment whose artwork this item reuses (imported items).
  final String? sourceId;

  String get imageId => sourceId ?? id;

  ClothingItem copyWith({
    String? name,
    String? category,
    String? color,
    String? occasion,
    String? season,
    int? wears,
    String? sourceId,
  }) {
    return ClothingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      color: color ?? this.color,
      occasion: occasion ?? this.occasion,
      season: season ?? this.season,
      wears: wears ?? this.wears,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
