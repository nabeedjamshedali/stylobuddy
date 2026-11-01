import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F23-A18 (amended 2026-10-30 for F26): the `ai-stylist` Edge Function is
/// wired in exactly one place, `lib/shared/backend/http_ai_stylist_client.dart`.
/// No view, widget or Cubit may talk to the endpoint directly. Every file
/// under `lib/` is scanned; the test fails (naming the file) if any file other
/// than that one contains "ai-stylist" (case-insensitive) or "functions/v1/ai",
/// or if that file is missing or lacks "functions/v1/ai-stylist".
void main() {
  test('F23_A18 only the HTTP client references ai-stylist', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from repo root');

    const clientPath = 'lib/shared/backend/http_ai_stylist_client.dart';
    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\', '/');
      if (path == clientPath) continue;
      final lower = entity.readAsStringSync().toLowerCase();
      if (lower.contains('ai-stylist') || lower.contains('functions/v1/ai')) {
        offenders.add(entity.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'only $clientPath may reference ai-stylist: $offenders',
    );

    final client = File(clientPath);
    expect(client.existsSync(), isTrue, reason: '$clientPath must exist');
    expect(
      client.readAsStringSync().toLowerCase(),
      contains('functions/v1/ai-stylist'),
    );
  });
}
