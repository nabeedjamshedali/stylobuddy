import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F14-A14: existing Cubit-level tests construct a Cubit directly
/// (bypassing `app.dart`'s `StreamBuilder`), so they must never trigger a
/// FirebaseAuth or Firestore call. This is a structural check, not a
/// behavioral one: no `lib/features/*/cubit/*.dart` file imports
/// `auth_session.dart` or `firestore_service.dart` (directly — grep is a
/// reasonable proxy for "transitively" here since neither file has any
/// other export surface a cubit file could reach it through).
void main() {
  test(
    'F14_A14 no lib/features/*/cubit file imports shared/backend',
    () {
      final cubitDir = Directory('lib/features');
      expect(cubitDir.existsSync(), isTrue, reason: 'run from repo root');

      final offenders = <String>[];
      for (final entity in cubitDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.replaceAll('\\', '/').contains('/cubit/')) continue;
        if (!entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        if (content.contains('shared/backend/auth_session.dart') ||
            content.contains('shared/backend/firestore_service.dart')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'cubit files must not import shared/backend: $offenders',
      );
    },
  );
}
