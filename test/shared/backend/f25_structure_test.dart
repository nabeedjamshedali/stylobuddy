import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F25-A09: Firebase Analytics / Remote Config and the two platform
/// packages stay behind their adapters; nothing sets a user id or property.
void main() {
  List<File> dartFiles(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String norm(String path) => path.replaceAll('\\', '/');

  test(
    'F25_A09 SDK imports are confined to their adapters and no user id/property is ever set',
    () {
      expect(Directory('lib').existsSync(), isTrue, reason: 'run from repo root');
      const allowed = {
        'package:firebase_analytics/': {
          'lib/shared/backend/firebase_analytics_sink.dart',
          'lib/main.dart',
        },
        'package:firebase_remote_config/': {
          'lib/shared/backend/firebase_remote_config_service.dart',
          'lib/main.dart',
        },
        'package:url_launcher/': {'lib/shared/backend/app_platform.dart'},
        'package:package_info_plus/': {'lib/shared/backend/app_platform.dart'},
      };
      final offenders = <String>[];
      final uiImports = <String>[];
      final identityCalls = <String>[];
      final uiPath = RegExp(r'^lib/(features/[^/]+/(view|widgets)|shared/widgets)/');
      for (final file in dartFiles('lib')) {
        final path = norm(file.path);
        final source = file.readAsStringSync();
        for (final entry in allowed.entries) {
          final imports = RegExp(
            "^\\s*import\\s+'${RegExp.escape(entry.key)}",
            multiLine: true,
          ).hasMatch(source);
          if (!imports) continue;
          if (!entry.value.contains(path)) offenders.add('$path -> ${entry.key}');
          if (uiPath.hasMatch(path)) uiImports.add('$path -> ${entry.key}');
        }
        for (final call in [
          'setUserId(',
          'setUserProperty(',
          'setDefaultEventParameters(',
        ]) {
          if (source.contains(call)) identityCalls.add('$path: $call');
        }
      }
      expect(offenders, isEmpty);
      expect(uiImports, isEmpty);
      expect(identityCalls, isEmpty);
    },
  );

  test(
    'F25_A09 app_config views and widgets import no backend file and no repository',
    () {
      final offenders = <String>[];
      for (final dir in [
        'lib/features/app_config/view',
        'lib/features/app_config/widgets',
      ]) {
        for (final file in dartFiles(dir)) {
          final source = file.readAsStringSync();
          if (source.contains('shared/backend/') ||
              source.contains('/repository/') ||
              source.contains("package:firebase_")) {
            offenders.add(norm(file.path));
          }
        }
      }
      expect(offenders, isEmpty);
    },
  );

  test(
    'F25 manifest turns off automatic Activity screen reporting (section 2.1)',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        RegExp(
          r'android:name="google_analytics_automatic_screen_reporting_enabled"\s+android:value="false"',
        ).hasMatch(manifest),
        isTrue,
      );
    },
  );
}
