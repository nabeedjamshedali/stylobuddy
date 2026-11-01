import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/app_config/cubit/app_config_cubit.dart';
import 'package:stylobuddy/features/app_config/cubit/app_config_state.dart';
import 'package:stylobuddy/shared/backend/remote_config_service.dart';
import 'package:stylobuddy/shared/models/app_config.dart';

import '../../support/fake_remote_config.dart';

AppConfigState _state({
  String? installed,
  String min = '',
  String latest = '',
  String message = '',
}) => AppConfigState(
  installedVersion: installed,
  config: AppConfig.defaults.copyWith(
    minSupportedVersion: min,
    latestVersion: latest,
    maintenanceMessage: message,
  ),
);

void main() {
  test(
    'F25_A19 load emits the activated (cached) config first, then the fetched config',
    () async {
      final remote = FakeRemoteConfig(
        initial: AppConfig.defaults.copyWith(minSupportedVersion: '1.5.0'),
        fetched: AppConfig.defaults.copyWith(minSupportedVersion: '2.0.0'),
      );
      final cubit = AppConfigCubit(
        remoteConfig: remote,
        installedVersion: () async => '1.0.0',
      );
      addTearDown(cubit.close);

      expect(cubit.state.config, AppConfig.defaults);
      expect(cubit.state.installedVersion, isNull);
      expect(cubit.state.loaded, isFalse);
      expect(cubit.state.updateRequired, isFalse);

      final emitted = <AppConfigState>[];
      final sub = cubit.stream.listen(emitted.add);
      await cubit.load();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, hasLength(2));
      expect(emitted[0].config.minSupportedVersion, '1.5.0');
      expect(emitted[0].installedVersion, '1.0.0');
      expect(emitted[0].loaded, isFalse);
      expect(emitted[0].updateRequired, isTrue);
      expect(emitted[1].config.minSupportedVersion, '2.0.0');
      expect(emitted[1].installedVersion, '1.0.0');
      expect(emitted[1].loaded, isTrue);
      expect(emitted[1].updateRequired, isTrue);
    },
  );

  test('F25_A20 a null or failing refresh keeps the initialize() config', () async {
    final initial = AppConfig.defaults.copyWith(maintenanceMessage: 'cached');
    for (final remote in [
      FakeRemoteConfig(initial: initial),
      FakeRemoteConfig(initial: initial, refreshThrows: true),
    ]) {
      final cubit = AppConfigCubit(remoteConfig: remote);
      await cubit.load();
      expect(cubit.state.config, initial);
      expect(cubit.state.loaded, isTrue);
      await cubit.close();
    }
  });

  test('F25_A21 a refresh that never completes is cut off by fetchTimeout', () async {
    final initial = AppConfig.defaults.copyWith(latestVersion: '3.0.0');
    final cubit = AppConfigCubit(
      remoteConfig: FakeRemoteConfig(
        initial: initial,
        refreshNeverCompletes: true,
      ),
      fetchTimeout: const Duration(milliseconds: 50),
    );
    addTearDown(cubit.close);
    final watch = Stopwatch()..start();
    await cubit.load();
    watch.stop();
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(cubit.state.config, initial);
    expect(cubit.state.loaded, isTrue);
    expect(AppConfigCubit.fetchTimeout, const Duration(seconds: 8));
  });

  test('F25_A22 load runs once, whether called concurrently or again later', () async {
    final remote = FakeRemoteConfig();
    final cubit = AppConfigCubit(remoteConfig: remote);
    addTearDown(cubit.close);
    await Future.wait([cubit.load(), cubit.load()]);
    await cubit.load();
    expect(remote.initializeCalls, 1);
    expect(remote.refreshCalls, 1);
  });

  test('F25_A23 an unreadable installed version never gates or nudges', () async {
    final remote = FakeRemoteConfig(
      initial: AppConfig.defaults.copyWith(
        minSupportedVersion: '99.0.0',
        latestVersion: '99.0.0',
      ),
    );
    for (final reader in <Future<String?> Function()>[
      () async => null,
      () async => throw Exception('no platform'),
    ]) {
      final cubit = AppConfigCubit(remoteConfig: remote, installedVersion: reader);
      await cubit.load();
      expect(cubit.state.installedVersion, isNull);
      expect(cubit.state.updateRequired, isFalse);
      expect(cubit.state.updateAvailable, isFalse);
      await cubit.close();
    }
  });

  test('F25_A24 updateRequired truth table (fail-open)', () {
    expect(_state(installed: '1.2.9', min: '1.2.10').updateRequired, isTrue);
    expect(_state(installed: '1.2.9', min: '1.2.9').updateRequired, isFalse);
    expect(_state(installed: '1.2.9', min: '1.2.8').updateRequired, isFalse);
    expect(_state(installed: '1.2.9', min: '').updateRequired, isFalse);
    expect(_state(installed: '1.2.9', min: '1.x').updateRequired, isFalse);
    expect(_state(installed: '1.2.9', min: 'latest').updateRequired, isFalse);
    expect(_state(installed: '1.2.10', min: '1.2.9').updateRequired, isFalse);
  });

  test('F25_A25 updateAvailable truth table; a forced update never also nudges', () {
    expect(_state(installed: '1.0.1', latest: '1.0.3').updateAvailable, isTrue);
    expect(_state(installed: '1.0.1', latest: '1.0.1').updateAvailable, isFalse);
    expect(_state(installed: '1.0.1', latest: '1.0.0').updateAvailable, isFalse);
    expect(_state(installed: '1.0.1', latest: '').updateAvailable, isFalse);
    expect(_state(installed: '1.0.1', latest: 'x').updateAvailable, isFalse);
    final both = _state(installed: '1.0.1', latest: '1.0.3', min: '1.0.2');
    expect(both.updateRequired, isTrue);
    expect(both.updateAvailable, isFalse);
    expect(both.showUpdateNudge, isFalse);
  });

  test('F25_A26 dismiss methods hide only their own notice', () async {
    final cubit = AppConfigCubit(
      remoteConfig: FakeRemoteConfig(
        initial: AppConfig.defaults.copyWith(
          latestVersion: '2.0.0',
          maintenanceMessage: 'Back at 9',
        ),
      ),
      installedVersion: () async => '1.0.0',
    );
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.showUpdateNudge, isTrue);
    expect(cubit.state.showMaintenance, isTrue);

    cubit.dismissUpdateNudge();
    expect(cubit.state.showUpdateNudge, isFalse);
    expect(cubit.state.showMaintenance, isTrue);
    expect(cubit.state.updateAvailable, isTrue);
    expect(cubit.state.updateRequired, isFalse);

    cubit.dismissMaintenance();
    expect(cubit.state.showMaintenance, isFalse);
    expect(cubit.state.maintenanceMessage, 'Back at 9');
    expect(cubit.state.updateRequired, isFalse);

    final gated = _state(installed: '1.0.0', min: '2.0.0')
        .copyWith(updateNudgeDismissed: true, maintenanceDismissed: true);
    expect(gated.updateRequired, isTrue);
  });

  test('F25_A27 maintenance message: blank is missing, text is trimmed', () {
    expect(_state(message: '').maintenanceMessage, isNull);
    expect(_state(message: '   \n ').maintenanceMessage, isNull);
    expect(_state(message: '   \n ').showMaintenance, isFalse);
    expect(_state(message: '  Back at 9  ').maintenanceMessage, 'Back at 9');
    expect(_state(message: '  Back at 9  ').showMaintenance, isTrue);
  });

  test('F25_A28 openStore records whether the store opened; a throw counts as failure', () async {
    for (final (launcher, expectedFailed) in <(Future<bool> Function(), bool)>[
      (() async => true, false),
      (() async => false, true),
      (() async => throw Exception('no activity'), true),
    ]) {
      var calls = 0;
      final cubit = AppConfigCubit(
        remoteConfig: const DefaultsRemoteConfigService(),
        openStore: () {
          calls++;
          return launcher();
        },
      );
      await cubit.openStore();
      expect(calls, 1);
      expect(cubit.state.storeLaunchFailed, expectedFailed);
      await cubit.close();
    }
  });
}
