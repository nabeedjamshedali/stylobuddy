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

  Trip copyWith({
    String? name,
    String? destination,
    String? start,
    String? end,
    String? type,
    String? notes,
    int? days,
    List<PackingItem>? items,
  }) => Trip(
    id: id,
    name: name ?? this.name,
    destination: destination ?? this.destination,
    start: start ?? this.start,
    end: end ?? this.end,
    type: type ?? this.type,
    notes: notes ?? this.notes,
    days: days ?? this.days,
    items: items ?? this.items,
  );
}
