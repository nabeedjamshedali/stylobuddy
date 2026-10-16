/// One-shot navigation outcome of [OnboardingCubit.next]/[OnboardingCubit.back].
enum OnboardingExit { none, finished, backToWelcome }

class OnboardingState {
  const OnboardingState({
    this.slide = 0,
    this.chosenOccasions = const {},
    this.chosenChips = const {},
    this.exit = OnboardingExit.none,
  });

  /// Zero-based intro slide (0..4).
  final int slide;

  /// Occasions ticked on intro slide 4.
  final Set<String> chosenOccasions;

  /// Occasion chips toggled on `/personalize`.
  final Set<String> chosenChips;
  final OnboardingExit exit;

  OnboardingState copyWith({
    int? slide,
    Set<String>? chosenOccasions,
    Set<String>? chosenChips,
    OnboardingExit? exit,
  }) => OnboardingState(
    slide: slide ?? this.slide,
    chosenOccasions: chosenOccasions ?? this.chosenOccasions,
    chosenChips: chosenChips ?? this.chosenChips,
    exit: exit ?? this.exit,
  );
}
