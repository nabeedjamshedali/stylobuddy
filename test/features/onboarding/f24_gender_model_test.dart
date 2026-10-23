import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_state.dart';
import 'package:stylobuddy/features/onboarding/models/intro_slide.dart';
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';
import 'package:stylobuddy/shared/models/genders.dart';

typedef _Copy = (String title, String description, String? image);

const _maleCopy = <_Copy>[
  (
    'Your wardrobe.\nSmarter.',
    'Organize every outfit and get AI-powered styling recommendations in seconds.',
    'onboard-01-model.png',
  ),
  (
    'Scan it once.\nFind it anytime.',
    'Store shirts, pants, shoes, watches, bags, and accessories in one organized place.',
    'onboard-02-closet.png',
  ),
  (
    'Let AI style you.',
    'Pick one item and receive complete outfit suggestions tailored to your wardrobe.',
    'onboard-03-style.png',
  ),
  (
    'Tell us where\nyou’re going.',
    'We’ll personalize recommendations\nbased on the occasion.',
    null,
  ),
  (
    'Never wonder\n“What should I wear?”',
    'Smart outfits for every you.',
    'onboard-04-outfit.png',
  ),
];

const _femaleCopy = <_Copy>[
  (
    'Your style.\nYour rules.',
    'Turn the pieces you already own into standout looks, styled by AI in seconds.',
    'onboard-f01-wardrobe.png',
  ),
  (
    'Scan it once.\nStyle it forever.',
    'Dresses, tops, trousers, shoes, bags and jewelry, beautifully organized in one place.',
    'onboard-f02-closet.png',
  ),
  (
    'Effortless looks,\non demand.',
    'Pick one piece you love and get complete outfits built around it.',
    'onboard-f03-style.png',
  ),
  (
    'Tell us where\nyou’re going.',
    'We’ll personalize recommendations\nbased on the occasion.',
    null,
  ),
  (
    'Dress for how\nyou want to feel.',
    'Outfits for every version of you.',
    'onboard-f04-outfit.png',
  ),
];

List<_Copy> _copyOf(List<IntroSlide> slides) =>
    [for (final s in slides) (s.title, s.description, s.image)];

void main() {
  setUp(PendingOnboardingSelections.clear);
  tearDown(PendingOnboardingSelections.clear);

  group('F24 Genders', () {
    test('F24_A01 Genders constants and exactly two values', () {
      expect(Genders.male, 'male');
      expect(Genders.female, 'female');
      expect(Genders.values, {'male', 'female'});
      expect(Genders.values.length, 2);
    });
  });

  group('F24 OnboardingCubit gender', () {
    test('F24_A02 fresh cubit has null gender; clear() nulls the holder slot', () {
      expect(OnboardingCubit().state.gender, isNull);
      PendingOnboardingSelections.setGender('female');
      PendingOnboardingSelections.clear();
      expect(PendingOnboardingSelections.genderForTest, isNull);
    });

    test('F24_A03 setGender sets state and holder, last wins, touches nothing else', () {
      final cubit = OnboardingCubit();
      cubit.next();
      cubit.toggleOccasion('Office');
      cubit.toggleChip('Party');
      final before = cubit.state;

      cubit.setGender('female');
      expect(cubit.state.gender, 'female');
      expect(PendingOnboardingSelections.genderForTest, 'female');

      cubit.setGender('male');
      expect(cubit.state.gender, 'male');
      expect(PendingOnboardingSelections.genderForTest, 'male');

      expect(cubit.state.slide, before.slide);
      expect(cubit.state.exit, before.exit);
      expect(cubit.state.chosenOccasions, {'Office'});
      expect(cubit.state.chosenChips, {'Party'});
      expect(PendingOnboardingSelections.chosenOccasionsForTest, {'Office'});
      expect(PendingOnboardingSelections.chosenChipsForTest, {'Party'});
    });

    test('F24_A04 invalid values throw ArgumentError and change nothing', () async {
      for (final prior in <String?>[null, 'male']) {
        PendingOnboardingSelections.clear();
        final cubit = OnboardingCubit();
        if (prior != null) cubit.setGender(prior);
        final emitted = <OnboardingState>[];
        final sub = cubit.stream.listen(emitted.add);

        for (final bad in ['', 'Female', 'other']) {
          expect(() => cubit.setGender(bad), throwsArgumentError, reason: bad);
          expect(cubit.state.gender, prior, reason: bad);
          expect(PendingOnboardingSelections.genderForTest, prior, reason: bad);
        }
        await Future<void>.delayed(Duration.zero);
        expect(emitted, isEmpty, reason: 'prior=$prior');
        await sub.cancel();
        await cubit.close();
      }
    });

    test('F24_A05 start() preserves gender, resets slide and exit', () {
      final cubit = OnboardingCubit();
      cubit.setGender('female');
      cubit.next();
      cubit.next();
      cubit.start();
      expect(cubit.state.slide, 0);
      expect(cubit.state.exit, OnboardingExit.none);
      expect(cubit.state.gender, 'female');
    });

    test('F24_A06 OnboardingExit values; back() on slide 0 -> backToGender', () {
      expect(OnboardingExit.values, [
        OnboardingExit.none,
        OnboardingExit.finished,
        OnboardingExit.backToGender,
      ]);
      final cubit = OnboardingCubit();
      cubit.back();
      expect(cubit.state.exit, OnboardingExit.backToGender);
      expect(cubit.state.slide, 0);
      cubit.clearExit();

      cubit.next();
      cubit.next();
      cubit.back();
      expect(cubit.state.slide, 1);
      expect(cubit.state.exit, OnboardingExit.none);
    });
  });

  group('F24 PendingOnboardingSelections gender slot', () {
    test('F24_A07 gender slot is independent of occasions/chips', () {
      expect(PendingOnboardingSelections.consumeGender(), isNull,
          reason: 'never-set holder');

      PendingOnboardingSelections.setChosenOccasions({'Office'});
      PendingOnboardingSelections.setGender('female');
      expect(PendingOnboardingSelections.consume(), {'Office'});
      expect(PendingOnboardingSelections.genderForTest, 'female');

      PendingOnboardingSelections.setChosenOccasions({'Wedding'});
      PendingOnboardingSelections.setChosenChips({'Travel'});
      expect(PendingOnboardingSelections.consumeGender(), 'female');
      expect(PendingOnboardingSelections.consumeGender(), isNull);
      expect(PendingOnboardingSelections.chosenOccasionsForTest, {'Wedding'});
      expect(PendingOnboardingSelections.chosenChipsForTest, {'Travel'});

      PendingOnboardingSelections.setGender('male');
      PendingOnboardingSelections.clear();
      expect(PendingOnboardingSelections.chosenOccasionsForTest, isEmpty);
      expect(PendingOnboardingSelections.chosenChipsForTest, isEmpty);
      expect(PendingOnboardingSelections.genderForTest, isNull);
    });
  });

  group('F24 parametrized intro slides', () {
    test('F24_A14 male path is exactly the pre-F24 copy and images', () {
      final slides = introSlidesFor('male');
      expect(slides.length, 5);
      expect(_copyOf(slides), _maleCopy);
      expect(slides[3].isOccasions, isTrue);
    });

    test('F24_A15 female path copy and images', () {
      final slides = introSlidesFor('female');
      expect(slides.length, 5);
      expect(_copyOf(slides), _femaleCopy);
      expect(slides[3].isOccasions, isTrue);
    });

    test('F24_A16 shared layout, length budget, ArgumentError, one list literal', () {
      final male = introSlidesFor('male');
      final female = introSlidesFor('female');
      for (var i = 0; i < 5; i++) {
        expect(female[i].maxImageWidth, male[i].maxImageWidth, reason: '$i');
        expect(female[i].heightFraction, male[i].heightFraction, reason: '$i');
        expect(female[i].minHeight, male[i].minHeight, reason: '$i');
        expect(female[i].topMargin, male[i].topMargin, reason: '$i');
        expect(female[i].isOccasions, male[i].isOccasions, reason: '$i');
        expect(
          female[i].description.length,
          lessThanOrEqualTo(male[i].description.length + 5),
          reason: '$i',
        );
      }
      expect(() => introSlidesFor('other'), throwsArgumentError);
      expect(() => introSlides.first.forGender(''), throwsArgumentError);

      final source = File(
        'lib/features/onboarding/models/intro_slide.dart',
      ).readAsStringSync();
      expect('<IntroSlide>['.allMatches(source).length, 1);
      expect(introSlides.length, 5);
    });

    test('F24_A19 every referenced asset exists; female slides are distinct', () {
      File asset(String name) => File('assets/onboarding/$name');
      final names = <String>{
        for (final g in Genders.values)
          for (final s in introSlidesFor(g))
            if (s.image != null) s.image!,
        'onboard-gender-male.png',
        'onboard-gender-female.png',
      };
      for (final name in names) {
        expect(asset(name).existsSync(), isTrue, reason: name);
      }

      final female = [
        for (final s in introSlidesFor('female'))
          if (s.image != null) s.image!,
      ];
      expect(female, [
        'onboard-f01-wardrobe.png',
        'onboard-f02-closet.png',
        'onboard-f03-style.png',
        'onboard-f04-outfit.png',
      ]);
      final femaleBytes = [for (final f in female) asset(f).readAsBytesSync()];
      for (var i = 0; i < femaleBytes.length; i++) {
        for (var j = i + 1; j < femaleBytes.length; j++) {
          expect(
            listEquals(femaleBytes[i], femaleBytes[j]),
            isFalse,
            reason: '${female[i]} == ${female[j]}',
          );
        }
      }
      const maleFiles = [
        'onboard-01-model.png',
        'onboard-02-closet.png',
        'onboard-03-style.png',
        'onboard-04-outfit.png',
      ];
      for (final m in maleFiles) {
        final maleBytes = asset(m).readAsBytesSync();
        for (var i = 0; i < female.length; i++) {
          expect(
            listEquals(maleBytes, femaleBytes[i]),
            isFalse,
            reason: '${female[i]} == $m',
          );
        }
      }
    });
  });
}
