/// Firebase Remote Config parameter keys (F25 §2.2). The published template
/// (`scripts/remoteconfig.template.json`) must carry exactly these.
abstract final class RemoteConfigKeys {
  static const minSupportedVersion = 'min_supported_version';
  static const latestVersion = 'latest_version';
  static const aiStylistEnabled = 'ai_stylist_enabled';
  static const premiumEnabled = 'premium_enabled';
  static const maintenanceMessage = 'maintenance_message';

  static const all = <String>{
    minSupportedVersion,
    latestVersion,
    aiStylistEnabled,
    premiumEnabled,
    maintenanceMessage,
  };
}

/// Typed, read-only client configuration from Remote Config
/// (`docs/foundation/03-domain-model.md`, F25). Never user data, never
/// written to Firestore.
class AppConfig {
  const AppConfig({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.aiStylistEnabled,
    required this.premiumEnabled,
    required this.maintenanceMessage,
  });

  /// In-app defaults: no version floor, no nudge, both flags off, no notice.
  static const defaults = AppConfig(
    minSupportedVersion: '',
    latestVersion: '',
    aiStylistEnabled: false,
    premiumEnabled: false,
    maintenanceMessage: '',
  );

  /// Installed versions below this are blocked (`''` = no floor).
  final String minSupportedVersion;

  /// Installed versions below this see a dismissible nudge (`''` = none).
  final String latestVersion;

  /// Reserved for the LLM-provider feature; nothing reads it yet.
  final bool aiStylistEnabled;

  /// Reserved for the RevenueCat feature; nothing reads it yet.
  final bool premiumEnabled;

  /// Non-blank text shows a dismissible notice (`''` = none).
  final String maintenanceMessage;

  AppConfig copyWith({
    String? minSupportedVersion,
    String? latestVersion,
    bool? aiStylistEnabled,
    bool? premiumEnabled,
    String? maintenanceMessage,
  }) {
    return AppConfig(
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      aiStylistEnabled: aiStylistEnabled ?? this.aiStylistEnabled,
      premiumEnabled: premiumEnabled ?? this.premiumEnabled,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
    );
  }

  /// The map handed to `FirebaseRemoteConfig.setDefaults`.
  Map<String, Object> toDefaultsMap() => {
    RemoteConfigKeys.minSupportedVersion: minSupportedVersion,
    RemoteConfigKeys.latestVersion: latestVersion,
    RemoteConfigKeys.aiStylistEnabled: aiStylistEnabled,
    RemoteConfigKeys.premiumEnabled: premiumEnabled,
    RemoteConfigKeys.maintenanceMessage: maintenanceMessage,
  };

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.minSupportedVersion == minSupportedVersion &&
      other.latestVersion == latestVersion &&
      other.aiStylistEnabled == aiStylistEnabled &&
      other.premiumEnabled == premiumEnabled &&
      other.maintenanceMessage == maintenanceMessage;

  @override
  int get hashCode => Object.hash(
    minSupportedVersion,
    latestVersion,
    aiStylistEnabled,
    premiumEnabled,
    maintenanceMessage,
  );

  @override
  String toString() =>
      'AppConfig(min: $minSupportedVersion, latest: $latestVersion, '
      'ai: $aiStylistEnabled, premium: $premiumEnabled, '
      'maintenance: "$maintenanceMessage")';
}
