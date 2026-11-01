import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/packing/models/packing_item.dart';
import 'package:stylobuddy/features/packing/models/trip.dart';
import 'package:stylobuddy/features/packing/repository/in_memory_packing_repository.dart';

void main() {
  Trip makeTrip({String id = 'trip-1', List<PackingItem> items = const []}) =>
      Trip(
        id: id,
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
        days: 2,
        items: items,
      );

  test(
    'F20_A12 InMemoryPackingRepository\'s write methods each return a '
    'SynchronousFuture (already complete in the same microtask the call '
    'returns, before any pump/await)',
    () {
      final repository = InMemoryPackingRepository();
      final trip = makeTrip();

      var saveTripCompleted = false;
      repository.saveTrip(trip, isNew: true).then((_) => saveTripCompleted = true);
      expect(saveTripCompleted, isTrue);

      var toggleCompleted = false;
      repository.toggle('trip-1', 'x').then((_) => toggleCompleted = true);
      expect(toggleCompleted, isTrue);

      var removeCompleted = false;
      repository.removeItem('trip-1', 'x').then((_) => removeCompleted = true);
      expect(removeCompleted, isTrue);

      var addWardrobeCompleted = false;
      repository
          .addWardrobe('trip-1', const PackingItem(key: 'a', label: 'A'))
          .then((_) => addWardrobeCompleted = true);
      expect(addWardrobeCompleted, isTrue);

      var addCustomCompleted = false;
      repository
          .addCustom('trip-1', const PackingItem(key: 'b', label: 'B'))
          .then((_) => addCustomCompleted = true);
      expect(addCustomCompleted, isTrue);

      var generateCompleted = false;
      repository
          .generateChecklist('trip-1', const [])
          .then((_) => generateCompleted = true);
      expect(generateCompleted, isTrue);

      var deleteCompleted = false;
      repository.deleteTrip('trip-1').then((_) => deleteCompleted = true);
      expect(deleteCompleted, isTrue);
    },
  );

  test(
    'F20_A13 InMemoryPackingRepository never imports or constructs a '
    'Firestore client — verified structurally by source inspection (no '
    'cloud_firestore import)',
    () {
      final content = _fileContent(
        'lib/features/packing/repository/in_memory_packing_repository.dart',
      );
      expect(content.contains('cloud_firestore'), isFalse);
      expect(content.contains('FirebaseFirestore'), isFalse);
    },
  );

  test(
    'F20_A15_in_memory toggle/removeItem/addWardrobe/addCustom/'
    'generateChecklist against an unknown tripId are silent no-ops',
    () {
      final repository = InMemoryPackingRepository();
      expect(() => repository.toggle('missing', 'x'), returnsNormally);
      expect(() => repository.removeItem('missing', 'x'), returnsNormally);
      expect(
        () => repository.addWardrobe(
          'missing',
          const PackingItem(key: 'x', label: 'X'),
        ),
        returnsNormally,
      );
      expect(
        () => repository.addCustom(
          'missing',
          const PackingItem(key: 'x', label: 'X'),
        ),
        returnsNormally,
      );
      expect(
        () => repository.generateChecklist('missing', const []),
        returnsNormally,
      );
      expect(repository.snapshot, isEmpty);
    },
  );
}

String _fileContent(String path) => File(path).readAsStringSync();
