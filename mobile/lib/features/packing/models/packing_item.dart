/// One packing checklist row. Prototype `{key,label,wardrobeId,packed}`
/// (`pkSuggested`/`pkAddWardrobe`/`pkCustom`).
class PackingItem {
  const PackingItem({
    required this.key,
    required this.label,
    this.wardrobeId,
    this.packed = false,
  });

  /// Stable row id: a `ClothingItem.id` for wardrobe pieces, or
  /// `'extra-<ts>'` for custom essentials.
  final String key;

  /// Stored display label; survives the wardrobe item being removed later
  /// (F10-A25).
  final String label;

  /// `ClothingItem.id` this row was added from; `null` for a custom
  /// essential (no wardrobe artwork).
  final String? wardrobeId;
  final bool packed;

  PackingItem copyWith({bool? packed}) => PackingItem(
    key: key,
    label: label,
    wardrobeId: wardrobeId,
    packed: packed ?? this.packed,
  );
}
