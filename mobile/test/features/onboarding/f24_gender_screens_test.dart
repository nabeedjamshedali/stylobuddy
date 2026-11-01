import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:stylobuddy/features/onboarding/models/intro_slide.dart';
import 'package:stylobuddy/features/onboarding/widgets/intro_headline.dart';
import 'package:stylobuddy/features/onboarding/widgets/intro_illustration.dart';
import 'package:stylobuddy/features/onboarding/widgets/onboarding_back_scope.dart';
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';

import '../support/f02_harness.dart';

const _maleKey = Key('gender-card-male');
const _femaleKey = Key('gender-card-female');
const _toast = 'Choose Male or Female to continue';

OnboardingCubit _cubit(WidgetTester tester) =>
    tester.element(find.byType(OnboardingBackScope)).read<OnboardingCubit>();

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

/// Taps the intro primary button [n] times (Get Started / Continue).
Future<void> _advance(WidgetTester tester, int n) async {
  for (var i = 0; i < n; i++) {
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            ['Get Started', 'Continue', 'Create My Wardrobe'].contains(w.data),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void _expectSelected(WidgetTester tester, {required bool male, required bool female}) {
  expect(
    tester.getSemantics(find.byKey(_maleKey)),
    isSemantics(label: 'Male', isButton: true, isSelected: male),
  );
  expect(
    tester.getSemantics(find.byKey(_femaleKey)),
    isSemantics(label: 'Female', isButton: true, isSelected: female),
  );
}

void _expectContinueEnabled(WidgetTester tester, bool enabled) {
  expect(
    tester.getSemantics(find.bySemanticsLabel('Continue →')),
    isSemantics(
      label: 'Continue →',
      isButton: true,
      hasEnabledState: true,
      isEnabled: enabled,
    ),
  );
}

/// Asset names of every `assets/onboarding/` Image currently on screen.
List<String> _onboardingImages(WidgetTester tester) => [
  for (final image in tester.widgetList<Image>(find.byType(Image)))
    if (image.image is AssetImage &&
        (image.image as AssetImage).assetName.startsWith('assets/onboarding/'))
      (image.image as AssetImage).assetName,
];

void main() {
  setUp(PendingOnboardingSelections.clear);
  tearDown(PendingOnboardingSelections.clear);

  group('F24 /gender screen', () {
    testWidgets('F24_A08 route constant, copy, no nav, no "change later" line', (
      tester,
    ) async {
      expect(AppRoutes.gender, '/gender');
      expect(AppRoutes.noNavRoutes, contains('/gender'));

      final handle = tester.ensureSemantics();
      final router = await pumpApp(tester, '/gender');
      expect(pathOf(router), '/gender');
      for (final text in [
        'YOUR STYLE PROFILE',
        'Who are you\nstyling for?',
        'Choose your wardrobe profile for relevant outfits and clothing categories.',
        'Male',
        'Menswear and outfit inspiration',
        'Female',
        'Womenswear and outfit inspiration',
        'Continue',
        'Back',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.bySemanticsLabel('Continue →'), findsOneWidget);
      expect(find.textContaining('You can change this later.'), findsNothing);
      for (final label in navLabels) {
        expect(find.text(label), findsNothing, reason: label);
      }
      handle.dispose();
    });

    testWidgets('F24_A09 Get Started opens /gender with nothing selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = await pumpApp(tester, '/welcome');
      await tapText(tester, 'Get Started');
      expect(pathOf(router), '/gender');
      _expectSelected(tester, male: false, female: false);
      expect(_cubit(tester).state.gender, isNull);
      handle.dispose();
    });

    testWidgets('F24_A10 Continue with no choice: disabled, toast, stays', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = await pumpApp(tester, '/welcome');
      await tapText(tester, 'Get Started');
      _expectContinueEnabled(tester, false);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text(_toast), findsOneWidget);
      await tester.pumpAndSettle();
      expect(pathOf(router), '/gender');
      expect(_cubit(tester).state.gender, isNull);
      await drainToast(tester);

      await _tapKey(tester, _maleKey);
      _expectContinueEnabled(tester, true);
      handle.dispose();
    });

    testWidgets('F24_A11 cards are single-select radios and never navigate', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = await pumpApp(tester, '/welcome');
      await tapText(tester, 'Get Started');

      await _tapKey(tester, _femaleKey);
      expect(_cubit(tester).state.gender, 'female');
      _expectSelected(tester, male: false, female: true);
      expect(pathOf(router), '/gender');

      await _tapKey(tester, _maleKey);
      expect(_cubit(tester).state.gender, 'male');
      _expectSelected(tester, male: true, female: false);
      expect(pathOf(router), '/gender');

      await _tapKey(tester, _maleKey);
      expect(_cubit(tester).state.gender, 'male');
      _expectSelected(tester, male: true, female: false);
      expect(pathOf(router), '/gender');
      handle.dispose();
    });

    testWidgets('F24_A12 Continue opens slide 1 of the chosen gender', (
      tester,
    ) async {
      var router = await pumpIntro(tester, gender: 'female');
      expect(pathOf(router), '/intro');
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text('Your style.\nYour rules.'), findsOneWidget);

      router = await pumpIntro(tester, gender: 'male');
      expect(pathOf(router), '/intro');
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text('Your wardrobe.\nSmarter.'), findsOneWidget);
    });

    testWidgets('F24_A13 card images are the two gender card assets', (
      tester,
    ) async {
      await pumpApp(tester, '/gender');
      String imageIn(Key key) {
        final image = tester.widget<Image>(
          find.descendant(of: find.byKey(key), matching: find.byType(Image)),
        );
        return (image.image as AssetImage).assetName;
      }

      expect(imageIn(_maleKey), 'assets/onboarding/onboard-gender-male.png');
      expect(imageIn(_femaleKey), 'assets/onboarding/onboard-gender-female.png');
    });
  });

  group('F24 gendered intro rendering', () {
    testWidgets('F24_A17 each image slide renders only its gender copy and art', (
      tester,
    ) async {
      for (final gender in ['male', 'female']) {
        final other = gender == 'male' ? 'female' : 'male';
        final mine = introSlidesFor(gender);
        final theirs = introSlidesFor(other);
        await pumpIntro(tester, gender: gender);
        for (var i = 0; i < 5; i++) {
          if (i != 3) {
            expect(find.text(mine[i].title), findsOneWidget, reason: '$gender $i');
            expect(find.text(mine[i].description), findsOneWidget, reason: '$gender $i');
            expect(
              _onboardingImages(tester),
              ['assets/onboarding/${mine[i].image}'],
              reason: '$gender $i',
            );
          }
          for (var j = 0; j < 5; j++) {
            if (j == 3) continue; // shared occasion slide
            expect(find.text(theirs[j].title), findsNothing, reason: '$gender $i/$j');
          }
          for (final name in _onboardingImages(tester)) {
            final isFemaleArt = name.contains('onboard-f0');
            final isMaleArt = RegExp(r'onboard-0[1-4]-').hasMatch(name);
            expect(
              gender == 'female' ? isMaleArt : isFemaleArt,
              isFalse,
              reason: '$gender $i $name',
            );
          }
          if (i < 4) await _advance(tester, 1);
        }
      }
    });

    testWidgets('F24_A18 female slide 4/5 is the shared occasion picker', (
      tester,
    ) async {
      await pumpIntro(tester, gender: 'female');
      await _advance(tester, 3);
      expect(find.text('4/5'), findsOneWidget);
      expect(find.text('Tell us where\nyou’re going.'), findsOneWidget);
      expect(
        find.text('We’ll personalize recommendations\nbased on the occasion.'),
        findsOneWidget,
      );
      expect(introOccasions.length, 7);
      for (final (glyph, name) in introOccasions) {
        expect(find.text(name), findsOneWidget, reason: name);
        expect(find.text(glyph), findsWidgets, reason: glyph);
      }
      expect(_onboardingImages(tester), isEmpty);

      await tapText(tester, 'Office');
      expect(_cubit(tester).state.chosenOccasions, {'Office'});
      expect(PendingOnboardingSelections.chosenOccasionsForTest, {'Office'});
    });

    testWidgets('F24_A20 a fresh /intro redirects to /gender without a slide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = createAppRouter(initialLocation: AppRoutes.intro);
      await tester.pumpWidget(StyloBuddyApp(router: router));
      for (var frame = 0; frame < 6; frame++) {
        expect(find.byType(IntroIllustration), findsNothing, reason: 'frame $frame');
        expect(find.byType(IntroHeadline), findsNothing, reason: 'frame $frame');
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(IntroIllustration), findsNothing);
      expect(find.byType(IntroHeadline), findsNothing);
      expect(pathOf(router), '/gender');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'F24_A20 a cold /personalize back lands on /gender, not /intro '
      '(amends F02-A14)',
      (tester) async {
        final router = await pumpApp(tester, AppRoutes.personalize);
        await tapText(tester, '‹');
        expect(pathOf(router), '/gender');
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('F24 back navigation', () {
    testWidgets('F24_A21 Back on /gender keeps the choice for Get Started again', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = await pumpApp(tester, '/welcome');
      await tapText(tester, 'Get Started');
      await _tapKey(tester, _femaleKey);
      await tapText(tester, 'Back');
      expect(pathOf(router), '/welcome');
      expect(_cubit(tester).state.gender, 'female');

      await tapText(tester, 'Get Started');
      expect(pathOf(router), '/gender');
      _expectSelected(tester, male: false, female: true);
      _expectContinueEnabled(tester, true);
      handle.dispose();
    });

    testWidgets('F24_A22 in-app Back steps through slides and back to /gender', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final router = await pumpIntro(tester, gender: 'female');
      expect(find.text('1/5'), findsOneWidget);
      await tapText(tester, 'Back');
      expect(pathOf(router), '/gender');
      _expectSelected(tester, male: false, female: true);
      expect(_cubit(tester).state.gender, 'female');

      await tapText(tester, 'Continue');
      await _advance(tester, 4);
      expect(find.text('5/5'), findsOneWidget);
      for (final counter in ['4/5', '3/5', '2/5']) {
        await tapText(tester, 'Back');
        expect(find.text(counter), findsOneWidget);
        expect(_cubit(tester).state.gender, 'female');
      }
      handle.dispose();
    });

    testWidgets('F24_A23 hardware back on the female path', (tester) async {
      final handle = tester.ensureSemantics();
      var router = await pumpIntro(tester, gender: 'female');
      await _advance(tester, 2);
      expect(find.text('3/5'), findsOneWidget);
      await _systemBack(tester);
      expect(find.text('2/5'), findsOneWidget);
      await _systemBack(tester);
      expect(find.text('1/5'), findsOneWidget);
      await _systemBack(tester);
      expect(pathOf(router), '/gender');
      _expectSelected(tester, male: false, female: true);
      await _systemBack(tester);
      expect(pathOf(router), '/welcome');
      expect(_cubit(tester).state.gender, 'female');

      router = await pumpPersonalize(tester, gender: 'female');
      expect(pathOf(router), '/personalize');
      await _systemBack(tester);
      expect(pathOf(router), '/intro');
      expect(_cubit(tester).state.gender, 'female');
      expect(find.byType(IntroHeadline), findsOneWidget);
      handle.dispose();
    });

    testWidgets('F24_A24 PopScope canPop only on /welcome', (tester) async {
      for (final (location, canPop) in [
        ('/welcome', true),
        ('/gender', false),
        ('/intro', false),
        ('/personalize', false),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider(
              create: (_) => OnboardingCubit(),
              child: OnboardingBackScope(
                location: location,
                child: const SizedBox(),
              ),
            ),
          ),
        );
        final scope = tester.widget<PopScope>(
          find.descendant(
            of: find.byType(OnboardingBackScope),
            matching: find.byWidgetPredicate((w) => w is PopScope),
          ),
        );
        expect(scope.canPop, canPop, reason: location);
      }
    });
  });

  group('F24 skip paths', () {
    testWidgets('F24_A25 skipping never asks; the holder keeps the last choice', (
      tester,
    ) async {
      // Nothing chosen: Skip introduction goes straight to /auth.
      var router = await pumpApp(tester, '/welcome');
      final visited = <String>[];
      void record() => visited.add(pathOf(router));
      router.routerDelegate.addListener(record);
      await tapText(tester, 'Skip introduction');
      router.routerDelegate.removeListener(record);
      expect(pathOf(router), '/auth');
      expect(visited, isNot(contains('/gender')));
      expect(PendingOnboardingSelections.genderForTest, isNull);

      // Female, Back to /welcome, then Skip introduction: kept.
      router = await pumpApp(tester, '/welcome', fresh: true);
      await tapText(tester, 'Get Started');
      await _tapKey(tester, _femaleKey);
      await tapText(tester, 'Back');
      await tapText(tester, 'Skip introduction');
      expect(pathOf(router), '/auth');
      expect(PendingOnboardingSelections.genderForTest, 'female');

      // Intro Skip from every slide goes to /personalize, gender unchanged.
      for (var slide = 0; slide < 5; slide++) {
        router = await pumpIntro(tester, gender: 'female');
        await _advance(tester, slide);
        expect(find.text('${slide + 1}/5'), findsOneWidget);
        await tapText(tester, 'Skip');
        expect(pathOf(router), '/personalize', reason: 'slide $slide');
        expect(_cubit(tester).state.gender, 'female', reason: 'slide $slide');
      }
    });
  });
}
