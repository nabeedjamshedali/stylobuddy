import 'trip.dart';

/// Pre-fill values for the new-trip form. Prototype `S.tripDraft`.
class TripDraft {
  const TripDraft({
    this.name = '',
    this.destination = '',
    this.start = '',
    this.end = '',
    this.type = 'Vacation',
    this.notes = '',
  });

  factory TripDraft.fromTrip(Trip trip) => TripDraft(
    name: trip.name,
    destination: trip.destination,
    start: trip.start,
    end: trip.end,
    type: trip.type,
    notes: trip.notes,
  );

  final String name;
  final String destination;
  final String start;
  final String end;
  final String type;
  final String notes;
}
