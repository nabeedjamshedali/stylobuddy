/// Which preference list `ProfileCubit.togglePreference` edits.
enum PreferenceField { styles, occasions }

/// Defaults mirror the prototype (`S.profileName`, `S.styleChoices`, ...).
class ProfileState {
  const ProfileState({
    this.name = 'Alex Morgan',
    this.email = 'alex@example.com',
    this.styles = const ['Minimal', 'Smart casual'],
    this.occasions = const ['Everyday', 'Office'],
    this.dailyNotifications = true,
    this.plannedNotifications = true,
    this.productNotifications = false,
    this.weatherConsent = true,
    this.climate = 'Mild',
    this.plan = 'Free',
    this.billingCycle = 'yearly',
    this.gender,
  });

  final String name;
  final String email;
  final List<String> styles;
  final List<String> occasions;
  final bool dailyNotifications;
  final bool plannedNotifications;
  final bool productNotifications;
  final bool weatherConsent;
  final String climate;
  final String plan;
  final String billingCycle;

  /// F24: `'male'` / `'female'` chosen on onboarding `/gender`, or `null`
  /// (never chosen: guest, skipped intro, or pre-F24 user). Written only by
  /// the D5 bootstrap seed; no setter.
  final String? gender;

  /// Prototype `S.profileStyle`: `Minimal • Smart casual`.
  String get styleSummary => styles.join(' • ');

  ProfileState copyWith({
    String? name,
    String? email,
    List<String>? styles,
    List<String>? occasions,
    bool? dailyNotifications,
    bool? plannedNotifications,
    bool? productNotifications,
    bool? weatherConsent,
    String? climate,
    String? plan,
    String? billingCycle,
    String? gender,
  }) => ProfileState(
    name: name ?? this.name,
    email: email ?? this.email,
    styles: styles ?? this.styles,
    occasions: occasions ?? this.occasions,
    dailyNotifications: dailyNotifications ?? this.dailyNotifications,
    plannedNotifications: plannedNotifications ?? this.plannedNotifications,
    productNotifications: productNotifications ?? this.productNotifications,
    weatherConsent: weatherConsent ?? this.weatherConsent,
    climate: climate ?? this.climate,
    plan: plan ?? this.plan,
    billingCycle: billingCycle ?? this.billingCycle,
    gender: gender ?? this.gender,
  );
}
