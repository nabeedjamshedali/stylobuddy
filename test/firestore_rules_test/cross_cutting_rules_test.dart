@Tags(['firestore-rules'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/rules_test_client.dart';

const _alice = 'alice';

String _join(String a, String b) => '$a${Platform.pathSeparator}$b';

String _repoRoot() {
  var dir = Directory.current;
  while (!File(_join(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir.path;
}

void main() {
  late RulesTestClient client;

  setUp(() async {
    client = RulesTestClient();
    await client.clearData();
  });

  group('F22 cross-cutting', () {
    test('F22_A01 no test file references the production project id', () {
      // Built by concatenation, deliberately, so the production project id
      // itself never appears as a literal substring anywhere under
      // test/firestore_rules_test/ (including this file).
      final productionProjectId = ['stylobuddy', 'b7e46'].join('-');
      final dir = Directory(_join(_join(_repoRoot(), 'test'), 'firestore_rules_test'));
      final offenders = <String>[];
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains(productionProjectId)) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty, reason: 'Production project id referenced in: $offenders');
    });

    test('F22_A04 recursive wildcard is gone', () async {
      final unknownCollection = await client.commit(
        [client.fullSet('users/$_alice/unknownCollection/x', {'a': 1})],
        token: mockIdToken(_alice),
      );
      expect(unknownCollection.isPermissionDenied, isTrue, reason: unknownCollection.body.toString());

      final seedWardrobe = await client.commit(
        [
          client.fullSet('users/$_alice/wardrobeItems/x', {
            'id': 'x',
            'name': 'x',
            'category': 'x',
            'color': 'x',
            'occasion': 'x',
            'season': 'x',
            'wears': 0,
            'sourceId': null,
            'imageUrl': null,
          }),
        ],
        token: ownerToken,
      );
      expect(seedWardrobe.ok, isTrue);
      final nested = await client.commit(
        [client.fullSet('users/$_alice/wardrobeItems/x/nested/y', {'a': 1})],
        token: mockIdToken(_alice),
      );
      expect(nested.isPermissionDenied, isTrue, reason: nested.body.toString());

      final topLevel = await client.commit(
        [client.fullSet('other/x', {'a': 1})],
        token: mockIdToken(_alice),
      );
      expect(topLevel.isPermissionDenied, isTrue, reason: topLevel.body.toString());
    });

    test('F22_A05 owner get of own profile succeeds, list on users collection denied', () async {
      final seed = await client.commit(
        [client.fullSet('users/$_alice', {'name': 'Alice'})],
        token: ownerToken,
      );
      expect(seed.ok, isTrue);

      final get = await client.get('users/$_alice', token: mockIdToken(_alice));
      expect(get.ok, isTrue, reason: get.body.toString());

      final list = await client.list('users', token: mockIdToken(_alice));
      expect(list.isPermissionDenied, isTrue, reason: list.body.toString());

      // Distinguishes `get` from `read`/`list`: a `runQuery` constrained by
      // `__name__` to alice's own doc is still a list/runQuery operation in
      // the rules engine's eyes, not a get, so `allow get` must deny it even
      // though the unconstrained `list` above is denied for a different
      // reason (no list grant at all) and even though the query result
      // would only ever have contained alice's own data.
      final constrained = await client.runQueryByName('users', 'users/$_alice', token: mockIdToken(_alice));
      expect(constrained.isPermissionDenied, isTrue, reason: constrained.body.toString());
    });

    test('F22_A06 no get()/exists() in firestore.rules', () {
      final rules = File(_join(_repoRoot(), 'firestore.rules')).readAsStringSync();
      for (final forbidden in ['get(', 'exists(', 'getAfter(', 'existsAfter(']) {
        expect(rules.contains(forbidden), isFalse, reason: 'firestore.rules uses $forbidden');
      }
    });

    test('F22_A49 no orderBy/where/limit/collectionGroup on a Firestore ref; indexes unchanged', () {
      final libDir = Directory(_join(_repoRoot(), 'lib'));
      final offenders = <String>[];
      // `.where(` alone is ambiguous with `Iterable.where` (used all over
      // the app's own in-memory filtering, e.g. `PackingRepository`'s
      // `items.where((i) => ...)`). Rather than hard-coding the small set of
      // Firestore collection/query reference fields this codebase happens to
      // have today (which would silently miss a `.where(...)` on a new
      // Firestore query added against a different reference), flag any
      // `.where(` call whose first argument is a Firestore query-filter
      // constructor shape: a string/FieldPath field-name literal followed by
      // a comma (`Query.where(field, isEqualTo: ...)` etc.) or a bare
      // `FieldPath` argument. `Iterable.where((x) => ...)` always passes a
      // closure as its sole argument and never matches either shape.
      final whereCall = RegExp(r'''\.where\(\s*(?:['"]|FieldPath)''');
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        for (final forbidden in ['.orderBy(', '.limit(', '.collectionGroup(']) {
          if (content.contains(forbidden)) offenders.add('${entity.path}: $forbidden');
        }
        if (whereCall.hasMatch(content)) {
          offenders.add('${entity.path}: .where( on a field-name/FieldPath literal');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));

      // A49 says "byte-identical" — compare the raw file text, not a
      // round-tripped JSON decode (which would mask a formatting/whitespace
      // change that still counts as a modification to the committed file).
      final indexesPath = File(_join(_repoRoot(), 'firestore.indexes.json'));
      final indexesText = indexesPath.readAsStringSync();
      const expectedIndexesText = '{\n  "indexes": [],\n  "fieldOverrides": []\n}\n';
      expect(
        indexesText,
        expectedIndexesText,
        reason:
            'firestore.indexes.json changed byte-for-byte from the expected '
            'unchanged content (F22_A49 requires it stay untouched)',
      );
    });
  });
}
