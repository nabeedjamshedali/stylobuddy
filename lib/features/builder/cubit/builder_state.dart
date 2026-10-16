/// Prototype `S.manual*` fields: the manual outfit draft being built.
class BuilderState {
  const BuilderState({
    this.picked = const [],
    this.category = 'All',
    this.editingId,
    this.name = '',
    this.occasion = 'Everyday',
  });

  final List<String> picked;
  final String category;
  final int? editingId;
  final String name;
  final String occasion;

  bool get isEditing => editingId != null;

  BuilderState copyWith({
    List<String>? picked,
    String? category,
    int? editingId,
    String? name,
    String? occasion,
  }) => BuilderState(
    picked: picked ?? this.picked,
    category: category ?? this.category,
    editingId: editingId ?? this.editingId,
    name: name ?? this.name,
    occasion: occasion ?? this.occasion,
  );
}
