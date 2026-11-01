import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/planned_entry.dart';

/// Seed content ported from the HTML prototype (`app.js` lines 2-5, 81-83).
abstract final class SeedData {
  static const List<String> categories = [
    'Shirts',
    'Pants',
    'Shoes',
    'Dresses',
    'Skirts',
    'Outerwear',
    'Accessories',
  ];
  static const List<String> colors = [
    'White',
    'Black',
    'Navy',
    'Blue',
    'Cream',
    'Beige',
    'Brown',
    'Green',
    'Rose',
    'Sage',
    'Tan',
    'Gold',
  ];
  static const List<String> occasions = [
    'Everyday',
    'Casual',
    'Office',
    'Wedding',
    'Party',
    'Date Night',
    'Travel',
  ];
  static const List<String> seasons = [
    'All season',
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
  ];

  // id, name, category, color, occasion
  static const List<List<String>> _rows = [
    ['white-shirt', 'White Oxford Shirt', 'Shirts', 'White', 'Office'],
    ['black-shirt', 'Black Shirt', 'Shirts', 'Black', 'Party'],
    ['blue-shirt', 'Blue Denim Shirt', 'Shirts', 'Blue', 'Casual'],
    ['cream-blouse', 'Cream Blouse', 'Shirts', 'Cream', 'Office'],
    ['navy-chinos', 'Navy Chinos', 'Pants', 'Navy', 'Office'],
    ['beige-chinos', 'Beige Chinos', 'Pants', 'Beige', 'Casual'],
    ['black-jeans', 'Black Jeans', 'Pants', 'Black', 'Casual'],
    ['blue-jeans', 'Blue Jeans', 'Pants', 'Blue', 'Casual'],
    ['white-sneakers', 'White Sneakers', 'Shoes', 'White', 'Casual'],
    ['brown-loafers', 'Brown Loafers', 'Shoes', 'Brown', 'Office'],
    ['black-boots', 'Black Boots', 'Shoes', 'Black', 'Party'],
    ['black-watch', 'Black Watch', 'Accessories', 'Black', 'Office'],
    ['black-bag', 'Black Bag', 'Accessories', 'Black', 'Everyday'],
    ['floral-dress', 'Floral Dress', 'Dresses', 'Rose', 'Date Night'],
    ['sage-dress', 'Sage Dress', 'Dresses', 'Sage', 'Wedding'],
    ['black-skirt', 'Black Skirt', 'Skirts', 'Black', 'Office'],
    ['tan-belt', 'Tan Belt', 'Accessories', 'Tan', 'Office'],
    ['gold-jewelry', 'Gold Jewelry', 'Accessories', 'Gold', 'Wedding'],
    ['sunglasses', 'Sunglasses', 'Accessories', 'Black', 'Casual'],
    ['cream-cardigan', 'Cream Cardigan', 'Outerwear', 'Cream', 'Casual'],
    ['black-heels', 'Black Heels', 'Shoes', 'Black', 'Party'],
    ['denim-jacket', 'Denim Jacket', 'Outerwear', 'Blue', 'Casual'],
    ['white-tee', 'White Tee', 'Shirts', 'White', 'Everyday'],
  ];

  static List<ClothingItem> get items => [
    for (var i = 0; i < _rows.length; i++)
      ClothingItem(
        id: _rows[i][0],
        name: _rows[i][1],
        category: _rows[i][2],
        color: _rows[i][3],
        occasion: _rows[i][4],
        wears: i % 5,
      ),
  ];

  static List<Outfit> get outfits => [
    const Outfit(
      id: 1,
      name: 'Everyday Essential',
      occasion: 'Everyday',
      items: ['white-shirt', 'navy-chinos', 'white-sneakers', 'black-watch'],
      why:
          'A crisp oxford creates structure, while navy chinos and white sneakers keep everything relaxed and balanced.',
    ),
    const Outfit(
      id: 2,
      name: 'Modern Weekend',
      occasion: 'Casual',
      items: ['black-shirt', 'beige-chinos', 'brown-loafers', 'black-watch'],
      why:
          'Earthy tailored trousers ground the dark shirt, creating an understated smart-casual look.',
    ),
  ];

  static Map<String, PlannedEntry> get planned => {
    '2026-10-15': const PlannedEntry(outfitId: 1, occasion: 'Everyday'),
  };
}
