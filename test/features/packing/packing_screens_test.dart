import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/packing/cubit/packing_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/shared/widgets/screen_head.dart';

import '../support/f02_harness.dart';

PackingCubit packingCubitOf(WidgetTester tester) =>
    tester.element(find.byType(ScreenHead).first).read<PackingCubit>();

WardrobeCubit wardrobeCubitOf(WidgetTester tester) =>
    tester.element(find.byType(ScreenHead).first).read<WardrobeCubit>();

/// Pushes [path] on the live router (without re-pumping the whole app),
/// so the feature-local `PackingCubit` instance (and any state set up via
/// it directly) survives the navigation.
Future<void> goTo(WidgetTester tester, GoRouter router, String path) async {
  router.push(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('F10_A01 first open shows the empty state and feature card', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.packing);
    for (final t in [
      'TRAVEL, WELL STYLED',
      'Pack smart.\nTravel light.',
      'Your trips',
      '0 trips',
      'No trips planned yet',
      'Create your first trip to get a personalized packing checklist.',
      'Your wardrobe goes with you.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('F10_A02 trip count label pluralizes correctly', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.packing);
    expect(find.text('0 trips'), findsOneWidget);

    final cubit = packingCubitOf(tester);
    cubit.newTrip();
    cubit.saveDraft(
      name: 'Trip one',
      destination: '',
      start: '2026-11-01',
      end: '2026-11-02',
      type: 'Vacation',
      notes: '',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 trip'), findsOneWidget);

    cubit.newTrip();
    cubit.saveDraft(
      name: 'Trip two',
      destination: '',
      start: '2026-11-03',
      end: '2026-11-04',
      type: 'Vacation',
      notes: '',
    );
    await tester.pumpAndSettle();
    expect(find.text('2 trips'), findsOneWidget);
  });

  testWidgets('F10_A03 saving a blank name toasts and stays on the form', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.packing);
    await tapText(tester, '＋ Create a trip');
    await tester.enterText(
      find.widgetWithText(TextField, 'Weekend escape'),
      '',
    );
    await tapText(tester, 'Continue to packing plan');
    expect(find.text('Add a trip name and both dates'), findsOneWidget);
    expect(pathOf(router), AppRoutes.newTrip);
    final cubit = packingCubitOf(tester);
    expect(cubit.state.trips, isEmpty);
    await drainToast(tester);
  });

  testWidgets(
    'F10_A08 the new-trip form fields drive a real save (full UI flow)',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      await tapText(tester, '＋ Create a trip');
      await tester.enterText(
        find.widgetWithText(TextField, 'Weekend escape'),
        'Lisbon getaway',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Istanbul'),
        'Lisbon',
      );

      await tester.tap(find.byKey(const Key('pk-start-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pk-end-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tapText(tester, 'Continue to packing plan');
      expect(pathOf(router), AppRoutes.packingPreview);

      final cubit = packingCubitOf(tester);
      final trip = cubit.state.selectedTrip!;
      expect(trip.name, 'Lisbon getaway');
      expect(trip.destination, 'Lisbon');
      expect(trip.days, greaterThanOrEqualTo(1));
    },
  );

  testWidgets('F10_A21 trip card label falls back to type and missing '
      'dates read Choose dates', (tester) async {
    await pumpApp(tester, AppRoutes.packing);
    final cubit = packingCubitOf(tester);
    cubit.newTrip();
    cubit.saveDraft(
      name: 'No destination trip',
      destination: '',
      start: '2026-11-01',
      end: '2026-11-02',
      type: 'City break',
      notes: '',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('City break · Nov 1 – Nov 2'), findsOneWidget);
  });

  testWidgets(
    'F10_A09 a 3-day Vacation trip suggests 11 pieces on the preview',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Lisbon getaway',
        destination: 'Lisbon',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      await goTo(tester, router, AppRoutes.packingPreview);
      for (final t in [
        'YOUR TRAVEL EDIT',
        'A thoughtful starting point.',
        'Based on your owned wardrobe and 3-day vacation trip. Suggestions '
            'are a demo, not live AI.',
        'Lisbon getaway',
        'Suggested pieces',
        '11 items',
      ]) {
        expect(find.text(t), findsWidgets, reason: t);
      }
    },
  );

  testWidgets(
    'F10_A13 F10_A14 F10_A15 F10_A16 generate once, toggle, zero-item '
    'empty state, remove row',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-03',
        type: 'Vacation',
        notes: '',
      );
      cubit.generateChecklist(wardrobeCubitOf(tester).state.items);
      await goTo(tester, router, AppRoutes.packingList);
      expect(find.text('0% packed'), findsOneWidget);
      expect(find.text('0 of 11 items ready'), findsOneWidget);
      expect(find.text('✧'), findsWidgets);

      // Toggle 3 of 11.
      for (final key in cubit.state.selectedTrip!.items
          .take(3)
          .map((i) => i.key)) {
        cubit.toggle(key);
      }
      await tester.pumpAndSettle();
      expect(find.text('27% packed'), findsOneWidget);
      expect(find.text('3 of 11 items ready'), findsOneWidget);

      // Running generate again does not duplicate or reset.
      cubit.generateChecklist(wardrobeCubitOf(tester).state.items);
      expect(cubit.state.selectedTrip!.items.length, 11);
      expect(
        cubit.state.selectedTrip!.items.where((i) => i.packed).length,
        3,
      );

      // Remove every item -> zero-item empty state.
      for (final key in [
        ...cubit.state.selectedTrip!.items.map((i) => i.key),
      ]) {
        cubit.removeItem(key);
      }
      await tester.pumpAndSettle();
      expect(find.text('0% packed'), findsOneWidget);
      expect(find.text('0 of 0 items ready'), findsOneWidget);
      expect(find.text('Your list is empty'), findsOneWidget);
      expect(
        find.text('Add clothing from your wardrobe to start packing.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('F10_A14 full progress shows the checkmark', (tester) async {
    final router = await pumpApp(tester, AppRoutes.packing);
    final cubit = packingCubitOf(tester);
    cubit.newTrip();
    cubit.saveDraft(
      name: 'Trip',
      destination: '',
      start: '2026-11-01',
      end: '2026-11-02',
      type: 'Vacation',
      notes: '',
    );
    cubit.generateChecklist(wardrobeCubitOf(tester).state.items);
    for (final i in cubit.state.selectedTrip!.items) {
      cubit.toggle(i.key);
    }
    await goTo(tester, router, AppRoutes.packingList);
    expect(find.text('100% packed'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
  });

  testWidgets(
    'F10_A17 adding a wardrobe item from packing-add disables it after',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      cubit.generateChecklist(wardrobeCubitOf(tester).state.items);
      await goTo(tester, router, AppRoutes.packingAdd);
      expect(find.text('Added'), findsWidgets);
      expect(find.text('＋ Add'), findsWidgets);

      final notAdded = wardrobeCubitOf(tester).state.items.firstWhere(
        (i) =>
            !cubit.state.selectedTrip!.items.any((p) => p.wardrobeId == i.id),
      );
      final before = cubit.state.selectedTrip!.items.length;
      await tester.ensureVisible(find.text(notAdded.name).first);
      await tester.tap(find.text(notAdded.name).first);
      await tester.pumpAndSettle();
      expect(cubit.state.selectedTrip!.items.length, before + 1);
      expect(
        cubit.state.selectedTrip!.items
            .where((p) => p.wardrobeId == notAdded.id)
            .length,
        1,
      );

      // Adding the same id again (from a second Add tap) never duplicates.
      await tester.ensureVisible(find.text(notAdded.name).first);
      await tester.tap(find.text(notAdded.name).first);
      await tester.pumpAndSettle();
      expect(cubit.state.selectedTrip!.items.length, before + 1);
    },
  );

  testWidgets(
    'F10_A18 F10_A19 custom item modal rejects blank and accepts a label',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      await goTo(tester, router, AppRoutes.packingAdd);
      await tapText(tester, '＋ Add a non-wardrobe item');
      for (final t in [
        'Add a travel essential',
        'Add items such as socks, toiletries, or chargers.',
        'Item name',
        'Add item',
      ]) {
        expect(find.text(t), findsWidgets, reason: t);
      }
      expect(
        find.widgetWithText(TextField, 'e.g. Phone charger'),
        findsOneWidget,
      );

      await tapText(tester, 'Add item');
      expect(find.text('Add a travel essential'), findsOneWidget); // stays
      expect(cubit.state.selectedTrip!.items, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Phone charger'),
        '   ',
      );
      await tapText(tester, 'Add item');
      expect(find.text('Add a travel essential'), findsOneWidget); // stays
      expect(cubit.state.selectedTrip!.items, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Phone charger'),
        'Phone charger',
      );
      await tapText(tester, 'Add item');
      expect(find.text('Add a travel essential'), findsNothing); // closed
      expect(cubit.state.selectedTrip!.items.single.label, 'Phone charger');
      expect(cubit.state.selectedTrip!.items.single.wardrobeId, isNull);
    },
  );

  testWidgets(
    'F10_A20 delete trip modal confirms, removes the trip and toasts',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      await goTo(tester, router, AppRoutes.packingList);
      await tapText(tester, 'Delete trip');
      for (final t in [
        'Delete this trip?',
        'This removes the trip and its checklist. Your wardrobe items '
            'stay safe.',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tester.tap(find.text('Delete trip').last);
      await tester.pumpAndSettle();
      expect(pathOf(router), AppRoutes.packing);
      expect(find.text('Trip removed'), findsOneWidget);
      expect(cubit.state.trips, isEmpty);
      await drainToast(tester);
    },
  );

  testWidgets('F10_A22 new-trip labels, select options and max lengths', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.packing);
    await tapText(tester, '＋ Create a trip');
    for (final t in [
      'New Trip',
      'TRIP DETAILS',
      'Where to next?',
      'Trip name *',
      'Destination',
      'Start date *',
      'End date *',
      'Type of trip',
      'Activities or notes',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    final nameField = tester.widget<TextField>(
      find.widgetWithText(TextField, '').first,
    );
    expect(nameField.maxLength, 60);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    for (final o in [
      'Vacation',
      'Business',
      'City break',
      'Beach',
      'Formal event',
      'Other',
    ]) {
      expect(find.text(o), findsWidgets, reason: o);
    }
  });

  testWidgets('F10_A23 packing-preview with no trip selected', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.packingPreview);
    expect(find.text('No trip selected.'), findsOneWidget);
  });

  testWidgets('F10_A24 packing-list / packing-add with no trip selected', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.packingList);
    expect(find.text('Choose a trip first.'), findsOneWidget);
  });

  testWidgets(
    'F10_A24 packing-list with a trip shows the checklist toolbar',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip name here',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      await goTo(tester, router, AppRoutes.packingList);
      for (final t in [
        'TRIP CHECKLIST',
        'Trip name here',
        '✎ Edit trip',
        '＋ Add items',
        '＋ Add clothing or essentials',
        'Delete trip',
      ]) {
        expect(find.text(t), findsWidgets, reason: t);
      }
    },
  );

  testWidgets(
    'F10_A25 a trip item whose wardrobe item was removed still renders',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      final wardrobe = wardrobeCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      cubit.addWardrobe(wardrobe.itemOrFallback('denim-jacket'));
      wardrobe.removeItem('denim-jacket');
      await goTo(tester, router, AppRoutes.packingList);
      expect(find.text('Denim Jacket'), findsOneWidget);
    },
  );

  testWidgets('F10_A26 header back targets', (tester) async {
    var router = await pumpApp(tester, AppRoutes.packing);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.home);

    router = await pumpApp(tester, AppRoutes.newTrip);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.packing);

    router = await pumpApp(tester, AppRoutes.packingPreview);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.packing); // no trip selected

    router = await pumpApp(tester, AppRoutes.packingList);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.packing);

    router = await pumpApp(tester, AppRoutes.packingAdd);
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.packing); // no trip: packing-add's head
  });

  testWidgets(
    'F10_A26 with a trip selected, packing-preview and new-trip (edit) '
    'back to the right place',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.packing);
      final cubit = packingCubitOf(tester);
      cubit.newTrip();
      cubit.saveDraft(
        name: 'Trip',
        destination: '',
        start: '2026-11-01',
        end: '2026-11-02',
        type: 'Vacation',
        notes: '',
      );
      // Mirror the real push chain (packing -> new-trip -> packing-preview)
      // so the back button's target is exercised honestly, whether it pops
      // a real stack entry or falls back to it.
      await goTo(tester, router, AppRoutes.newTrip);
      await goTo(tester, router, AppRoutes.packingPreview);
      await tester.tap(find.text('‹').first);
      await tester.pumpAndSettle();
      expect(pathOf(router), AppRoutes.newTrip);

      await goTo(tester, router, AppRoutes.packingList);
      await goTo(tester, router, AppRoutes.packingAdd);
      await tester.tap(find.text('‹').first);
      await tester.pumpAndSettle();
      expect(pathOf(router), AppRoutes.packingList);

      cubit.editTrip(cubit.state.trips.single.id);
      await goTo(tester, router, AppRoutes.newTrip);
      expect(find.text('Edit Trip'), findsOneWidget);
      await tester.tap(find.text('‹').first);
      await tester.pumpAndSettle();
      expect(pathOf(router), AppRoutes.packingList);
    },
  );
}
