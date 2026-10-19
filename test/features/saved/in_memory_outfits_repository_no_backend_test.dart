import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'F16_A16 InMemoryOutfitsRepository never imports or constructs a Firestore client — guest mode makes zero network calls, structurally',
    () {
      final file = File(
        'lib/features/saved/repository/in_memory_outfits_repository.dart',
      );
      final content = file.readAsStringSync();
      expect(content.contains('cloud_firestore'), isFalse);
      expect(content.contains('Firestore'), isFalse);
    },
  );
}
