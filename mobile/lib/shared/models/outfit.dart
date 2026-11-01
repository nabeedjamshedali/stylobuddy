class Outfit {
  const Outfit({
    required this.id,
    required this.name,
    required this.occasion,
    required this.items,
    required this.why,
    this.worn = 0,
  });

  final int id;
  final String name;
  final String occasion;
  final List<String> items;
  final String why;
  final int worn;

  Outfit copyWith({
    int? id,
    String? name,
    String? occasion,
    List<String>? items,
    String? why,
    int? worn,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      occasion: occasion ?? this.occasion,
      items: items ?? this.items,
      why: why ?? this.why,
      worn: worn ?? this.worn,
    );
  }
}
