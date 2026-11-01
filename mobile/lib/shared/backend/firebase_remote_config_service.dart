import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../models/app_config.dart';
import 'remote_config_service.dart';

/// [RemoteConfigService] backed by Firebase Remote Config (F25 §2.2).
/// Constructed only in `lib/main.dart`.
class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService(this._remoteConfig, {this._debug = kDebugMode});

  final FirebaseRemoteConfig _remoteConfig;
  final bool _debug;

  static const fetchTimeout = Duration(seconds: 10);
  static const debugMinimumFetchInterval = Duration(minutes: 5);
  static const releaseMinimumFetchInterval = Duration(hours: 1);

  @override
  Future<AppConfig> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: fetchTimeout,
          minimumFetchInterval: _debug
              ? debugMinimumFetchInterval
              : releaseMinimumFetchInterval,
        ),
      );
      await _remoteConfig.setDefaults(AppConfig.defaults.toDefaultsMap());
      return _read();
    } catch (error) {
      _log('initialize failed', error);
      return AppConfig.defaults;
    }
  }

  @override
  Future<AppConfig?> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      return _read();
    } catch (error) {
      _log('refresh failed', error);
      return null;
    }
  }

  AppConfig _read() => AppConfig(
    minSupportedVersion: _remoteConfig.getString(
      RemoteConfigKeys.minSupportedVersion,
    ),
    latestVersion: _remoteConfig.getString(RemoteConfigKeys.latestVersion),
    aiStylistEnabled: _remoteConfig.getBool(RemoteConfigKeys.aiStylistEnabled),
    premiumEnabled: _remoteConfig.getBool(RemoteConfigKeys.premiumEnabled),
    maintenanceMessage: _remoteConfig.getString(
      RemoteConfigKeys.maintenanceMessage,
    ),
  );

  static void _log(String message, Object error) {
    if (kDebugMode) debugPrint('FirebaseRemoteConfigService: $message: $error');
  }
}
