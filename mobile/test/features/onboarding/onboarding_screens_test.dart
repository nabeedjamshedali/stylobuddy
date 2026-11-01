import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/onboarding/models/intro_slide.dart';
import 'package:stylobuddy/shared/widgets/chip_button.dart';
import 'package:stylobuddy/shared/widgets/option_tile.dart';

import '../support/f02_harness.dart';

Future<void> _toSlide(WidgetTester tester, int slide) async {
  for (var i = 0; i < slide; i++) {
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is Text && ['Get Started', 'Continue'].contains(w.data),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  group('welcome', () {
    testWidgets('F02_A08 renders copy; Get Started opens /gender, then intro slide 1', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/welcome');
      expect(find.textContaining('Your AI-Powered'), findsOneWidget);
      expect(find.textContaining('Personal Stylist'), findsOneWidget);
      expect(find.textContaining('Organize your wardrobe,'), findsOneWidget);
      expect(find.text('Skip introduction'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Get Started →'), findsOneWidget);
      handle.dispose();

      await tapText(tester, 'Get Started');
      // Amended 2026-10-22 (F24): the required /gender step comes first.
      expect(pathOf(router), '/gender');
      await tester.tap(find.byKey(const Key('gender-card-male')));
      await tester.pumpAndSettle();
      await tapText(tester, 'Continue');
      expect(pathOf(router), '/intro');
      expect(find.text('1/5'), findsOneWidget);
    });

    testWidgets('F02_A08 Skip introduction opens /auth', (tester) async {
      final router = await pumpApp(tester, '/welcome');
      await tapText(tester, 'Skip introduction');
      expect(pathOf(router), '/auth');
      expect(find.text('Create your wardrobe.'), findsOneWidget);
    });
  });

  group('intro', () {
    testWidgets('F02_A09 male-path slide 1 counter, copy and button labels', (
      tester,
    ) async {
      await pumpIntro(tester);
      expect(find.text('1/5'), findsOneWidget);
      expect(find.text('Your wardrobe.\nSmarter.'), findsOneWidget);
      expect(
        find.text(
          'Organize every outfit and get AI-powered styling recommendations in seconds.',
        ),
        findsOneWidget,
      );
      expect(find.text('Get Started'), findsOneWidget);
      await _toSlide(tester, 1);
      expect(find.text('Continue'), findsOneWidget);
      await _toSlide(tester, 2);
      expect(find.text('Continue'), findsOneWidget);
      await _toSlide(tester, 1);
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('Create My Wardrobe'), findsOneWidget);
    });

    testWidgets('F02_A10 male-path slide titles in order and slide 5 description', (
      tester,
    ) async {
      await pumpIntro(tester);
      for (var i = 0; i < 5; i++) {
        expect(
          find.text(introSlidesFor('male')[i].title),
          findsOneWidget,
          reason: '$i',
        );
        if (i < 4) await _toSlide(tester, 1);
      }
      expect(introSlidesFor('male')[0].title, 'Your wardrobe.\nSmarter.');
      expect(introSlidesFor('male')[1].title, 'Scan it once.\nFind it anytime.');
      expect(introSlidesFor('male')[2].title, 'Let AI style you.');
      expect(introSlidesFor('male')[3].title, 'Tell us where\nyou’re going.');
      expect(introSlidesFor('male')[4].title, 'Never wonder\n“What should I wear?”');
      expect(find.text('Smart outfits for every you.'), findsOneWidget);
    });

    testWidgets('F02_A11 five dots, one active; Back targets (slide 1 -> /gender)', (
      tester,
    ) async {
      final router = await pumpIntro(tester);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(const Key('intro-dot-active')), findsOneWidget);
        expect(find.byKey(const Key('intro-dot')), findsNWidgets(4));
        if (i < 4) await _toSlide(tester, 1);
      }

      // Back on slide 5 -> 4 ... down to slide 2 -> 1.
      await tapText(tester, 'Back');
      expect(find.text('4/5'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tapText(tester, 'Back');
      }
      expect(find.text('1/5'), findsOneWidget);

      await tapText(tester, 'Back');
      // Amended 2026-10-22 (F24): Back on slide 1 returns to /gender.
      expect(pathOf(router), '/gender');
    });

    testWidgets('F02_A11 Skip goes to /personalize from any slide', (
      tester,
    ) async {
      final router = await pumpIntro(tester);
      await _toSlide(tester, 2);
      await tapText(tester, 'Skip');
      expect(pathOf(router), '/personalize');
    });

    testWidgets('F02_A01 last slide button finishes to /personalize', (
      tester,
    ) async {
      final router = await pumpIntro(tester);
      await _toSlide(tester, 4);
      await tapText(tester, 'Create My Wardrobe');
      expect(pathOf(router), '/personalize');
    });

    testWidgets('F02_A12 slide 4 lists occasions with glyphs and toggles', (
      tester,
    ) async {
      await pumpIntro(tester);
      await _toSlide(tester, 3);
      const expected = [
        ('▣', 'Office'),
        ('♧', 'Wedding'),
        ('♥', 'Date Night'),
        ('☼', 'Casual Day Out'),
        ('✧', 'Party'),
        ('♙', 'Interview'),
        ('⌂', 'Vacation'),
      ];
      expect(introOccasions, expected);
      for (final (glyph, name) in expected) {
        expect(find.text(name), findsOneWidget);
        expect(find.text(glyph), findsWidgets);
      }
      expect(find.byKey(const Key('occasion-Office')), findsOneWidget);
      await tapText(tester, 'Office');
      expect(find.byKey(const Key('occasion-Office-chosen')), findsOneWidget);
      await tapText(tester, 'Office');
      expect(find.byKey(const Key('occasion-Office')), findsOneWidget);
      expect(find.byKey(const Key('occasion-Office-chosen')), findsNothing);
    });

    testWidgets('F02_A26 intro and welcome show no bottom nav', (tester) async {
      await pumpIntro(tester);
      for (final label in navLabels) {
        expect(find.text(label), findsNothing);
      }
    });
  });

  group('personalize', () {
    testWidgets('F02_A13 renders head, options, preselected and toasts', (
      tester,
    ) async {
      await pumpApp(tester, '/personalize');
      expect(find.text('Your Style, Your Way'), findsOneWidget);
      expect(find.text('What feels most like you?'), findsOneWidget);
      expect(
        find.text('Choose a few favorites. You can change them later.'),
        findsOneWidget,
      );
      final tiles = tester.widgetList<OptionTile>(find.byType(OptionTile));
      expect(tiles.map((t) => t.label), [
        'Minimal & clean',
        'Smart casual',
        'Elegant & polished',
        'Relaxed & comfy',
        'Colorful & bold',
      ]);
      expect(tiles.where((t) => t.selected).map((t) => t.label), [
        'Smart casual',
      ]);

      await tapText(tester, 'Colorful & bold');
      expect(find.text('Colorful & bold selected'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('F02_A14 chips toggle independently; Continue opens /auth', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/personalize');
      bool selected(String l) => tester
          .widget<ChipButton>(find.widgetWithText(ChipButton, l))
          .selected;
      for (final l in ['Everyday', 'Office', 'Wedding', 'Party', 'Travel']) {
        expect(find.widgetWithText(ChipButton, l), findsOneWidget);
        expect(selected(l), isFalse);
      }
      await tapText(tester, 'Office');
      await tapText(tester, 'Travel');
      expect(selected('Office'), isTrue);
      expect(selected('Travel'), isTrue);
      expect(selected('Party'), isFalse);
      await tapText(tester, 'Office');
      expect(selected('Office'), isFalse);
      expect(selected('Travel'), isTrue);

      await tapText(tester, 'Continue →');
      expect(pathOf(router), '/auth');
    });

    testWidgets('F02_A14 the back button on Personalize returns to /intro', (
      tester,
    ) async {
      final router = await pumpPersonalize(tester);
      await tapText(tester, '‹');
      expect(pathOf(router), '/intro');
    });

    testWidgets('F02_A26 personalize shows no bottom nav', (tester) async {
      await pumpApp(tester, '/personalize');
      for (final label in navLabels) {
        expect(find.text(label), findsNothing);
      }
    });
  });

  group('system back', () {
    testWidgets('F02_A11 system back on intro steps back one slide', (
      tester,
    ) async {
      final router = await pumpIntro(tester);
      await _toSlide(tester, 2);
      expect(find.text('3/5'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('2/5'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('1/5'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Amended 2026-10-22 (F24): system back on slide 1 returns to /gender.
      expect(pathOf(router), '/gender');
    });

    testWidgets('F02_A14 system back on personalize returns to /intro', (
      tester,
    ) async {
      final router = await pumpPersonalize(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pathOf(router), '/intro');
    });
  });
}
