import 'dart:convert';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylobuddy/shared/backend/firebase_remote_config_service.dart';
import 'package:stylobuddy/shared/backend/remote_config_service.dart';
import 'package:stylobuddy/shared/models/app_config.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

void _stubValues(
  _MockRemoteConfig rc, {
  String min = '',
  String latest = '',
  bool ai = false,
  bool premium = false,
  String message = '',
}) {
  when(() => rc.getString('min_supported_version')).thenReturn(min);
  when(() => rc.getString('latest_version')).thenReturn(latest);
  when(() => rc.getBool('ai_stylist_enabled')).thenReturn(ai);
  when(() => rc.getBool('premium_enabled')).thenReturn(premium);
  when(() => rc.getString('maintenance_message')).thenReturn(message);
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: Duration.zero,
        minimumFetchInterval: Duration.zero,
      ),
    );
  });

  test('F25_A12 keys and in-app defaults are exact', () {
    expect(RemoteConfigKeys.all, {
      'min_supported_version',
      'latest_version',
      'ai_stylist_enabled',
      'premium_enabled',
      'maintenance_message',
    });
    const d = AppConfig.defaults;
    expect(d.minSupportedVersion, '');
    expect(d.latestVersion, '');
    expect(d.aiStylistEnabled, isFalse);
    expect(d.premiumEnabled, isFalse);
    expect(d.maintenanceMessage, '');
    expect(d.toDefaultsMap(), {
      'min_supported_version': '',
      'latest_version': '',
      'ai_stylist_enabled': false,
      'premium_enabled': false,
      'maintenance_message': '',
    });
  });

  test(
    'F25_A12 scripts/remoteconfig.template.json carries exactly the five keys with the in-app defaults and no conditions',
    () {
      final template =
          jsonDecode(File('scripts/remoteconfig.template.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(template['conditions'], isEmpty);
      final parameters = template['parameters'] as Map<String, dynamic>;
      expect(parameters.keys.toSet(), RemoteConfigKeys.all);
      final defaults = AppConfig.defaults.toDefaultsMap();
      for (final key in RemoteConfigKeys.all) {
        final p = parameters[key] as Map<String, dynamic>;
        final value = (p['defaultValue'] as Map<String, dynamic>)['value'];
        expect(value, defaults[key].toString(), reason: key);
        expect(p['valueType'], defaults[key] is bool ? 'BOOLEAN' : 'STRING');
        expect((p['description'] as String).isNotEmpty, isTrue);
        expect(p.containsKey('conditionalValues'), isFalse);
      }
    },
  );

  test('F25_A13 AppConfig has value semantics and copyWith changes one field', () {
    const a = AppConfig(
      minSupportedVersion: '1.0.0',
      latestVersion: '1.1.0',
      aiStylistEnabled: true,
      premiumEnabled: false,
      maintenanceMessage: 'm',
    );
    const b = AppConfig(
      minSupportedVersion: '1.0.0',
      latestVersion: '1.1.0',
      aiStylistEnabled: true,
      premiumEnabled: false,
      maintenanceMessage: 'm',
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    final c = a.copyWith(maintenanceMessage: 'x');
    expect(c.maintenanceMessage, 'x');
    expect(c.minSupportedVersion, a.minSupportedVersion);
    expect(c.latestVersion, a.latestVersion);
    expect(c.aiStylistEnabled, a.aiStylistEnabled);
    expect(c.premiumEnabled, a.premiumEnabled);
    expect(c == a, isFalse);
  });

  group('FirebaseRemoteConfigService', () {
    late _MockRemoteConfig rc;

    setUp(() {
      rc = _MockRemoteConfig();
      when(() => rc.setConfigSettings(any())).thenAnswer((_) async {});
      when(() => rc.setDefaults(any())).thenAnswer((_) async {});
      _stubValues(rc);
    });

    test(
      'F25_A14 initialize applies 10 s timeout, 5 min debug / 1 h release interval and the defaults, then reads typed values',
      () async {
        _stubValues(rc, min: '1.1.0', latest: '1.2.0', ai: true, message: 'hi');
        final order = <String>[];
        RemoteConfigSettings? settings;
        Map<String, dynamic>? defaults;
        when(() => rc.setConfigSettings(any())).thenAnswer((invocation) async {
          order.add('settings');
          settings = invocation.positionalArguments.single as RemoteConfigSettings;
        });
        when(() => rc.setDefaults(any())).thenAnswer((invocation) async {
          order.add('defaults');
          defaults = invocation.positionalArguments.single as Map<String, dynamic>;
        });
        final config = await FirebaseRemoteConfigService(rc, debug: true).initialize();

        expect(order, ['settings', 'defaults']);
        expect(settings!.fetchTimeout, const Duration(seconds: 10));
        expect(settings!.minimumFetchInterval, const Duration(minutes: 5));
        expect(defaults, AppConfig.defaults.toDefaultsMap());
        expect(
          config,
          const AppConfig(
            minSupportedVersion: '1.1.0',
            latestVersion: '1.2.0',
            aiStylistEnabled: true,
            premiumEnabled: false,
            maintenanceMessage: 'hi',
          ),
        );

        final release = _MockRemoteConfig();
        when(() => release.setConfigSettings(any())).thenAnswer((_) async {});
        when(() => release.setDefaults(any())).thenAnswer((_) async {});
        _stubValues(release);
        await FirebaseRemoteConfigService(release, debug: false).initialize();
        final releaseSettings =
            verify(() => release.setConfigSettings(captureAny())).captured.single
                as RemoteConfigSettings;
        expect(releaseSettings.minimumFetchInterval, const Duration(hours: 1));
      },
    );

    test('F25_A15 initialize falls back to defaults when settings or defaults throw', () async {
      when(() => rc.setConfigSettings(any())).thenThrow(Exception('channel'));
      expect(
        await FirebaseRemoteConfigService(rc).initialize(),
        AppConfig.defaults,
      );

      final rc2 = _MockRemoteConfig();
      when(() => rc2.setConfigSettings(any())).thenAnswer((_) async {});
      when(() => rc2.setDefaults(any())).thenThrow(Exception('channel'));
      _stubValues(rc2, min: '9.9.9');
      expect(
        await FirebaseRemoteConfigService(rc2).initialize(),
        AppConfig.defaults,
      );
    });

    test('F25_A16 refresh returns typed values after fetchAndActivate, null when it throws', () async {
      when(() => rc.fetchAndActivate()).thenAnswer((_) async => true);
      _stubValues(rc, min: '1.2.0', ai: true, message: 'Down at 9');
      final fetched = await FirebaseRemoteConfigService(rc).refresh();
      expect(fetched?.minSupportedVersion, '1.2.0');
      expect(fetched?.aiStylistEnabled, isTrue);
      expect(fetched?.premiumEnabled, isFalse);
      expect(fetched?.maintenanceMessage, 'Down at 9');

      // A non-boolean server string is whatever the SDK's getBool yields
      // (false for 'maybe'); the service passes it through untouched.
      when(() => rc.getBool('premium_enabled')).thenReturn(false);
      expect(
        (await FirebaseRemoteConfigService(rc).refresh())?.premiumEnabled,
        isFalse,
      );

      when(() => rc.fetchAndActivate()).thenThrow(Exception('offline'));
      expect(await FirebaseRemoteConfigService(rc).refresh(), isNull);
    });
  });

  test('F25_A17 DefaultsRemoteConfigService returns defaults and never fetches', () async {
    const service = DefaultsRemoteConfigService();
    expect(await service.initialize(), AppConfig.defaults);
    expect(await service.refresh(), isNull);
  });
}
