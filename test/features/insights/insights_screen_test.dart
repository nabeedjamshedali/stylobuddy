import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/insights/widgets/in_empty_state.dart';
import 'package:stylobuddy/features/insights/widgets/in_stat_cards.dart';
import 'package:stylobuddy/features/insights/widgets/in_wear_activity_card.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/shared/widgets/screen_head.dart';

import '../support/f02_harness.dart';

WardrobeCubit wardrobeCubitOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<WardrobeCubit>();

OutfitsCubit outfitsCubitOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<OutfitsCubit>();

/// Finds [text] only within the `.in-stats` stat cards, since the same
/// number (count or worn) is often repeated in the donut centre or the
/// wear-activity summary.
Finder statCardText(String text) =>
    find.descendant(of: find.byType(InStatCards), matching: find.text(text));

/// Removes every item, one at a time (`WardrobeCubit` has no bulk clear).
void clearWardrobe(WardrobeCubit wardrobe) {
  for (final item in List.of(wardrobe.state.items)) {
    wardrobe.removeItem(item.id);
  }
}

void main() {
  testWidgets(
    'F12_A07 empty wardrobe renders the screen head and empty state',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.insights);
      clearWardrobe(wardrobeCubitOf(tester));
      await tester.pumpAndSettle();

      expect(find.byType(ScreenHead), findsOneWidget);
      expect(find.text('Style Insights'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(InEmptyState), matching: find.text('▦')),
        findsOneWidget,
      );
      expect(find.text('Insights start with your wardrobe'), findsOneWidget);
      expect(
        find.text(
          'Add your first clothing pieces to see category breakdowns, '
          'style patterns and wearing habits.',
        ),
        findsOneWidget,
      );
      expect(find.text('Add clothing'), findsOneWidget);

      await tapText(tester, 'Add clothing');
      expect(pathOf(router), AppRoutes.import);
    },
  );

  testWidgets(
    'F12_A06 empty wardrobe does not render stat cards or report sections',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      clearWardrobe(wardrobeCubitOf(tester));
      await tester.pumpAndSettle();
      expect(find.text('YOUR PERSONAL STYLE REPORT'), findsNothing);
      expect(find.text('WARDROBE'), findsNothing);
    },
  );

  testWidgets(
    'F12_A08 seed report renders heading, subtitle and the three stat cards',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(find.text('YOUR PERSONAL STYLE REPORT'), findsOneWidget);
      expect(find.text('Style Insights.', findRichText: true), findsOneWidget);
      expect(
        find.text('A clearer picture of what you own and wear.'),
        findsOneWidget,
      );
      expect(find.text('WARDROBE'), findsOneWidget);
      expect(statCardText('23'), findsOneWidget);
      expect(find.text('clothing pieces'), findsOneWidget);
      expect(find.text('LOGGED WEARS'), findsOneWidget);
      expect(statCardText('0'), findsOneWidget);
      expect(find.text('outfit wear entries'), findsOneWidget);
      expect(find.text('EVER WORN'), findsOneWidget);
      expect(statCardText('18'), findsOneWidget);
      expect(find.text('tracked pieces'), findsOneWidget);
    },
  );

  testWidgets(
    'F12_A09 after logWear(1) the LOGGED WEARS card reads 1, not blank',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(statCardText('0'), findsOneWidget);
      outfitsCubitOf(tester).logWear(1);
      await tester.pumpAndSettle();
      expect(statCardText('1'), findsOneWidget);
    },
  );

  testWidgets(
    'F12_A10 wardrobe mix caption, donut centre and legend percentages',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(find.text('7 categories'), findsOneWidget);
      expect(find.text('items'), findsOneWidget);
      // 'Shirts' appears in both the mix legend and the bars card.
      expect(find.text('Shirts'), findsExactly(2));
      expect(find.text('22%'), findsWidgets);
      expect(find.text('17%'), findsWidgets);
      expect(find.text('9%'), findsWidgets);
      expect(find.text('4%'), findsOneWidget);
    },
  );

  testWidgets(
    'F12_A11 category breakdown lists one bar per category with its count',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(find.text('Category breakdown'), findsOneWidget);
      expect(find.text('Items owned'), findsOneWidget);
      // Each category label also appears in the mix legend above.
      expect(find.text('Pants'), findsExactly(2));
      expect(find.text('Skirts'), findsExactly(2));
    },
  );

  testWidgets(
    'F12_A12 wear activity shows 18 / 23 pieces, progress text and the '
    'has/have note',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(
        find.descendant(
          of: find.byType(InWearActivityCard),
          matching: find.text('18'),
        ),
        findsOneWidget,
      );
      expect(find.text(' / 23'), findsOneWidget);
      expect(find.text('pieces with recorded wears'), findsOneWidget);
      expect(
        find.text(
          '5 items have no recorded wears. This uses the demo’s item wear '
          'counters; it is not a prediction of how often you actually dress '
          'in each piece.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'F12_A12 singular note reads "1 item has no recorded wears"',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      final wardrobe = wardrobeCubitOf(tester);
      // Mark every unworn item worn except one, leaving exactly 1 unused.
      for (final item in wardrobe.state.items) {
        if (item.wears == 0 && item.id != 'white-shirt') {
          wardrobe.adjustWears([item.id], 1);
        }
      }
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 item has no recorded wears.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('F12_A13 "View wear history →" opens /saved', (tester) async {
    final router = await pumpApp(tester, AppRoutes.insights);
    await tapText(tester, 'View wear history →');
    expect(pathOf(router), AppRoutes.saved);
  });

  testWidgets(
    'F12_A14 most-worn pieces shows 4 rows, navy-chinos first, and opens '
    '/clothing on tap',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.insights);
      expect(find.text('Most-worn pieces'), findsOneWidget);
      expect(find.text('Top items'), findsOneWidget);
      expect(find.text('Navy Chinos'), findsOneWidget);
      expect(find.text('4 recorded wears · Pants'), findsOneWidget);

      await tapText(tester, 'Navy Chinos');
      expect(pathOf(router), AppRoutes.clothingPath);
    },
  );

  testWidgets(
    'F12_A15 underused pieces shows 5 rows, white-shirt first',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(find.text('Rediscover your wardrobe'), findsOneWidget);
      expect(find.text('Underused pieces'), findsOneWidget);
      expect(find.text('White Oxford Shirt'), findsOneWidget);
      expect(
        find.text('0 recorded wears · Try styling this piece'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'F12_A16 when every item has wears >= 1, underused falls back to the '
    'reversed top 4',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      final wardrobe = wardrobeCubitOf(tester);
      for (final item in wardrobe.state.items) {
        if (item.wears == 0) wardrobe.adjustWears([item.id], 1);
      }
      await tester.pumpAndSettle();
      // Reversed top order: the lowest-wear items (after bumping, every item
      // has wears >= 1; the former-zero items now have wears 1 and sit last
      // in `top`, so they lead the reversed list).
      expect(find.text('0 recorded wears · Try styling this piece'), findsNothing);
      expect(find.text('1 recorded wears · Try styling this piece'), findsWidgets);
    },
  );

  testWidgets(
    'F12_A17 occasion readiness rows render verbatim, including "1 pieces"',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      expect(find.text('Occasion readiness'), findsOneWidget);
      expect(find.text('Wardrobe labels'), findsOneWidget);
      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('8 pieces'), findsOneWidget);
      expect(find.text('Date Night'), findsOneWidget);
      expect(find.text('1 pieces'), findsOneWidget);
    },
  );

  testWidgets(
    'F12_A18 callout and disclaimer render; Match My Clothes opens /matching',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.insights);
      expect(find.text('Put your wardrobe to work'), findsOneWidget);
      expect(
        find.text('Find new combinations for clothes you already own.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Insights are based on wardrobe details and manually recorded '
          'wears. No external fashion model is connected in this demo.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Match My Clothes →');
      expect(pathOf(router), AppRoutes.matching);
    },
  );

  testWidgets(
    'F12_A19 section caption with a single category reads "1 categories" '
    'verbatim',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      final wardrobe = wardrobeCubitOf(tester);
      final toRemove = [
        for (final i in wardrobe.state.items)
          if (i.category != 'Shirts') i.id,
      ];
      for (final id in toRemove) {
        wardrobe.removeItem(id);
      }
      await tester.pumpAndSettle();
      expect(find.text('1 categories'), findsOneWidget);
    },
  );

  testWidgets(
    'F12_A20 insights never show an item removed from the wardrobe',
    (tester) async {
      await pumpApp(tester, AppRoutes.insights);
      final wardrobe = wardrobeCubitOf(tester);
      wardrobe.removeItem('white-shirt');
      await tester.pumpAndSettle();
      expect(find.text('White Oxford Shirt'), findsNothing);
      // WARDROBE count dropped by 1; shown both in the stat card and the
      // donut centre.
      expect(find.text('22'), findsExactly(2));
      expect(find.text('23'), findsNothing);
    },
  );
}
