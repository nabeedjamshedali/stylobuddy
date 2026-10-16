import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  static const lastSlide = 4;

  /// Welcome "Get Started": always begins at slide 1.
  void start() => emit(state.copyWith(slide: 0, exit: OnboardingExit.none));

  /// Advances; from the last slide emits [OnboardingExit.finished].
  void next() {
    if (state.slide >= lastSlide) {
      emit(state.copyWith(exit: OnboardingExit.finished));
    } else {
      emit(state.copyWith(slide: state.slide + 1));
    }
  }

  /// Goes back one slide; on slide 0 emits [OnboardingExit.backToWelcome].
  void back() {
    if (state.slide <= 0) {
      emit(state.copyWith(exit: OnboardingExit.backToWelcome));
    } else {
      emit(state.copyWith(slide: state.slide - 1));
    }
  }

  /// Called once the view has navigated for an exit signal.
  void clearExit() => emit(state.copyWith(exit: OnboardingExit.none));

  void toggleOccasion(String name) => emit(
    state.copyWith(chosenOccasions: _toggled(state.chosenOccasions, name)),
  );

  void toggleChip(String name) =>
      emit(state.copyWith(chosenChips: _toggled(state.chosenChips, name)));

  Set<String> _toggled(Set<String> set, String value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}
