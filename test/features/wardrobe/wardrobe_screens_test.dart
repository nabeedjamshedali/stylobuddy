import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/import_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/shared/widgets/progress_bar.dart';

import '../support/f02_harness.dart';

T cubitOf<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<T>();

double progressValue(WidgetTester tester) =>
    tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value;

Future<void> enterSearch(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('F06_A01 wardrobe header and stats for the seed', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.wardrobe);
    for (final t in [
      'YOUR COLLECTION',
      'My Wardrobe',
      'Everything you own, beautifully organized.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('23'), findsOneWidget);
    expect(find.text('Pieces'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('Worn pieces'), findsOneWidget);
  });

  testWidgets('F06_A02 stats react to removing and adding items', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.wardrobe);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    wardrobe.removeItem('white-shirt'); // never worn (wears 0)
    await tester.pumpAndSettle();
    expect(find.text('22'), findsOneWidget);
    expect(find.text('18'), findsOneWidget); // worn count unaffected

    final base = wardrobe.itemOrFallback('black-shirt');
    wardrobe.addItems([
      base.copyWith(category: 'Jewelry').copyWith(name: 'Statement Ring'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget); // categories: 7 -> 8
  });

  testWidgets('F06_A03 action buttons and AI action navigate', (
    tester,
  ) async {
    var router = await pumpApp(tester, AppRoutes.wardrobe);
    await tapText(tester, '＋ Add clothing');
    expect(pathOf(router), AppRoutes.import);

    router = await pumpApp(tester, AppRoutes.wardrobe);
    await tapText(tester, 'Build outfit ↗');
    expect(pathOf(router), AppRoutes.builder);

    router = await pumpApp(tester, AppRoutes.wardrobe);
    await tapText(tester, 'Filter ☷');
    expect(pathOf(router), AppRoutes.filter);

    router = await pumpApp(tester, AppRoutes.wardrobe);
    expect(find.text('Find your best matches'), findsOneWidget);
    expect(
      find.text('Select wardrobe pieces and let AI style them.'),
      findsOneWidget,
    );
    await tapText(tester, 'Find your best matches');
    expect(pathOf(router), AppRoutes.matching);
  });

  testWidgets('F06_A04 category chips filter the grid and section header', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.wardrobe);
    await tapText(tester, 'Shoes');
    expect(find.text('Shoes'), findsWidgets);
    expect(find.text('4 items'), findsOneWidget);
    for (final shoe in [
      'White Sneakers',
      'Brown Loafers',
      'Black Boots',
      'Black Heels',
    ]) {
      expect(find.text(shoe), findsOneWidget, reason: shoe);
    }
    await tapText(tester, 'All');
    expect(find.text('All clothing'), findsOneWidget);
    expect(find.text('23 items'), findsOneWidget);
  });

  testWidgets('F06_A05 tile shows name/color/category and opens detail', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.wardrobe);
    expect(find.text('White Oxford Shirt'), findsOneWidget);
    expect(find.text('White · Shirts'), findsWidgets);
    await tapText(tester, 'White Oxford Shirt');
    expect(pathOf(router), AppRoutes.clothingPath);
    expect(find.text('Clothing Details'), findsOneWidget);
    expect(find.text('White Oxford Shirt'), findsOneWidget);
  });

  testWidgets('F06_A06 search is case-insensitive and narrows the grid', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.wardrobe);
    await enterSearch(tester, 'jean');
    expect(find.text('Black Jeans'), findsOneWidget);
    expect(find.text('Blue Jeans'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);

    await enterSearch(tester, 'JEAN');
    expect(find.text('Black Jeans'), findsOneWidget);
    expect(find.text('Blue Jeans'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
  });

  testWidgets('F06_A07 empty search shows all 23 items, no empty state', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.wardrobe);
    await enterSearch(tester, '');
    expect(find.text('23 items'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsNothing);
  });

  testWidgets('F06_A08 no-match search shows empty state with Clear search', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.wardrobe);
    await enterSearch(tester, 'zzz');
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(
      find.text('Try a different search, or clear the search field.'),
      findsOneWidget,
    );
    expect(find.text('Clear search'), findsOneWidget);
    await tapText(tester, 'Clear search');
    expect(find.text('23 items'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsNothing);
  });

  testWidgets('F06_A09 empty category (no search) offers Add clothing', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.wardrobe);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    wardrobe.removeItem('black-skirt'); // only Skirts item
    await tester.pumpAndSettle();
    await tapText(tester, 'Skirts');
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(
      find.text('This category is waiting for your first item.'),
      findsOneWidget,
    );
    await tapText(tester, 'Add clothing');
    expect(pathOf(router), AppRoutes.import);
  });

  testWidgets('F06_A10 filter screen sets filter and returns to wardrobe', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.wardrobe);
    await tapText(tester, 'Filter ☷');
    expect(find.text('Wardrobe Filters'), findsOneWidget);
    expect(
      find.text('Choose a category to narrow down the wardrobe.'),
      findsOneWidget,
    );
    for (final o in [
      'All',
      'Shirts',
      'Pants',
      'Shoes',
      'Dresses',
      'Skirts',
      'Outerwear',
      'Accessories',
    ]) {
      expect(find.text(o), findsWidgets, reason: o);
    }
    await tapText(tester, 'Pants');
    expect(pathOf(router), AppRoutes.wardrobe);
    expect(find.text('4 items'), findsOneWidget);
  });

  testWidgets('F06_A11 clothing detail renders white-shirt', (tester) async {
    await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    for (final t in [
      'Clothing Details',
      'IN MY WARDROBE',
      'Shirts',
      'White Oxford Shirt',
      'COLOR',
      'White',
      'OCCASION',
      'Office',
      'TIMES WORN',
      '0',
      'SEASON',
      'All season',
      'Style this piece',
      '✧ Find matching outfits',
      'Edit item details',
      'Remove from wardrobe',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  testWidgets('F06_A12 zero wears shows 0; unknown id uses fallback', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    expect(find.text('0'), findsOneWidget);

    await pumpApp(tester, AppRoutes.clothing('mystery-coat'));
    expect(find.text('mystery coat'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F06_A13 Find matching outfits selects, locks and navigates', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    final stylist = cubitOf<StylistCubit>(tester);
    await tapText(tester, '✧ Find matching outfits');
    expect(stylist.state.selected, ['white-shirt']);
    expect(stylist.state.locked, ['white-shirt']);
    expect(pathOf(router), AppRoutes.matchReview);
  });

  testWidgets('F06_A14 options menu offers edit and remove', (tester) async {
    final router = await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    await tapText(tester, '⋯');
    expect(find.text('Clothing options'), findsOneWidget);
    expect(find.text('Edit clothing details →'), findsOneWidget);
    expect(find.text('Remove this item →'), findsOneWidget);
    await tapText(tester, 'Edit clothing details →');
    expect(pathOf(router), AppRoutes.editItem);
  });

  testWidgets('F06_A14b Remove this item opens the remove dialog', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    await tapText(tester, '⋯');
    await tapText(tester, 'Remove this item →');
    expect(find.text('Remove clothing?'), findsOneWidget);
  });

  testWidgets('F06_A15 remove dialog copy and Cancel keeps the item', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    await tapText(tester, 'Remove from wardrobe');
    expect(find.text('Remove clothing?'), findsOneWidget);
    expect(
      find.text(
        'This item will be removed from your wardrobe. Saved looks '
        'that used it may need adjusting.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove item'), findsOneWidget);
    await tapText(tester, 'Cancel');
    expect(find.text('Remove clothing?'), findsNothing);
    expect(find.text('White Oxford Shirt'), findsOneWidget);
  });

  testWidgets('F06_A16 Remove item removes, navigates, toasts and drops count', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    await tapText(tester, 'Remove from wardrobe');
    await tapText(tester, 'Remove item');
    expect(pathOf(router), AppRoutes.wardrobe);
    expect(find.text('Item removed'), findsOneWidget);
    expect(wardrobe.state.items.any((i) => i.id == 'white-shirt'), isFalse);
    expect(find.text('22'), findsOneWidget);
    await drainToast(tester);

    // A saved outfit referencing the removed id still resolves via fallback.
    final fallback = wardrobe.itemOrFallback('white-shirt');
    expect(fallback.name, 'white shirt');
    expect(tester.takeException(), isNull);
  });

  testWidgets('F06_A17 edit-item renders prefilled fields', (tester) async {
    await pumpApp(tester, AppRoutes.editItemFor('white-shirt'));
    for (final t in [
      'Edit Item',
      'EDITING YOUR WARDROBE',
      'Clothing name',
      'Category',
      'Color',
      'Best for',
      'Season',
      'Save changes',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text('White Oxford Shirt'), findsWidgets);
  });

  testWidgets('F06_A18 blank / whitespace name toasts and leaves unchanged', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.editItemFor('white-shirt'));
    final wardrobe = cubitOf<WardrobeCubit>(tester);

    await tester.enterText(find.byType(TextField), '');
    await tapText(tester, 'Save changes');
    expect(find.text('Enter an item name'), findsOneWidget);
    expect(wardrobe.itemOrFallback('white-shirt').name, 'White Oxford Shirt');
    await drainToast(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tapText(tester, 'Save changes');
    expect(find.text('Enter an item name'), findsOneWidget);
    expect(wardrobe.itemOrFallback('white-shirt').name, 'White Oxford Shirt');
    await drainToast(tester);
  });

  testWidgets('F06_A19 valid save updates item, returns, toasts', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.clothing('white-shirt'));
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    await tapText(tester, 'Edit item details');
    await tester.enterText(find.byType(TextField), '  Test Shirt  ');
    await tapText(tester, 'Save changes');
    expect(find.text('Clothing updated'), findsOneWidget);
    expect(wardrobe.itemOrFallback('white-shirt').name, 'Test Shirt');
    expect(pathOf(router), AppRoutes.clothingPath);
    expect(find.text('Test Shirt'), findsWidgets);
    await drainToast(tester);
  });

  testWidgets('F06_A20 import intro copy', (tester) async {
    await pumpApp(tester, AppRoutes.import);
    for (final t in [
      'Add Clothing',
      '✧',
      'YOUR DIGITAL CLOSET',
      'Every great look starts here.',
      'Take a photo',
      'Capture one item with your camera',
      'Choose from gallery',
      'Add one or multiple pieces',
      'AI suggestions are editable before anything is saved.',
      'Prototype preview uses sample garment photos. No device camera '
          'or AI service is connected.',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  testWidgets('F06_A21 import-source labels camera vs gallery, default 3', (
    tester,
  ) async {
    var router = await pumpApp(tester, AppRoutes.import);
    await tapText(tester, 'Take a photo');
    expect(pathOf(router), AppRoutes.importSource);
    expect(find.text('CAMERA IMPORT'), findsOneWidget);
    expect(find.text('Choose Photos'), findsOneWidget);
    expect(find.text('Select your pieces'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text('6 items'), findsOneWidget);

    router = await pumpApp(tester, AppRoutes.import);
    await tapText(tester, 'Choose from gallery');
    expect(find.text('GALLERY IMPORT'), findsOneWidget);
  });

  testWidgets('F06_A22 review button label pluralizes by count', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.importSource);
    expect(find.text('Review 3 photos →'), findsOneWidget);
    await tapText(tester, '6 items');
    expect(find.text('Review 6 photos →'), findsOneWidget);
    await tapText(tester, '1 item');
    expect(find.text('Review 1 photo →'), findsOneWidget);
  });

  testWidgets('F06_A23 batch screen and drafts match the pool order', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    for (final t in [
      'Review Photos',
      'STEP 1 OF 3',
      'Ready to organize?',
      '3 items',
      'Ready for AI analysis',
      '✧ Analyze clothing',
      'AI processing is simulated in this prototype.',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    final drafts = cubitOf<ImportCubit>(tester).state.drafts;
    expect(drafts.map((d) => d.sourceId).toList(), [
      'cream-blouse',
      'denim-jacket',
      'tan-belt',
    ]);
  });

  testWidgets('F06_A24 analyzing auto-advances after 1150ms', (tester) async {
    final router = await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    // Plain tap + single pump: the analyzing screen has a repeating
    // spinner, so `pumpAndSettle` would otherwise flush the 1150 ms delay.
    await tester.tap(find.text('✧ Analyze clothing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(pathOf(router), AppRoutes.analyzing);
    expect(find.text('Analyzing Items'), findsOneWidget);
    expect(find.text('Preparing your pieces'), findsOneWidget);
    expect(
      find.text('Removing backgrounds and identifying clothing details...'),
      findsOneWidget,
    );
    expect(find.text('DEMO ANALYSIS'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.review);
  });

  testWidgets('F06_A24b leaving analyzing early cancels the auto-advance', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    await tester.tap(find.text('✧ Analyze clothing'));
    await tester.pump();
    expect(pathOf(router), AppRoutes.analyzing);
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.batch);
  });

  testWidgets('F06_A25 review of item 1 of 3 and the compare toggle', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    await tapText(tester, '✧ Analyze clothing');
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    expect(find.text('Review AI Suggestions'), findsOneWidget);
    expect(find.text('ITEM 1 OF 3'), findsOneWidget);
    expect(find.text('AI suggestion · editable'), findsOneWidget);
    expect(progressValue(tester), closeTo(1 / 3, 0.001));
    expect(find.text('CLEAN BACKGROUND · PREVIEW'), findsOneWidget);
    expect(find.text('Compare original image ↗'), findsOneWidget);
    await tapText(tester, 'Compare original image ↗');
    expect(find.text('ORIGINAL PHOTO'), findsOneWidget);
    expect(find.text('Show cleaned preview ↗'), findsOneWidget);
  });

  testWidgets('F06_A26 button label and progress change across items', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    await tapText(tester, '✧ Analyze clothing');
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    expect(find.text('Confirm & next item →'), findsOneWidget);
    await tapText(tester, 'Confirm & next item →');
    expect(find.text('ITEM 2 OF 3'), findsOneWidget);
    expect(progressValue(tester), closeTo(2 / 3, 0.001));
    expect(find.text('Confirm & next item →'), findsOneWidget);
    await tapText(tester, 'Confirm & next item →');
    expect(find.text('ITEM 3 OF 3'), findsOneWidget);
    expect(find.text('Save to my wardrobe →'), findsOneWidget);
  });

  testWidgets('F06_A27 blank name on review toasts and does not advance', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    await tapText(tester, '✧ Analyze clothing');
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tapText(tester, 'Confirm & next item →');
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('ITEM 1 OF 3'), findsOneWidget);
    await drainToast(tester);
  });

  testWidgets(
    'F06_A28 importing 3 items keeps edits, adds 3 items, navigates',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.importSource);
      final wardrobe = cubitOf<WardrobeCubit>(tester);
      expect(wardrobe.state.items.length, 23);
      await tapText(tester, 'Review 3 photos →');
      await tapText(tester, '✧ Analyze clothing');
      await tester.pump(const Duration(milliseconds: 1150));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Silk Blouse');
      await tapText(tester, 'Confirm & next item →');
      await tapText(tester, 'Confirm & next item →');
      await tapText(tester, 'Save to my wardrobe →');

      expect(pathOf(router), AppRoutes.addConfirm);
      expect(wardrobe.state.items.length, 26);
      final renamed = wardrobe.state.items.firstWhere(
        (i) => i.sourceId == 'cream-blouse',
      );
      expect(renamed.name, 'Silk Blouse');
      expect(renamed.imageId, 'cream-blouse');
    },
  );

  testWidgets('F06_A29 two consecutive imports produce distinct ids', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.importSource);
    final wardrobe = cubitOf<WardrobeCubit>(tester);

    for (var round = 0; round < 2; round++) {
      await tapText(tester, 'Review 3 photos →');
      await tapText(tester, '✧ Analyze clothing');
      await tester.pump(const Duration(milliseconds: 1150));
      await tester.pumpAndSettle();
      await tapText(tester, 'Confirm & next item →');
      await tapText(tester, 'Confirm & next item →');
      await tapText(tester, 'Save to my wardrobe →');
      router.go(AppRoutes.importSource);
      await tester.pumpAndSettle();
    }

    final newItems = wardrobe.state.items.where(
      (i) => i.id.startsWith('new-'),
    );
    final ids = newItems.map((i) => i.id).toSet();
    expect(newItems.length, 6);
    expect(ids.length, 6);
  });

  testWidgets('F06_A30 add-confirm copy for 3 and 1 piece', (tester) async {
    var router = await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, 'Review 3 photos →');
    await tapText(tester, '✧ Analyze clothing');
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    await tapText(tester, 'Confirm & next item →');
    await tapText(tester, 'Confirm & next item →');
    await tapText(tester, 'Save to my wardrobe →');
    expect(find.text('Import Complete'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
    expect(find.text('WARDROBE UPDATED'), findsOneWidget);
    expect(find.text('Looking good already.'), findsOneWidget);
    expect(
      find.text(
        '3 pieces have been added to your wardrobe. You can edit details '
        'or start creating new looks anytime.',
      ),
      findsOneWidget,
    );
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('New wardrobe items'), findsOneWidget);
    await tapText(tester, 'View my wardrobe');
    expect(pathOf(router), AppRoutes.wardrobe);

    router = await pumpApp(tester, AppRoutes.importSource);
    await tapText(tester, '1 item');
    await tapText(tester, 'Review 1 photo →');
    await tapText(tester, '✧ Analyze clothing');
    await tester.pump(const Duration(milliseconds: 1150));
    await tester.pumpAndSettle();
    await tapText(tester, 'Save to my wardrobe →');
    expect(
      find.text(
        '1 piece has been added to your wardrobe. You can edit details or '
        'start creating new looks anytime.',
      ),
      findsOneWidget,
    );
    expect(find.text('+1'), findsOneWidget);
    await tapText(tester, 'Add more clothing');
    expect(pathOf(router), AppRoutes.import);
  });

  testWidgets('F06_A31 review with no drafts renders the missing message', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.review);
    expect(find.text('No draft to review.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
