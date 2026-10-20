import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/packing/cubit/packing_cubit.dart';
import 'package:stylobuddy/features/packing/models/trip.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

void main() {
  late PackingCubit cubit;
  final seed = SeedData.items;

  setUp(() => cubit = PackingCubit());
  tearDown(() => cubit.close());

  group('saveDraft validation', () {
    test('F10_A03 blank name toasts and creates no trip', () {
      cubit.newTrip();
      final result = cubit.saveDraft(
        name: '',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Add a trip name and both dates');
      expect(cubit.state.trips, isEmpty);
    });

    test('F10_A04 whitespace-only name is treated as blank', () {
      cubit.newTrip();
      final result = cubit.saveDraft(
        name: '   ',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Add a trip name and both dates');
      expect(cubit.state.trips, isEmpty);
    });

    test('F10_A05 missing start or missing end toasts the same message', () {
      cubit.newTrip();
      final noStart = cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      expect(noStart.errorMessage, 'Add a trip name and both dates');

      final noEnd = cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '',
        type: 'Vacation',
        notes: '',
      );
      expect(noEnd.errorMessage, 'Add a trip name and both dates');
      expect(cubit.state.trips, isEmpty);
    });

    test('F10_A06 end before start rejected; equal dates accepted (1 day)', () {
      cubit.newTrip();
      final badOrder = cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-05',
        end: '2026-11-01',
        type: 'Vacation',
        notes: '',
      );
      expect(badOrder.success, isFalse);
      expect(badOrder.errorMessage, 'End date must be after start date');
      expect(cubit.state.trips, isEmpty);

      final sameDay = cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-05',
        end: '2026-11-05',
        type: 'Vacation',
        notes: '',
      );
      expect(sameDay.success, isTrue);
      expect(cubit.state.trips.single.days, 1);
    });

    test('F10_A07 days are whole inclusive days, minimum 1', () {
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      expect(cubit.state.trips.single.days, 3);
    });

    test(
      'F10_A08 a valid new trip is inserted at the front, trimmed, with '
      'empty items; editing keeps the id and existing items',
      () {
        cubit.newTrip();
        final result = cubit.saveDraft(
          name: '  Lisbon getaway  ',
          destination: '  Lisbon  ',
          start: '2026-11-01',
          end: '2026-11-03',
          type: 'Vacation',
          notes: '  bring sunscreen  ',
        );
        expect(result.success, isTrue);
        expect(result.wasEditing, isFalse);
        final created = cubit.state.trips.first;
        expect(created.id, startsWith('trip-'));
        expect(created.name, 'Lisbon getaway');
        expect(created.destination, 'Lisbon');
        expect(created.notes, 'bring sunscreen');
        expect(created.items, isEmpty);

        // A second trip is inserted in front of the first.
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Second trip',
          destination: '',
          start: '2026-12-01',
          end: '2026-12-02',
          type: 'Vacation',
          notes: '',
        );
        expect(cubit.state.trips.first.name, 'Second trip');
        expect(cubit.state.trips.length, 2);

        // Edit the first (now second in list) trip: keeps id and items.
        cubit.selectTrip(created.id);
        cubit.generateChecklist(seed);
        cubit.editTrip(created.id);
        final editResult = cubit.saveDraft(
          name: 'Lisbon renamed',
          destination: 'Lisbon',
          start: '2026-11-01',
          end: '2026-11-04',
          type: 'Vacation',
          notes: '',
        );
        expect(editResult.success, isTrue);
        expect(editResult.wasEditing, isTrue);
        expect(editResult.tripId, created.id);
        final edited = cubit.state.trips.firstWhere((t) => t.id == created.id);
        expect(edited.name, 'Lisbon renamed');
        expect(edited.days, 4);
        expect(edited.items, isNotEmpty);
        expect(cubit.state.trips.length, 2);
      },
    );
  });

  group('suggestions (pkSuggested port)', () {
    test(
      'F10_A09 a 3-day Vacation trip yields the 9 base pieces + 2 extras '
      'in wardrobe order',
      () {
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Trip',
          destination: '',
          start: '2026-11-01',
          end: '2026-11-03',
          type: 'Vacation',
          notes: '',
        );
        final trip = cubit.state.selectedTrip!;
        final result = cubit.suggestions(trip, seed);
        expect(result.map((i) => i.key).toList(), [
          'white-shirt',
          'black-shirt',
          'blue-shirt',
          'cream-blouse',
          'navy-chinos',
          'beige-chinos',
          'black-jeans',
          'blue-jeans',
          'white-sneakers',
          'black-watch',
          'black-bag',
        ]);
        expect(result.length, 11);
        expect(result.every((i) => !i.packed), isTrue);
        for (final i in result) {
          final item = seed.firstWhere((x) => x.id == i.key);
          expect(i.label, item.name);
        }
      },
    );

    test('F10_A10 a 1-day trip yields 5+2=7; a 5-day trip yields 12+2=14', () {
      final oneDay = const _StubDays(1);
      final fiveDay = const _StubDays(5);
      expect(cubit.suggestions(oneDay.toTrip(), seed).length, 7);
      expect(cubit.suggestions(fiveDay.toTrip(), seed).length, 14);
    });

    test(
      'F10_A11 Business trips list Office-occasion base items first, in '
      'wardrobe order',
      () {
        final trip = const _StubDays(1).toTrip(type: 'Business');
        final result = cubit.suggestions(trip, seed);
        expect(result.take(5).map((i) => i.key).toList(), [
          'white-shirt',
          'cream-blouse',
          'navy-chinos',
          'brown-loafers',
          'black-skirt',
        ]);
      },
    );

    test('F10_A12 an empty wardrobe yields an empty suggestion list', () {
      final trip = const _StubDays(3).toTrip();
      expect(cubit.suggestions(trip, const <ClothingItem>[]), isEmpty);
    });
  });

  group('checklist generation and editing', () {
    test(
      'F10_A13 generating fills items only once; running again does not '
      'duplicate or reset packed flags',
      () {
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Trip',
          destination: '',
          start: '2026-11-01',
          end: '2026-11-03',
          type: 'Vacation',
          notes: '',
        );
        cubit.generateChecklist(seed);
        final firstCount = cubit.state.selectedTrip!.items.length;
        cubit.toggle(cubit.state.selectedTrip!.items.first.key);
        cubit.generateChecklist(seed);
        expect(cubit.state.selectedTrip!.items.length, firstCount);
        expect(cubit.state.selectedTrip!.items.first.packed, isTrue);
      },
    );

    test('F10_A14 toggling an item flips packed', () {
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      cubit.generateChecklist(seed);
      final key = cubit.state.selectedTrip!.items.first.key;
      cubit.toggle(key);
      expect(
        cubit.state.selectedTrip!.items.firstWhere((i) => i.key == key).packed,
        isTrue,
      );
      cubit.toggle(key);
      expect(
        cubit.state.selectedTrip!.items.firstWhere((i) => i.key == key).packed,
        isFalse,
      );
    });

    test(
      'F20_A20_followup toggling a stale/absent key is a silent no-op '
      '(matches removeItem\'s already-established stale-key behavior) '
      'rather than throwing',
      () {
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Trip',
          destination: '',
          start: '2026-11-01',
          end: '2026-11-03',
          type: 'Vacation',
          notes: '',
        );
        cubit.generateChecklist(seed);
        final before = cubit.state.selectedTrip!.items
            .map((i) => i.packed)
            .toList();
        expect(() => cubit.toggle('no-such-key'), returnsNormally);
        expect(
          cubit.state.selectedTrip!.items.map((i) => i.packed).toList(),
          before,
        );
      },
    );

    test('F10_A16 removing a checklist row deletes it', () {
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      cubit.generateChecklist(seed);
      final key = cubit.state.selectedTrip!.items.first.key;
      final before = cubit.state.selectedTrip!.items.length;
      cubit.removeItem(key);
      expect(cubit.state.selectedTrip!.items.length, before - 1);
      expect(
        cubit.state.selectedTrip!.items.any((i) => i.key == key),
        isFalse,
      );
    });

    test(
      'F10_A17 adding a wardrobe item appends it once; adding the same id '
      'twice never duplicates',
      () {
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Trip',
          destination: '',
          start: '2026-11-01',
          end: '2026-11-02',
          type: 'Vacation',
          notes: '',
        );
        final item = seed.firstWhere((i) => i.id == 'denim-jacket');
        cubit.addWardrobe(item);
        expect(cubit.state.selectedTrip!.items.length, 1);
        final added = cubit.state.selectedTrip!.items.single;
        expect(added.key, item.id);
        expect(added.label, item.name);
        expect(added.wardrobeId, item.id);
        expect(added.packed, isFalse);

        cubit.addWardrobe(item);
        expect(cubit.state.selectedTrip!.items.length, 1);
      },
    );

    test(
      'F10_A18 a blank/whitespace custom item adds nothing; a real label '
      'adds a row with no wardrobeId',
      () {
        cubit.newTrip();
        cubit.saveDraft(
          name: 'Trip',
          destination: '',
          start: '2026-11-01',
          end: '2026-11-02',
          type: 'Vacation',
          notes: '',
        );
        cubit.addCustom('   ');
        expect(cubit.state.selectedTrip!.items, isEmpty);

        cubit.addCustom('Phone charger');
        final added = cubit.state.selectedTrip!.items.single;
        expect(added.label, 'Phone charger');
        expect(added.wardrobeId, isNull);
        expect(added.packed, isFalse);
      },
    );
  });

  test('F10_A20 deleting the selected trip removes it and clears selection', () {
    cubit.newTrip();
    cubit.saveDraft(
      name: 'Trip',
      destination: '',
      start: '2026-11-01',
      end: '2026-11-02',
      type: 'Vacation',
      notes: '',
    );
    final id = cubit.state.selectedTripId;
    cubit.deleteSelectedTrip();
    expect(cubit.state.trips.any((t) => t.id == id), isFalse);
    expect(cubit.state.selectedTripId, isNull);
  });

  test('a trip with zero items has no suggestions duplicated by edit flow', () {
    cubit.newTrip();
    expect(cubit.state.draft, isNotNull);
    expect(cubit.state.selectedTripId, isNull);
  });
}

/// Builds a [Trip] stub with a given day count for pure suggestion tests
/// that don't need the save-draft date math.
class _StubDays {
  const _StubDays(this.days);
  final int days;

  Trip toTrip({String type = 'Vacation'}) => Trip(
    id: 'stub',
    name: 'Stub',
    destination: '',
    start: '2026-11-01',
    end: '2026-11-0$days',
    type: type,
    notes: '',
    days: days,
  );
}
