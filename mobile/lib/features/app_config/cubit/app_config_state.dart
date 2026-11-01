import '../../../shared/models/app_config.dart';
import '../models/app_version.dart';

/// Remote Config values plus what the app derives from them (F25 §2.3).
class AppConfigState {
  const AppConfigState({
    this.config = AppConfig.defaults,
    this.installedVersion,
    this.loaded = false,
    this.updateNudgeDismissed = false,
    this.maintenanceDismissed = false,
    this.storeLaunchFailed = false,
  });

  final AppConfig config;

  /// `versionName` of the running build; `null` until read or if unreadable.
  final String? installedVersion;

  /// `true` once the startup fetch finished (succeeded, failed or timed out).
  final bool loaded;

  final bool updateNudgeDismissed;
  final bool maintenanceDismissed;

  /// The last "Update now" / "Update" tap could not open the store.
  final bool storeLaunchFailed;

  AppVersion? get _installed {
    final raw = installedVersion;
    return raw == null ? null : AppVersion.tryParse(raw);
  }

  /// Installed < `min_supported_version`. Fail-open: an unreadable installed
  /// version or a missing/empty/unparseable floor never blocks.
  bool get updateRequired {
    final installed = _installed;
    final minimum = AppVersion.tryParse(config.minSupportedVersion);
    if (installed == null || minimum == null) return false;
    return installed < minimum;
  }

  /// Installed < `latest_version` and no forced update.
  bool get updateAvailable {
    if (updateRequired) return false;
    final installed = _installed;
    final latest = AppVersion.tryParse(config.latestVersion);
    if (installed == null || latest == null) return false;
    return installed < latest;
  }

  /// The trimmed `maintenance_message`, or `null` when blank.
  String? get maintenanceMessage {
    final text = config.maintenanceMessage.trim();
    return text.isEmpty ? null : text;
  }

  bool get showUpdateNudge => updateAvailable && !updateNudgeDismissed;

  bool get showMaintenance =>
      maintenanceMessage != null && !maintenanceDismissed;

  AppConfigState copyWith({
    AppConfig? config,
    String? installedVersion,
    bool? loaded,
    bool? updateNudgeDismissed,
    bool? maintenanceDismissed,
    bool? storeLaunchFailed,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      installedVersion: installedVersion ?? this.installedVersion,
      loaded: loaded ?? this.loaded,
      updateNudgeDismissed: updateNudgeDismissed ?? this.updateNudgeDismissed,
      maintenanceDismissed: maintenanceDismissed ?? this.maintenanceDismissed,
      storeLaunchFailed: storeLaunchFailed ?? this.storeLaunchFailed,
    );
  }
}
