import 'package:flutter/foundation.dart' show visibleForTesting;

/// App-lifetime-scoped holder (F18 Task 5, controller ruling — binding):
/// a plain class with static get/set/clear, deliberately NOT a widget/view
/// file, NOT a new DI framework, NOT Provider/Riverpod/GetX.
///
/// `OnboardingCubit.toggleOccasion`/`toggleChip` write into this holder on
/// every toggle (mirroring `OnboardingState`'s own toggle semantics
/// exactly — last-state-wins, no history) because at the moment onboarding
/// finishes the user is still a guest (`uid == null`): `OnboardingState`
/// itself is scoped to the onboarding `ShellRoute` and is torn down the
/// moment navigation leaves it for `/auth`'s separate `ShellRoute`, so it
/// never survives to the point sign-in succeeds. This holder lives outside
/// both shells' widget subtrees, so it survives that teardown.
///
/// `lib/app.dart`'s uid-keyed builder calls [consume] exactly once when
/// constructing the signed-in `ProfileCubit`/`FirestoreProfileRepository`
/// for a (possibly brand-new) uid, folding the result into that uid's D5
/// bootstrap seed write. [consume] always clears the holder so a later,
/// unrelated sign-up in the same app process never sees a stale value
/// (edge case in F18 doc §12) — never persisted to disk, so a full app
/// kill/relaunch starts it empty again too.
class PendingOnboardingSelections {
  PendingOnboardingSelections._();

  static Set<String> _chosenOccasions = const {};
  static Set<String> _chosenChips = const {};

  /// Called by [OnboardingCubit.toggleOccasion] with the full, current
  /// `chosenOccasions` set on every toggle.
  static void setChosenOccasions(Set<String> value) {
    _chosenOccasions = value;
  }

  /// Called by [OnboardingCubit.toggleChip] with the full, current
  /// `chosenChips` set on every toggle.
  static void setChosenChips(Set<String> value) {
    _chosenChips = value;
  }

  /// Returns the union of `chosenOccasions`/`chosenChips` (duplicates
  /// collapsed, F18 doc §13's accepted union ruling) accumulated so far,
  /// then clears the holder. Safe to call even when nothing was ever
  /// toggled (returns an empty set).
  static Set<String> consume() {
    final union = {..._chosenOccasions, ..._chosenChips};
    clear();
    return union;
  }

  /// Resets the holder without reading it — used by tests, and available
  /// for a future caller that needs to discard a stale in-flight
  /// onboarding attempt without forwarding it.
  static void clear() {
    _chosenOccasions = const {};
    _chosenChips = const {};
  }

  @visibleForTesting
  static Set<String> get chosenOccasionsForTest => _chosenOccasions;

  @visibleForTesting
  static Set<String> get chosenChipsForTest => _chosenChips;
}
