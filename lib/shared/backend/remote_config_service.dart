import '../models/app_config.dart';

/// Reads typed [AppConfig] from Remote Config (F25 §2.2). SDK-free so the
/// `app_config` Cubit and every test can use it without Firebase.
abstract interface class RemoteConfigService {
  /// Applies fetch settings and the in-app defaults, then returns the
  /// currently activated values: [AppConfig.defaults] on a first install,
  /// the last fetched values afterwards. Never throws; on any error returns
  /// [AppConfig.defaults].
  Future<AppConfig> initialize();

  /// Fetches and activates, returning the newly activated values, or `null`
  /// when the fetch fails. Never throws.
  Future<AppConfig?> refresh();
}

/// Always the in-app defaults, never fetches. `StyloBuddyApp`'s default and
/// the test double.
class DefaultsRemoteConfigService implements RemoteConfigService {
  const DefaultsRemoteConfigService();

  @override
  Future<AppConfig> initialize() async => AppConfig.defaults;

  @override
  Future<AppConfig?> refresh() async => null;
}
