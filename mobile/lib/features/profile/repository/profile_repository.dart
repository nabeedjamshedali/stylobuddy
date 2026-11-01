import '../cubit/profile_state.dart';

/// Dual-mode repository (architecture D2, D6): the method surface
/// `ProfileCubit` already called directly on its own state before this
/// task, one method per setter. `togglePreference` stays a pure
/// Cubit-local computation of the *next* list (unchanged), then calls
/// [setStyles]/[setOccasions] with that already-computed list — so every
/// write method here is always a plain overwrite of a value the Cubit
/// already fully computed, never a repository-side read-modify-write
/// (F18 doc §6; distinct from F16's `logWear`/`removeWear`). No method on
/// this interface ever needs `runTransaction`.
abstract class ProfileRepository {
  Stream<ProfileState> watchProfile();
  Future<void> updateDetails(String name, String email);
  Future<void> setStyles(List<String> styles);
  Future<void> setOccasions(List<String> occasions);
  Future<void> setDailyNotifications(bool v);
  Future<void> setPlannedNotifications(bool v);
  Future<void> setProductNotifications(bool v);
  Future<void> setWeatherConsent(bool v);
  Future<void> setClimate(String v);
  Future<void> setPlan(String v);
  Future<void> setBillingCycle(String v);
}
