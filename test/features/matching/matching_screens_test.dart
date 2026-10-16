import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';

import '../support/f02_harness.dart';

T cubitOf<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<T>();

void main() {
  testWidgets('F04_A01 matching intro copy', (tester) async {
    await pumpApp(tester, AppRoutes.matching);
    for (final t in [
      'Match My Clothes',
      'YOUR WARDROBE, BETTER TOGETHER',
      'Find the pieces that belong together.',
      'Choose a few options, lock anything you definitely want to wear, '
          'and discover looks made entirely from your wardrobe.',
      '01',
      'Select your candidates',
      'Pick tops, bottoms, dresses and layers to compare.',
      '02',
      'Lock your must-wear pieces',
      'Required garments stay in every suggested look.',
      '03',
      'Get your best three matches',
      'Complete outfits with owned footwear and accessories.',
      'Choose from my wardrobe →',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('F04_A02 Choose from my wardrobe resets state and navigates', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matching);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit
      ..toggleSelect('white-shirt')
      ..toggleLock('white-shirt')
      ..setCategory('Shoes');
    await tapText(tester, 'Choose from my wardrobe →');
    expect(cubit.state.selected, isEmpty);
    expect(cubit.state.locked, isEmpty);
    expect(cubit.state.category, 'All');
    expect(pathOf(router), AppRoutes.matchSelect);
  });

  testWidgets('F04_A03 match-select heading and chips', (tester) async {
    await pumpApp(tester, AppRoutes.matchSelect);
    for (final t in [
      'Select Clothing',
      'STEP 1 OF 3',
      'What should we match?',
      'Select the pieces you want AI to compare. You can choose multiple '
          'items in each category.',
      'All',
      'Shirts',
      'Pants',
      'Dresses',
      'Skirts',
      'Outerwear',
      'Shoes',
      'Accessories',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('F04_A04 zero selected summary, no strip, disabled continue', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.text('Start with a shirt, trousers or dress'), findsOneWidget);
    expect(find.text('Continue with 0 items →'), findsOneWidget);
    await tapText(tester, 'Continue with 0 items →');
    expect(pathOf(router), AppRoutes.matchSelect);
  });

  testWidgets('F04_A05 toggling tiles updates mark, summary and button', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.matchSelect);
    expect(find.text('+'), findsWidgets);
    await tapText(tester, 'White Oxford Shirt');
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Your chosen pieces are shown below'), findsOneWidget);
    expect(find.text('Continue with 1 item →'), findsOneWidget);
    await tester.ensureVisible(find.text('Navy Chinos'));
    await tester.tap(find.text('Navy Chinos'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Continue with 2 items →'), findsOneWidget);
    await tester.ensureVisible(find.text('White Oxford Shirt'));
    await tester.tap(find.text('White Oxford Shirt'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('F04_A06 category chips filter tiles and store category', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    await tapText(tester, 'Shoes');
    expect(cubit.state.category, 'Shoes');
    for (final shoe in [
      'White Sneakers',
      'Brown Loafers',
      'Black Boots',
      'Black Heels',
    ]) {
      expect(find.text(shoe), findsOneWidget, reason: shoe);
    }
    expect(find.text('White Oxford Shirt'), findsNothing);
    await tapText(tester, 'All');
    expect(cubit.state.category, 'All');
    expect(find.text('White Oxford Shirt'), findsOneWidget);
    expect(find.text('White Sneakers'), findsOneWidget);
  });

  testWidgets('F04_A07 deselecting a locked item also unlocks it', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleLock('white-shirt');
    expect(cubit.state.locked, ['white-shirt']);
    cubit.toggleSelect('white-shirt');
    expect(cubit.state.selected, isEmpty);
    expect(cubit.state.locked, isEmpty);
  });

  testWidgets('F04_A08 selection strip shows mini image and lock badge', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleLock('white-shirt');
    await tester.pumpAndSettle();
    expect(find.text('◆'), findsOneWidget);
  });

  testWidgets('F04_A09 match-review heading and candidate captions', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleSelect('white-sneakers');
    router.push(AppRoutes.matchReview);
    await tester.pumpAndSettle();
    for (final t in [
      'Review Your Selection',
      'STEP 2 OF 3',
      'Anything you must wear?',
      'Required',
      'Candidate',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Flexible candidate'), findsNWidgets(3));
    expect(find.text('◇'), findsNWidgets(3));
  });

  testWidgets('F04_A10 locking a tile flips caption, badge and note', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleSelect('white-sneakers');
    router.push(AppRoutes.matchReview);
    await tester.pumpAndSettle();
    await tapText(tester, 'White Oxford Shirt');
    expect(find.text('Required in every look'), findsOneWidget);
    expect(find.text('◆'), findsOneWidget);
    expect(find.text('1 required · 2 flexible'), findsOneWidget);
    await tapText(tester, 'White Oxford Shirt');
    expect(find.text('Flexible candidate'), findsNWidgets(3));
  });

  testWidgets('F04_A11 empty selection shows warning, disables continue', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchReview);
    expect(
      find.text('Choose at least one item before continuing.'),
      findsOneWidget,
    );
    await tapText(tester, 'Continue to preferences →');
    expect(pathOf(router), AppRoutes.matchReview);
    await tapText(tester, 'Edit selected items');
    expect(pathOf(router), AppRoutes.matchSelect);
  });

  testWidgets('F04_A12 match-options copy, toggle default, singular note', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleLock('white-shirt');
    router.push(AppRoutes.matchOptions);
    await tester.pumpAndSettle();
    for (final t in [
      'Styling Preferences',
      'STEP 3 OF 3',
      "Let's finish the look.",
      'Everyday',
      'Complete my outfits',
      'Based on 2 selected items',
      '1 must-wear piece will be preserved. We will show up to three '
          'different combinations, without inventing new clothes.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isTrue);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    for (final o in [
      'Office',
      'Wedding',
      'Date Night',
      'Casual',
      'Party',
      'Vacation',
    ]) {
      expect(find.text(o), findsOneWidget, reason: o);
    }
    await tester.tap(find.text('Everyday').last);
    await tester.pumpAndSettle();
  });

  testWidgets('F04_A12 note is plural for zero or many must-wear pieces', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    router.push(AppRoutes.matchOptions);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('0 must-wear pieces will be preserved'),
      findsOneWidget,
    );
  });

  testWidgets('F04_A13 occasion outside the option list falls back', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.setOccasion('Casual Day Out');
    cubit.toggleSelect('white-shirt');
    router.push(AppRoutes.matchOptions);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Everyday'), findsWidgets);
    await tester.tap(find.text('✧ Find my best matches'));
    await tester.pump();
    expect(cubit.state.occasion, 'Everyday');
    await tester.pump(StylistCubit.generationDelay);
    await tester.pumpAndSettle();
  });

  testWidgets('F04_A14 unchecking Complete my outfits excludes extras', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    router.push(AppRoutes.matchOptions);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(cubit.state.accessories, isFalse);
    await tapText(tester, '✧ Find my best matches');
    await tester.pump(StylistCubit.generationDelay);
    await tester.pumpAndSettle();
    for (final look in cubit.state.results) {
      expect(
        look.items.every((id) => cubit.state.selected.contains(id)),
        isTrue,
      );
    }
  });

  testWidgets('F04_A15 Find my best matches stores occasion and jumps', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    router.push(AppRoutes.matchOptions);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wedding').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('✧ Find my best matches'));
    await tester.pump();
    expect(cubit.state.occasion, 'Wedding');
    await tester.pump(const Duration(milliseconds: 400));
    expect(pathOf(router), AppRoutes.matchingProgress);
    expect(find.text('Matching Your Clothes'), findsOneWidget);
    expect(find.text('Discovering your best combinations'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchingResults);
  });

  testWidgets('F04_A15 leaving matching-progress early cancels the jump', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    router.push(AppRoutes.matchOptions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('✧ Find my best matches'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    router.pop();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchOptions);
  });

  testWidgets('F04_A16 matching-results head, context line and look names', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleSelect('white-sneakers');
    cubit.toggleLock('white-shirt');
    final run = cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    router.push(AppRoutes.matchingResults);
    await tester.pumpAndSettle();
    for (final t in [
      'Your Best Matches',
      '1 locked must-wear item · 3 selected candidates',
      'Best Match',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tapText(tester, 'Edit chosen clothing');
    expect(pathOf(router), AppRoutes.matchSelect);
  });

  testWidgets('F04_A16 plural items in the context line', (tester) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleLock('white-shirt');
    cubit.toggleLock('navy-chinos');
    final run = cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    router.push(AppRoutes.matchingResults);
    await tester.pumpAndSettle();
    expect(
      find.text('2 locked must-wear items · 2 selected candidates'),
      findsOneWidget,
    );
  });

  testWidgets('F04_A17 single locked item with accessories off never crashes', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.setAccessories(false);
    cubit.toggleSelect('black-skirt');
    cubit.toggleLock('black-skirt');
    final run = cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    router.push(AppRoutes.matchingResults);
    await tester.pumpAndSettle();
    expect(find.text('1 look from your selection'), findsOneWidget);
    expect(cubit.state.results, hasLength(1));
    expect(cubit.state.results.first.items, ['black-skirt']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F04_A18 Refresh combinations re-runs generateMatches', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleLock('white-shirt');
    final run = cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    router.push(AppRoutes.matchingResults);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('↻ Refresh combinations'));
    await tester.tap(find.text('↻ Refresh combinations'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(pathOf(router), AppRoutes.matchingProgress);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchingResults);
  });

  testWidgets('F04_A19 matching-detail locked caption and back target', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    cubit.toggleSelect('white-shirt');
    cubit.toggleSelect('navy-chinos');
    cubit.toggleLock('white-shirt');
    final run = cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    router.push(AppRoutes.matchingResults);
    await tester.pumpAndSettle();
    await tapText(tester, 'Best Match');
    expect(pathOf(router), AppRoutes.matchingDetail);
    expect(find.text('Outfit Details'), findsOneWidget);
    expect(find.text('White Oxford Shirt · Locked'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchingResults);
  });

  testWidgets('F04_A20 header back targets fall back when there is no pop', (
    tester,
  ) async {
    var router = await pumpApp(tester, AppRoutes.matchSelect);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matching);

    router = await pumpApp(tester, AppRoutes.matchReview);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchSelect);

    router = await pumpApp(tester, AppRoutes.matchOptions);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchReview);

    router = await pumpApp(tester, AppRoutes.matchingResults);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.matchReview);
  });

  testWidgets('F04_A21 deleted wardrobe item renders via fallback in review', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.matchSelect);
    final cubit = cubitOf<StylistCubit>(tester);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    cubit.toggleSelect('white-shirt');
    wardrobe.removeItem('white-shirt');
    router.push(AppRoutes.matchReview);
    await tester.pumpAndSettle();
    expect(find.text('white shirt'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final run = cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'F04_A23 empty selection cannot pass through to generateMatches',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.matchSelect);
      expect(find.text('Continue with 0 items →'), findsOneWidget);
      await tapText(tester, 'Continue with 0 items →');
      expect(pathOf(router), AppRoutes.matchSelect);
      router.push(AppRoutes.matchReview);
      await tester.pumpAndSettle();
      expect(
        find.text('Choose at least one item before continuing.'),
        findsOneWidget,
      );
      await tapText(tester, 'Continue to preferences →');
      expect(pathOf(router), AppRoutes.matchReview);
    },
  );
}
