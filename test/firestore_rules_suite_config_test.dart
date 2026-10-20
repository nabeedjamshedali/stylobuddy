// Part of the DEFAULT `flutter test` run (no tag, no emulator needed):
// proves F22_A03 — the emulator-backed suite under test/firestore_rules_test
// is wired to be excluded by default, not just "happens not to run" by
// accident.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('F22_A03 dart_test.yaml excludes the firestore-rules tag by default '
      'and points at the one script that bundles run-skipped+concurrency', () {
    final config = File('dart_test.yaml').readAsStringSync();
    expect(config.contains('firestore-rules'), isTrue);
    expect(config.contains('skip:'), isTrue);
    expect(config.contains('scripts/run_firestore_rules_suite.sh'), isTrue);
  });

  test('F22_A03 the documented suite script passes --run-skipped and --concurrency=1 together', () {
    final script = File('scripts/run_firestore_rules_suite.sh').readAsStringSync();
    // Matches only the real `flutter test` command line, not the script's
    // own comment block above it (which also mentions both flag names) —
    // a dropped flag on the real line must fail this test.
    final commandLine = script
        .split('\n')
        .firstWhere((line) => line.trim().startsWith('"flutter test'));
    expect(commandLine.contains('--run-skipped'), isTrue);
    expect(commandLine.contains('--concurrency=1'), isTrue);
  });

  test('F22_A03 every file under test/firestore_rules_test/ carries the firestore-rules tag', () {
    final dir = Directory('test/firestore_rules_test');
    final untagged = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('_test.dart')) continue;
      final content = entity.readAsStringSync();
      if (!content.contains("@Tags(['firestore-rules'])")) {
        untagged.add(entity.path);
      }
    }
    expect(untagged, isEmpty, reason: 'Missing @Tags([\'firestore-rules\']) in: $untagged');
  });
}
