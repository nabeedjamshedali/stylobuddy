import '../../../shared/models/clothing_item.dart';

class WardrobeState {
  const WardrobeState({this.items = const []});

  final List<ClothingItem> items;

  WardrobeState copyWith({List<ClothingItem>? items}) =>
      WardrobeState(items: items ?? this.items);
}
