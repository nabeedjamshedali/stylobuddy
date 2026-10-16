import '../../../shared/models/clothing_item.dart';

/// A look item resolved against the wardrobe (with the prototype's
/// fallback for ids that are no longer owned).
class LookPiece {
  const LookPiece({required this.item, required this.locked});

  final ClothingItem item;

  /// Match mode: mandatory piece that cannot be swapped.
  final bool locked;

  String get id => item.id;
  String get name => item.name;
  String get imageId => item.imageId;
}
