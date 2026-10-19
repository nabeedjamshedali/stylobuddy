import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F15-A08 (cheap, compile-time-safe check, same pattern as F14-A14's
/// `no_backend_leak_test.dart`): [InMemoryWardrobeRepository]'s source file
/// itself never imports a Firestore/Supabase/http client — guest mode makes
/// zero network calls, structurally, not "happens not to call one today".
void main() {
  test(
    'F15_A08 in_memory_wardrobe_repository.dart imports no cloud_firestore/http/supabase package',
    () {
      final file = File(
        'lib/features/wardrobe/repository/in_memory_wardrobe_repository.dart',
      );
      expect(file.existsSync(), isTrue, reason: 'run from repo root');

      final content = file.readAsStringSync();
      for (final banned in ['cloud_firestore', 'package:http', 'supabase']) {
        expect(
          content.contains(banned),
          isFalse,
          reason:
              'in_memory_wardrobe_repository.dart must never import/mention '
              '"$banned" — guest mode must make zero network calls '
              'structurally',
        );
      }
    },
  );
}
