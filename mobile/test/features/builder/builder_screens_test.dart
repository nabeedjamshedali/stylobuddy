import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/builder/cubit/builder_cubit.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';

import '../support/f02_harness.dart';

T cubitOf<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<T>();

void main() {
  testWidgets('test_F07_A09_builder_intro_copy_and_headings', (tester) async {
    await pumpApp(tester, AppRoutes.builder);
    for (final t in [
      'Build Your Outfit',
      'YOUR PERSONAL LOOK',
      'Put your pieces together.',
      'Choose items from your wardrobe. Watch your look come together as '
          'you select.',
      'Live outfit preview',
      'Choose from your wardrobe',
      '23 pieces',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('test_F07_A09_edit_mode_shows_edit_heading', (tester) async {
    await pumpApp(tester, AppRoutes.builder);
    final builder = cubitOf<BuilderCubit>(tester);
    builder.start(editId: 1);
    await tester.pumpAndSettle();
    expect(find.text('Edit Your Outfit'), findsOneWidget);
    expect(find.text('Build Your Outfit'), findsNothing);
  });

  testWidgets(
    'test_F07_A10_preview_counts_and_copy_update_as_items_are_picked',
    (tester) async {
      await pumpApp(tester, AppRoutes.builder);
      expect(find.text('0 items'), findsOneWidget);
      expect(find.text('Your look starts here'), findsOneWidget);
      expect(
        find.text('Select clothing below to build an outfit.'),
        findsOneWidget,
      );
      expect(find.text('Preview 0 items →'), findsOneWidget);
      // Disabled: tapping it leaves the builder in place.
      final router = await pumpApp(tester, AppRoutes.builder);
      await tapText(tester, 'Preview 0 items →');
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.builder,
      );

      await tapText(tester, 'White Oxford Shirt');
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Preview 1 item →'), findsOneWidget);

      await tapText(tester, 'Black Shirt');
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('Preview 2 items →'), findsOneWidget);
    },
  );

  testWidgets(
    'test_F07_A11_tile_mark_toggles_and_category_chips_filter',
    (tester) async {
      await pumpApp(tester, AppRoutes.builder);
      expect(find.text('+'), findsWidgets);
      expect(find.text('✓'), findsNothing);

      await tapText(tester, 'White Oxford Shirt');
      expect(find.text('✓'), findsOneWidget);

      await tapText(tester, 'Shoes');
      for (final shoe in [
        'White Sneakers',
        'Brown Loafers',
        'Black Boots',
        'Black Heels',
      ]) {
        expect(find.text(shoe), findsOneWidget, reason: shoe);
      }
      expect(find.text('White Oxford Shirt'), findsNothing);
    },
  );

  testWidgets(
    'test_F07_A12_live_preview_shows_at_most_six_with_remove_and_all_as_tags',
    (tester) async {
      await pumpApp(tester, AppRoutes.builder);
      final names = [
        'White Oxford Shirt',
        'Black Shirt',
        'Blue Denim Shirt',
        'Cream Blouse',
        'Navy Chinos',
        'Beige Chinos',
        'Black Jeans',
      ];
      for (final name in names) {
        await tapText(tester, name);
      }
      expect(find.text('7 items'), findsOneWidget);
      // Six remove buttons in the composition grid (bare '×').
      expect(find.text('×'), findsNWidgets(6));
      // All seven picked pieces appear as removable tags.
      for (final name in names) {
        expect(find.text('$name ×'), findsOneWidget, reason: name);
      }
    },
  );

  testWidgets(
    'test_F07_A13_manual_preview_copy_summary_and_form',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.builder);
      await tapText(tester, 'White Oxford Shirt');
      await tapText(tester, 'Preview 1 item →');
      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          AppRoutes.manualPreview);

      for (final t in [
        'Your Custom Outfit',
        'YOUR OWN STYLE',
        'Looks good together.',
        'Review your selections, name your outfit and save it to your '
            'collection.',
        'Pieces in this outfit',
        'White Oxford Shirt',
        'Change',
        'Outfit name',
        'My custom look',
        'Best for',
      ]) {
        expect(find.text(t), findsWidgets, reason: t);
      }

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      for (final occasion in [
        'Everyday',
        'Office',
        'Casual',
        'Party',
        'Wedding',
        'Date Night',
        'Vacation',
      ]) {
        expect(find.text(occasion), findsWidgets, reason: occasion);
      }
    },
  );

  testWidgets(
    'test_F07_A14_primary_button_label_and_change_items_keeps_draft',
    (tester) async {
      var router = await pumpApp(tester, AppRoutes.builder);
      var builder = cubitOf<BuilderCubit>(tester);
      builder.toggle('white-shirt');
      await tester.pumpAndSettle();
      await tapText(tester, 'Preview 1 item →');
      expect(find.text('Save to My Looks'), findsOneWidget);
      expect(find.text('Save Changes'), findsNothing);

      await tester.enterText(find.byType(TextField), 'My Friday look');
      await tester.pumpAndSettle();
      await tapText(tester, 'Change Items');
      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          AppRoutes.builder);
      expect(builder.state.name, 'My Friday look');

      router = await pumpApp(tester, AppRoutes.builder);
      builder = cubitOf<BuilderCubit>(tester);
      builder.start(editId: 1);
      await tester.pumpAndSettle();
      await tapText(tester, 'Preview 4 items →');
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Save to My Looks'), findsNothing);
    },
  );

  testWidgets('test_F07_A15_manual_preview_with_no_pieces', (tester) async {
    await pumpApp(tester, AppRoutes.manualPreview);
    expect(find.text('No garments chosen yet'), findsOneWidget);
  });

  testWidgets('test_F07_A16_name_field_accepts_at_most_60_chars', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.manualPreview);
    await tester.enterText(find.byType(TextField), 'a' * 70);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 60);
  });

  testWidgets(
    'test_F07_A17_editing_outfit_with_deleted_item_shows_fallback',
    (tester) async {
      await pumpApp(tester, AppRoutes.builder);
      final wardrobe = cubitOf<WardrobeCubit>(tester);
      final builder = cubitOf<BuilderCubit>(tester);
      wardrobe.removeItem('white-shirt');
      builder.start(editId: 1);
      await tester.pumpAndSettle();
      expect(find.text('Preview 4 items →'), findsOneWidget);
      await tapText(tester, 'Preview 4 items →');
      expect(find.text('white shirt'), findsWidgets);

      await tapText(tester, 'Save Changes');
      await drainToast(tester);
      final outfits = cubitOf<OutfitsCubit>(tester);
      expect(outfits.byId(1), isNotNull);
    },
  );

  testWidgets('test_F07_A18_header_back_targets', (tester) async {
    var router = await pumpApp(tester, AppRoutes.builder);
    await tapText(tester, '‹');
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.wardrobe);

    router = await pumpApp(tester, AppRoutes.wardrobe);
    await tapText(tester, 'Build outfit ↗');
    await tapText(tester, '‹');
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.wardrobe);

    router = await pumpApp(tester, AppRoutes.builder);
    cubitOf<BuilderCubit>(tester).toggle('white-shirt');
    await tester.pumpAndSettle();
    await tapText(tester, 'Preview 1 item →');
    await tapText(tester, '‹');
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        AppRoutes.builder);
  });
}
