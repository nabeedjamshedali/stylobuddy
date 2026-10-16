import 'packing_item.dart';

/// A trip record. Prototype `{id,name,destination,start,end,type,notes,
/// days,items}` (`pkSaveDraft`).
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.start,
    required this.end,
    required this.type,
    required this.notes,
    required this.days,
    this.items = const [],
  });

  /// `'trip-<ts>'`.
  final String id;
  final String name;
  final String destination;

  /// `yyyy-MM-dd`, or `''` when not set.
  final String start;

  /// `yyyy-MM-dd`, or `''` when not set.
  final String end;
  final String type;
  final String notes;
  final int days;
  final List<PackingItem> items;

  Trip copyWith({List<PackingItem>? items}) => Trip(
    id: id,
    name: name,
    destination: destination,
    start: start,
    end: end,
    type: type,
    notes: notes,
    days: days,
    items: items ?? this.items,
  );
}
