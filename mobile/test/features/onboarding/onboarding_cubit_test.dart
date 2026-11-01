import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_state.dart';

void main() {
  group('OnboardingCubit', () {
    test('F02_A01 starts at slide 0, next/back move, ends emit exits', () {
      final cubit = OnboardingCubit();
      expect(cubit.state.slide, 0);
      expect(cubit.state.exit, OnboardingExit.none);

      cubit.next();
      expect(cubit.state.slide, 1);
      cubit.back();
      expect(cubit.state.slide, 0);

      cubit.back();
      expect(cubit.state.exit, OnboardingExit.backToGender);
      expect(cubit.state.slide, 0);
      cubit.clearExit();

      for (var i = 0; i < 4; i++) {
        cubit.next();
      }
      expect(cubit.state.slide, 4);
      expect(cubit.state.exit, OnboardingExit.none);
      cubit.next();
      expect(cubit.state.exit, OnboardingExit.finished);
      expect(cubit.state.slide, 4, reason: 'never runs past the last slide');
    });

    test('F02_A02 toggleOccasion adds then removes', () {
      final cubit = OnboardingCubit();
      cubit.toggleOccasion('Office');
      expect(cubit.state.chosenOccasions, {'Office'});
      cubit.toggleOccasion('Office');
      expect(cubit.state.chosenOccasions, isEmpty);
    });

    test('F02_A14 chips toggle independently of each other', () {
      final cubit = OnboardingCubit();
      cubit.toggleChip('Office');
      cubit.toggleChip('Party');
      expect(cubit.state.chosenChips, {'Office', 'Party'});
      cubit.toggleChip('Office');
      expect(cubit.state.chosenChips, {'Party'});
      expect(cubit.state.chosenOccasions, isEmpty);
    });
  });
}
