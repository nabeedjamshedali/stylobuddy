import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F23-A18: `ai-stylist` (docs/features/F23-ai-stylist-stub.md) is a
/// deployed-but-unreferenced Edge Function this round — no Flutter code may
/// call it. This is a structural check, not a behavioral one: every file
/// under `lib/` is scanned, and the test fails (naming the offending file)
/// if any contains "ai-stylist" (case-insensitive) or "functions/v1/ai".
/// It passes on the current tree: today the only Edge Function reference
/// in `lib/` is `storage-upload-url` in
/// `lib/shared/backend/storage_repository.dart`.
void main() {
  test(
    'F23_A18 no lib/ file references ai-stylist',
    () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'run from repo root');

      final offenders = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        final lower = content.toLowerCase();
        if (lower.contains('ai-stylist') || lower.contains('functions/v1/ai')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'lib/ must not reference ai-stylist: $offenders',
      );
    },
  );
}
