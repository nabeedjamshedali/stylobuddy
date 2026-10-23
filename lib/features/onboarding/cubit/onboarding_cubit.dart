import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/backend/pending_onboarding_selections.dart';
import '../../../shared/models/genders.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  static const lastSlide = 4;

  /// Welcome "Get Started": always begins at slide 1. Keeps [OnboardingState.gender]
  /// so returning to `/gender` shows the earlier choice (F24).
  void start() => emit(state.copyWith(slide: 0, exit: OnboardingExit.none));

  /// Advances; from the last slide emits [OnboardingExit.finished].
  void next() {
    if (state.slide >= lastSlide) {
      emit(state.copyWith(exit: OnboardingExit.finished));
    } else {
      emit(state.copyWith(slide: state.slide + 1));
    }
  }

  /// Goes back one slide; on slide 0 emits [OnboardingExit.backToGender].
  void back() {
    if (state.slide <= 0) {
      emit(state.copyWith(exit: OnboardingExit.backToGender));
    } else {
      emit(state.copyWith(slide: state.slide - 1));
    }
  }

  /// Called once the view has navigated for an exit signal.
  void clearExit() => emit(state.copyWith(exit: OnboardingExit.none));

  /// `/gender` card tap (F24). Accepts only [Genders.values]; anything else
  /// throws [ArgumentError] and changes neither the state nor the holder.
  /// Forwards the choice to [PendingOnboardingSelections] for the same
  /// reason as [toggleOccasion]: the bootstrap seed needs it after sign-in.
  void setGender(String gender) {
    if (!Genders.values.contains(gender)) {
      throw ArgumentError.value(gender, 'gender', 'must be one of ${Genders.values}');
    }
    emit(state.copyWith(gender: gender));
    PendingOnboardingSelections.setGender(gender);
  }

  /// Also forwards the full, current set into [PendingOnboardingSelections]
  /// on every toggle (F18 Task 5) — `OnboardingState` itself is torn down
  /// the moment navigation leaves this feature's `ShellRoute` for `/auth`'s
  /// separate one, so this is the only way the choice survives to the
  /// moment sign-in succeeds.
  void toggleOccasion(String name) {
    final next = _toggled(state.chosenOccasions, name);
    emit(state.copyWith(chosenOccasions: next));
    PendingOnboardingSelections.setChosenOccasions(next);
  }

  void toggleChip(String name) {
    final next = _toggled(state.chosenChips, name);
    emit(state.copyWith(chosenChips: next));
    PendingOnboardingSelections.setChosenChips(next);
  }

  Set<String> _toggled(Set<String> set, String value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}
