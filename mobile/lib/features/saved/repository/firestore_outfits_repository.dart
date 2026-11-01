import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../../../shared/backend/firestore_service.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';
import 'outfits_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes under
/// `users/{uid}/outfits/{outfitId}` and `users/{uid}/wearEvents/{eventId}`
/// (schema doc §3-4) — document ids are `Outfit.id.toString()`/
/// `WearEvent.id.toString()` verbatim (F16-A03); the model fields stay
/// `int`, only the Firestore document id is the stringified form.
class FirestoreOutfitsRepository implements OutfitsRepository {
  FirestoreOutfitsRepository(FirestoreService service, String uid)
    : _outfits = service.subcollection<Outfit>(
        uid,
        'outfits',
        _outfitFromFirestore,
        _outfitToFirestore,
      ),
      _wearEvents = service.subcollection<WearEvent>(
        uid,
        'wearEvents',
        _wearEventFromFirestore,
        _wearEventToFirestore,
      );

  final CollectionReference<Outfit> _outfits;
  final CollectionReference<WearEvent> _wearEvents;

  static Outfit _outfitFromFirestore(Map<String, dynamic> data, String id) =>
      Outfit(
        // The real document id is the source of truth (F14-A13 precedent),
        // never a possibly-stale 'id' field, mirroring
        // FirestoreWardrobeRepository's own converter.
        id: int.tryParse(id) ?? (data['id'] as num?)?.toInt() ?? 0,
        name: data['name'] as String? ?? '',
        occasion: data['occasion'] as String? ?? '',
        items: List<String>.from(data['items'] as List? ?? const []),
        why: data['why'] as String? ?? '',
        worn: (data['worn'] as num?)?.toInt() ?? 0,
      );

  /// Public wrapper around [_outfitToFirestore] (F18 fix-round ruling):
  /// lets a shared bootstrap seed writer (`lib/app.dart`) reuse this
  /// repository's exact `outfits` document-write shape when seeding
  /// `SeedData.outfits` directly inside the combined D5 transaction.
  static Map<String, dynamic> seedFieldsForOutfit(Outfit outfit) =>
      _outfitToFirestore(outfit);

  static Map<String, dynamic> _outfitToFirestore(Outfit outfit) => {
    // 'id' duplicated on the document per the schema doc's convention
    // (F16-A04), consistent with F14-A12/F15-A03's shared converter
    // behavior.
    'id': outfit.id,
    'name': outfit.name,
    'occasion': outfit.occasion,
    'why': outfit.why,
    'items': outfit.items,
    'worn': outfit.worn,
  };

  static WearEvent _wearEventFromFirestore(
    Map<String, dynamic> data,
    String id,
  ) => WearEvent(
    id: int.tryParse(id) ?? (data['id'] as num?)?.toInt() ?? 0,
    outfitId: (data['outfitId'] as num?)?.toInt() ?? 0,
    name: data['name'] as String? ?? '',
    occasion: data['occasion'] as String? ?? '',
    items: List<String>.from(data['items'] as List? ?? const []),
    timestamp:
        (data['timestamp'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  static Map<String, dynamic> _wearEventToFirestore(WearEvent event) => {
    'id': event.id,
    'outfitId': event.outfitId,
    'name': event.name,
    'occasion': event.occasion,
    'items': event.items,
    'timestamp': Timestamp.fromDate(event.timestamp),
  };

  @override
  Stream<List<Outfit>> watchOutfits() => _outfits.snapshots().map((snapshot) {
    final outfits = snapshot.docs.map((doc) => doc.data()).toList();
    // Firestore returns docs in lexicographic-by-doc-id order with no
    // orderBy applied, whereas guest mode (InMemoryOutfitsRepository) is
    // always newest-first (a new/edited outfit is inserted at index 0).
    // Sort by id descending here so both modes present outfits in the
    // same order — Outfit.id is timestamp-derived (see
    // OutfitsCubit._newId), so this is also newest-first.
    outfits.sort((a, b) => b.id.compareTo(a.id));
    return outfits;
  });

  @override
  Stream<List<WearEvent>> watchWearEvents() =>
      _wearEvents.snapshots().map((snapshot) {
        final events = snapshot.docs.map((doc) => doc.data()).toList();
        // Newest first, tie-broken by id descending for equal timestamps
        // (F16-A12) — matches OutfitsCubit.wearEvents()'s existing sort.
        events.sort((a, b) {
          final c = b.timestamp.compareTo(a.timestamp);
          return c != 0 ? c : b.id.compareTo(a.id);
        });
        return events;
      });

  @override
  Future<Outfit> saveOrFind(
    Outfit draft, {
    required List<Outfit> current,
  }) async {
    for (final o in current) {
      if (listEquals(o.items, draft.items)) return o;
    }
    await _outfits.doc(draft.id.toString()).set(draft);
    return draft;
  }

  @override
  Future<Outfit> upsertManual({
    required Outfit candidate,
    int? editingId,
    required List<Outfit> current,
  }) async {
    if (editingId != null) {
      final doc = _outfits.doc(editingId.toString());
      try {
        // Only name/items/occasion are touched — 'worn' is deliberately
        // excluded from this partial update so it is left untouched
        // regardless of what [candidate.worn] happens to hold (F16-A05).
        await doc.update({
          'name': candidate.name,
          'occasion': candidate.occasion,
          'items': candidate.items,
        });
      } on FirebaseException catch (error) {
        // Controller ruling: the edit-in-place path falls back to a full
        // set() on a not-found failure (the document was concurrently
        // deleted on another device) rather than crashing or silently
        // dropping the edit.
        if (error.code == 'not-found') {
          await doc.set(candidate);
        } else {
          rethrow;
        }
      }
      return candidate;
    }
    await _outfits.doc(candidate.id.toString()).set(candidate);
    return candidate;
  }

  @override
  Future<void> delete(int id) => _outfits.doc(id.toString()).delete();

  @override
  Future<void> logWear(
    int outfitId, {
    required Outfit outfit,
    required WearEvent event,
  }) async {
    final outfitDoc = _outfits.doc(outfitId.toString());
    final eventDoc = _wearEvents.doc(event.id.toString());
    // Read-modify-write inside a single transaction (F16-A09, binding):
    // 'worn' is incremented off this transaction's own server-side read,
    // never off [outfit] (the caller's possibly-stale snapshot) — the new
    // WearEvent's name/occasion/items are likewise snapshotted from that
    // same fresh read (F16-A08), not from [outfit]/[event]. A missing
    // outfit document (deleted concurrently) makes this a silent no-op,
    // not a crash (F16-A13).
    await _outfits.firestore.runTransaction((tx) async {
      final snapshot = await tx.get(outfitDoc);
      final current = snapshot.data();
      if (current == null) return;
      tx.set(outfitDoc, current.copyWith(worn: current.worn + 1));
      tx.set(
        eventDoc,
        WearEvent(
          id: event.id,
          outfitId: outfitId,
          name: current.name,
          occasion: current.occasion,
          items: List<String>.of(current.items),
          timestamp: event.timestamp,
        ),
      );
    });
  }

  @override
  Future<void> removeWear(int eventId, {required WearEvent event}) async {
    final eventDoc = _wearEvents.doc(eventId.toString());
    // Read-modify-write inside a single transaction (F16-A09, binding):
    // reads the target WearEvent and its parent outfit server-side,
    // clamps 'worn' at 0 off that fresh read (F16-A10), deletes the event
    // and writes the clamped worn value atomically. A missing event
    // document is a silent no-op, not a crash (F16-A14).
    await _outfits.firestore.runTransaction((tx) async {
      final eventSnapshot = await tx.get(eventDoc);
      final storedEvent = eventSnapshot.data();
      if (storedEvent == null) return;
      final outfitDoc = _outfits.doc(storedEvent.outfitId.toString());
      final outfitSnapshot = await tx.get(outfitDoc);
      final currentOutfit = outfitSnapshot.data();
      tx.delete(eventDoc);
      if (currentOutfit != null) {
        tx.set(
          outfitDoc,
          currentOutfit.copyWith(
            worn: currentOutfit.worn > 0 ? currentOutfit.worn - 1 : 0,
          ),
        );
      }
    });
  }
}
