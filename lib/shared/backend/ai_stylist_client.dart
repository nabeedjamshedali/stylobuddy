import '../models/clothing_item.dart';

/// Wire value of a stylist request (F26 §6.1).
enum AiStylistMode {
  auto('auto'),
  match('match');

  const AiStylistMode(this.wire);

  final String wire;
}

/// Longest prefix of [s] made of whole code points whose UTF-16 length is at
/// most [max]. Never splits a surrogate pair.
String truncateUtf16(String s, int max) {
  if (s.length <= max) return s;
  final buffer = StringBuffer();
  var length = 0;
  for (final rune in s.runes) {
    final units = rune > 0xFFFF ? 2 : 1;
    if (length + units > max) break;
    buffer.writeCharCode(rune);
    length += units;
  }
  return buffer.toString();
}

/// What the app asks the AI stylist to compose (F26 §6.1 / §6.4).
class AiStylistRequest {
  const AiStylistRequest({
    required this.mode,
    required this.occasion,
    required this.styleDirection,
    required this.weather,
    required this.includeAccessories,
    required this.lockedIds,
    required this.selectedIds,
    required this.items,
  });

  /// The server rejects any string longer than this (UTF-16 units).
  static const maxFieldLength = 60;

  final AiStylistMode mode;
  final String occasion;
  final String styleDirection;
  final String weather;
  final bool includeAccessories;
  final List<String> lockedIds;
  final List<String> selectedIds;
  final List<ClothingItem> items;

  /// Exactly the eight request keys; each item exactly six keys. Photos,
  /// wear counts and source ids are never sent.
  Map<String, Object> toJson() {
    String t(String s) => truncateUtf16(s, maxFieldLength);
    return {
      'occasion': t(occasion),
      'styleDirection': t(styleDirection),
      'weather': t(weather),
      'includeAccessories': includeAccessories,
      'mode': mode.wire,
      'lockedIds': [for (final id in lockedIds) t(id)],
      'selectedIds': [for (final id in selectedIds) t(id)],
      'items': [
        for (final i in items)
          {
            'id': t(i.id),
            'name': t(i.name),
            'category': t(i.category),
            'color': t(i.color),
            'occasion': t(i.occasion),
            'season': t(i.season),
          },
      ],
    };
  }
}

/// One look composed by the AI.
class AiOutfit {
  const AiOutfit({
    required this.name,
    required this.why,
    required this.itemIds,
  });

  final String name;
  final String why;
  final List<String> itemIds;

  @override
  bool operator ==(Object other) =>
      other is AiOutfit &&
      other.name == name &&
      other.why == why &&
      _sameList(other.itemIds, itemIds);

  @override
  int get hashCode => Object.hash(name, why, Object.hashAll(itemIds));

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Source of AI outfits (F26). SDK-free so the Cubit never depends on HTTP or
/// Firebase.
abstract interface class AiStylistClient {
  /// 1+ outfits on success; null on ANY failure. Never throws.
  Future<List<AiOutfit>?> suggest(AiStylistRequest request);
}
