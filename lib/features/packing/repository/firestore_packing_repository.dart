import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/backend/firestore_service.dart';
import '../models/packing_item.dart';
import '../models/trip.dart';
import 'packing_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes of
/// `users/{uid}/packingTrips/{tripId}` documents (schema doc §6). A `Trip`,
/// including its embedded `items` array, is always read/written as ONE
/// whole document — never a sub-subcollection for items (confirmed by
/// F20-A01: no document is ever written under `.../items/*`).
///
/// Document ID is `Trip.id.toString()` verbatim (architecture D4, F20-A02).
///
/// [saveTrip]'s edit branch (`isNew: false`) is a targeted merge-set
/// touching every field EXCEPT `items` (feature doc §6's binding non-clobber
/// rationale) — written via [_rawTrips] (an untyped `Map<String, dynamic>`
/// collection reference over the SAME underlying Firestore path as
/// [_trips]) specifically so `items` is never a key in that write's map,
/// even as a no-op/equal value; the typed `_trips.doc(id).set(trip)` call
/// used by the create branch would unconditionally serialize `trip.items`
/// too, which would be able to clobber a concurrently in-flight
/// toggle/removeItem/addWardrobe/addCustom/generateChecklist call's
/// `runTransaction` write to the same document.
///
/// [toggle]/[removeItem]/[addWardrobe]/[addCustom]/[generateChecklist] each
/// build their own pure `List<PackingItem> -> List<PackingItem>` transform
/// (mirroring `PackingCubit`'s exact existing logic) and delegate to the
/// shared private [_mutateItems] helper, which runs a `runTransaction` that
/// reads the target trip's `items` fresh from the server, applies the
/// transform, and writes the whole `Trip` back (same other fields, new
/// `items`) in the same transaction — never a bare `get()` followed by a
/// separate `set()`/`update()` (F20-A06).
class FirestorePackingRepository implements PackingRepository {
  FirestorePackingRepository(FirestoreService service, String uid)
    : _trips = service.subcollection<Trip>(
        uid,
        'packingTrips',
        _tripFromFirestore,
        _tripToFirestore,
      ),
      _rawTrips = service.userDoc(uid).collection('packingTrips');

  final CollectionReference<Trip> _trips;
  final CollectionReference<Map<String, dynamic>> _rawTrips;

  static Trip _tripFromFirestore(Map<String, dynamic> data, String id) => Trip(
    // The real document id is the source of truth (F14-A13 precedent),
    // never a possibly-stale 'id' field.
    id: id,
    name: data['name'] as String? ?? '',
    destination: data['destination'] as String? ?? '',
    start: data['start'] as String? ?? '',
    end: data['end'] as String? ?? '',
    type: data['type'] as String? ?? '',
    notes: data['notes'] as String? ?? '',
    days: (data['days'] as num?)?.toInt() ?? 0,
    // A missing 'items' field defaults to [] (F20-A16), distinct from an
    // explicitly-present 'items': [] (also []) but exercised via a
    // different code path in tests.
    items: _itemsFromFirestore(data['items']),
  );

  static List<PackingItem> _itemsFromFirestore(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map)
          PackingItem(
            key: entry['key'] as String? ?? '',
            label: entry['label'] as String? ?? '',
            wardrobeId: entry['wardrobeId'] as String?,
            packed: entry['packed'] as bool? ?? false,
          ),
    ];
  }

  static Map<String, dynamic> _tripToFirestore(Trip trip) => {
    // 'id' duplicated on the document per the schema doc's convention,
    // consistent with F14-A12/F15-A03's shared converter behavior.
    'id': trip.id,
    'name': trip.name,
    'destination': trip.destination,
    'start': trip.start,
    'end': trip.end,
    'type': trip.type,
    'notes': trip.notes,
    'days': trip.days,
    'items': _itemsToFirestore(trip.items),
  };

  static List<Map<String, dynamic>> _itemsToFirestore(
    List<PackingItem> items,
  ) => [
    for (final i in items)
      {'key': i.key, 'label': i.label, 'wardrobeId': i.wardrobeId, 'packed': i.packed},
  ];

  @override
  Stream<List<Trip>> watchTrips() => _trips.snapshots().map((snapshot) {
    final trips = snapshot.docs.map((doc) => doc.data()).toList();
    // Firestore returns docs in lexicographic-by-doc-id order with no
    // orderBy applied, whereas guest mode (InMemoryPackingRepository) is
    // always newest-first (a new trip is inserted at index 0). Sort by id
    // descending here so both modes present trips in the same order —
    // Trip.id is 'trip-<ts>', a timestamp-derived string, so this is also
    // newest-first.
    trips.sort((a, b) => b.id.compareTo(a.id));
    return trips;
  });

  @override
  Future<void> saveTrip(Trip trip, {required bool isNew}) {
    if (isNew) {
      // Whole-document create (items: [] per the Cubit's own create-branch
      // logic, F20-A01) — no concurrent items-mutating call can race a
      // document that doesn't exist yet.
      return _trips.doc(trip.id).set(trip);
    }
    // Targeted merge-set excluding 'items' (see class doc) — never the
    // typed _trips.doc(id).set(trip), which would also write trip.items.
    return _rawTrips.doc(trip.id).set({
      'id': trip.id,
      'name': trip.name,
      'destination': trip.destination,
      'start': trip.start,
      'end': trip.end,
      'type': trip.type,
      'notes': trip.notes,
      'days': trip.days,
    }, SetOptions(merge: true));
  }

  Future<void> _mutateItems(
    String tripId,
    List<PackingItem> Function(List<PackingItem> current) transform,
  ) {
    final doc = _trips.doc(tripId);
    return _trips.firestore.runTransaction((tx) async {
      final snapshot = await tx.get(doc);
      final current = snapshot.data();
      // A missing document (deleted concurrently, e.g. by a deleteTrip
      // call from another device landing first) is a silent no-op, not a
      // crash (F20-A15, F16-A13/A14 precedent).
      if (current == null) return;
      tx.set(doc, current.copyWith(items: transform(current.items)));
    });
  }

  @override
  Future<void> toggle(String tripId, String key) => _mutateItems(
    tripId,
    (items) => [
      for (final i in items) i.key == key ? i.copyWith(packed: !i.packed) : i,
    ],
  );

  @override
  Future<void> removeItem(String tripId, String key) =>
      _mutateItems(tripId, (items) => items.where((i) => i.key != key).toList());

  @override
  Future<void> addWardrobe(String tripId, PackingItem item) => _mutateItems(
    tripId,
    (items) => items.any((i) => i.wardrobeId == item.wardrobeId)
        ? items
        : [...items, item],
  );

  @override
  Future<void> addCustom(String tripId, PackingItem item) =>
      _mutateItems(tripId, (items) => [...items, item]);

  @override
  Future<void> generateChecklist(String tripId, List<PackingItem> suggested) =>
      _mutateItems(tripId, (items) => items.isEmpty ? suggested : items);

  @override
  Future<void> deleteTrip(String tripId) => _trips.doc(tripId).delete();
}
