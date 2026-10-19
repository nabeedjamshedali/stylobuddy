import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/saved/cubit/saved_view_cubit.dart';
import 'package:stylobuddy/features/saved/widgets/sl_search_field.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/shared/models/outfit.dart';

import '../support/f02_harness.dart';

T cubitOf<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<T>();

/// [SavedViewCubit] is provided locally (nested under the saved routes'
/// `ShellRoute`), below the app shell's `Scaffold` rather than above it, so
/// it must be read from a widget inside that subtree (only present while a
/// `/saved` screen is on top).
SavedViewCubit savedViewCubitOf(WidgetTester tester) =>
    tester.element(find.byType(SlSearchField)).read<SavedViewCubit>();

String? _hintOf(WidgetTester tester) =>
    tester.widget<SlSearchField>(find.byType(SlSearchField)).placeholder;

void main() {
  testWidgets('F08_A01 saved renders the archive header and stats', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.saved);
    for (final t in [
      'YOUR STYLE ARCHIVE',
      'My Looks.',
      'Everything you love wearing, in one place.',
      'saved looks',
      'Saved outfits',
      'Wears logged',
      'Worn looks',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text('2'), findsWidgets); // total + saved outfits stat
    expect(find.text('0'), findsNWidgets(2)); // wears logged + worn looks
  });

  testWidgets('F08_A02 tabs switch the list and search placeholder', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.saved);
    final viewCubit = savedViewCubitOf(tester);
    expect(viewCubit.state.tab, 'Saved');
    expect(find.text('Saved collection'), findsOneWidget);
    expect(_hintOf(tester), 'Search your looks');

    await tapText(tester, 'Wear History');
    expect(viewCubit.state.tab, 'History');
    expect(find.text('Outfits you wore'), findsOneWidget);
    expect(_hintOf(tester), 'Search wear history');
  });

  testWidgets('F08_A03 switching tabs clears the search text', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final view = savedViewCubitOf(tester);
    view.setSearch('weekend');
    await tester.pumpAndSettle();
    expect(view.state.search, 'weekend');

    view.setTab('History');
    expect(view.state.search, '');
  });

  testWidgets('F08_A04 saved list cards show the per-outfit summary', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.saved);
    for (final t in [
      'Saved collection',
      '2 looks',
      'Everyday · 4 pieces',
      'Everyday Essential',
      '0 times worn',
      'Casual · 4 pieces',
      'Modern Weekend',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(find.text('View look →'), findsNWidgets(2));
    await tapText(tester, 'Everyday Essential');
    expect(pathOf(router), startsWith(AppRoutes.savedDetailPath));
    expect(find.text('Outfit Details'), findsOneWidget);
  });

  testWidgets('F08_A05 search filters by name, occasion and item name', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.saved);
    final view = savedViewCubitOf(tester);

    view.setSearch('weekend');
    await tester.pumpAndSettle();
    expect(find.text('Modern Weekend'), findsOneWidget);
    expect(find.text('Everyday Essential'), findsNothing);
    expect(find.text('1 looks'), findsOneWidget);

    view.setSearch('everyday');
    await tester.pumpAndSettle();
    expect(find.text('Everyday Essential'), findsOneWidget);

    view.setSearch('loafers');
    await tester.pumpAndSettle();
    expect(find.text('Modern Weekend'), findsOneWidget);
    expect(find.text('Everyday Essential'), findsNothing);

    view.setSearch('  CASUAL  ');
    await tester.pumpAndSettle();
    expect(find.text('Modern Weekend'), findsOneWidget);
    expect(find.text('Everyday Essential'), findsNothing);
    expect(find.text('1 looks'), findsOneWidget);

    // Case-insensitive and trimmed: '  OFFICE  ' behaves like 'office'.
    view.setSearch('office');
    await tester.pumpAndSettle();
    final lowercase = find.text('No matching outfits');
    expect(lowercase, findsOneWidget);
    view.setSearch('  OFFICE  ');
    await tester.pumpAndSettle();
    expect(find.text('No matching outfits'), findsOneWidget);
  });

  testWidgets('F08_A06 empty search shows all; non-matching search shows '
      'the empty state', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final view = savedViewCubitOf(tester);
    view.setSearch('');
    await tester.pumpAndSettle();
    expect(find.text('Everyday Essential'), findsOneWidget);
    expect(find.text('Modern Weekend'), findsOneWidget);

    view.setSearch('zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching outfits'), findsOneWidget);
    expect(find.text('Try a different search.'), findsOneWidget);
  });

  testWidgets('F08_A07 zero outfits and no search shows the start-here '
      'empty state', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.delete(1);
    outfits.delete(2);
    await tester.pumpAndSettle();
    expect(find.text('Your looks start here'), findsOneWidget);
    expect(
      find.text(
        'Save an AI recommendation or build your own outfit to begin '
        'your collection.',
      ),
      findsOneWidget,
    );
    final router = await pumpApp(tester, AppRoutes.saved);
    cubitOf<OutfitsCubit>(tester)
      ..delete(1)
      ..delete(2);
    await tester.pumpAndSettle();
    await tapText(tester, 'Explore AI Stylist');
    expect(pathOf(router), AppRoutes.stylist);
  });

  testWidgets('F08_A08 wear history empty states', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final view = savedViewCubitOf(tester);
    view.setTab('History');
    await tester.pumpAndSettle();
    expect(find.text('Your outfit diary starts here'), findsOneWidget);
    expect(
      find.text(
        'Open a saved look and tap “Mark as Worn” to build your personal '
        'style history.',
      ),
      findsOneWidget,
    );
    await tapText(tester, 'Browse saved looks');
    expect(savedViewCubitOf(tester).state.tab, 'Saved');

    savedViewCubitOf(tester).setTab('History');
    savedViewCubitOf(tester).setSearch('zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching entries'), findsOneWidget);
  });

  testWidgets('F08_A09 wear history entries render newest first and open '
      'wear-detail', (tester) async {
    final router = await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    outfits.logWear(2);
    await tester.pumpAndSettle();
    savedViewCubitOf(tester).setTab('History');
    await tester.pumpAndSettle();
    expect(find.text('Outfits you wore'), findsOneWidget);
    expect(find.text('2 entries'), findsOneWidget);
    for (final t in [
      'Everyday Essential',
      '4 pieces · Everyday',
      'Modern Weekend',
      '4 pieces · Casual',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    await tapText(tester, 'Modern Weekend');
    expect(pathOf(router), startsWith(AppRoutes.wearDetailPath));
  });

  testWidgets('F08_A10 footer buttons navigate', (tester) async {
    var router = await pumpApp(tester, AppRoutes.saved);
    await tapText(tester, '＋ Create a look');
    expect(pathOf(router), AppRoutes.builder);

    router = await pumpApp(tester, AppRoutes.saved);
    await tapText(tester, '✧ Get AI recommendations');
    expect(pathOf(router), AppRoutes.stylist);
  });

  testWidgets('F08_A11 saved-detail renders outfit 1 details', (tester) async {
    await pumpApp(tester, AppRoutes.savedDetail(1));
    expect(find.textContaining('THE STYLE NOTE'), findsOneWidget);
    for (final t in [
      'Outfit Details',
      'SAVED / EVERYDAY',
      'Everyday Essential',
      'An outfit made from 4 pieces in your wardrobe.',
      'Everyday',
      '0 wears logged',
      'Pieces in this look',
      '4 ITEMS',
      'White Oxford Shirt',
      'Shirts · White',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    expect(
      find.textContaining('A crisp oxford creates structure'),
      findsOneWidget,
    );
  });

  testWidgets('F08_A12 style note is absent when why is empty', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    final created = outfits.upsertManual(
      name: 'No Note',
      items: ['white-tee'],
      occasion: 'Everyday',
    );
    // upsertManual always sets a why; emulate an outfit with an empty one.
    outfits.delete(created.id);
    final fresh = outfits.saveOrFind(
      const Outfit(
        id: 0,
        name: 'No Note',
        occasion: 'Everyday',
        items: ['white-tee'],
        why: '',
      ),
    );
    final router = await pumpApp(tester, AppRoutes.savedDetail(fresh.id));
    expect(find.textContaining('THE STYLE NOTE'), findsNothing);
    expect(pathOf(router), startsWith(AppRoutes.savedDetailPath));
  });

  testWidgets('F08_A13 wear note text for 0, 1 and 2 wears', (tester) async {
    await pumpApp(tester, AppRoutes.savedDetail(1));
    expect(
      find.text('You haven’t logged a wear for this look yet.'),
      findsOneWidget,
    );

    final router = await pumpApp(tester, AppRoutes.savedDetail(1));
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    await tester.pumpAndSettle();
    expect(find.text('You have worn this look 1 time.'), findsOneWidget);

    outfits.logWear(1);
    await tester.pumpAndSettle();
    expect(find.text('You have worn this look 2 times.'), findsOneWidget);
    expect(pathOf(router), startsWith(AppRoutes.savedDetailPath));
  });

  testWidgets('F08_A14 Mark as Worn Today records a wear', (tester) async {
    await pumpApp(tester, AppRoutes.savedDetail(1));
    final outfits = cubitOf<OutfitsCubit>(tester);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    final before = wardrobe.itemOrFallback('white-shirt').wears;

    await tapText(tester, '✓ Mark as Worn Today');
    expect(find.text('Outfit wear recorded'), findsOneWidget);
    expect(outfits.byId(1)!.worn, 1);
    expect(wardrobe.itemOrFallback('white-shirt').wears, before + 1);
    expect(outfits.state.wearLog.length, 1);
    expect(find.text('You have worn this look 1 time.'), findsOneWidget);
    expect(find.text('1 wears logged'), findsOneWidget);
    await drainToast(tester);

    await pumpApp(tester, AppRoutes.saved);
    expect(find.text('1'), findsWidgets); // Wears logged stat
  });

  testWidgets('F08_A15 See all history opens saved with History tab active', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.savedDetail(1));
    await tapText(tester, 'See all history →');
    expect(pathOf(router), AppRoutes.saved);
    expect(savedViewCubitOf(tester).state.tab, 'History');
  });

  testWidgets('F08_A16 Plan outfit schedules and Edit look opens the '
      'builder', (tester) async {
    var router = await pumpApp(tester, AppRoutes.savedDetail(1));
    await tapText(tester, 'Plan outfit');
    expect(pathOf(router), AppRoutes.calendarDate);
    for (final t in ['Everyday Essential', '4 items in your wardrobe']) {
      expect(find.text(t), findsWidgets, reason: t);
    }

    router = await pumpApp(tester, AppRoutes.savedDetail(1));
    await tapText(tester, 'Edit look');
    expect(pathOf(router), AppRoutes.builder);
    expect(find.text('Edit Your Outfit'), findsOneWidget);
  });

  testWidgets('F08_A17 Share copies to clipboard, or falls back to a modal', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.savedDetail(1));
    final calls = <MethodCall>[];
    var fail = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        if (call.method == 'Clipboard.setData' && fail) {
          throw PlatformException(code: 'denied');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tapText(tester, 'Share');
    expect(calls.any((c) => c.method == 'Clipboard.setData'), isTrue);
    expect(find.text('Outfit description copied'), findsOneWidget);
    await drainToast(tester);

    fail = true;
    await tapText(tester, 'Share');
    expect(find.text('Share your outfit'), findsOneWidget);
    expect(
      find.text('Copy this look description and send it to a friend.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Everyday Essential (Everyday) —'),
      findsOneWidget,
    );
    await tapText(tester, 'Done');
    expect(find.text('Share your outfit'), findsNothing);
  });

  testWidgets('F08_A18 remove-saved modal copy and Keep outfit closes it', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.savedDetail(1));
    await tapText(tester, 'Remove from saved looks');
    for (final t in [
      'Remove saved outfit?',
      'This look will be removed from Saved. Recorded wear history will '
          'remain for your style insights.',
      'Remove outfit',
      'Keep outfit',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    await tapText(tester, 'Keep outfit');
    expect(find.text('Remove saved outfit?'), findsNothing);
    expect(cubitOf<OutfitsCubit>(tester).byId(1), isNotNull);
  });

  testWidgets('F08_A19 Remove outfit deletes it, lands on /saved and keeps '
      'wear history', (tester) async {
    final router = await pumpApp(tester, AppRoutes.savedDetail(1));
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    await tester.pumpAndSettle();

    await tapText(tester, 'Remove from saved looks');
    await tapText(tester, 'Remove outfit');
    expect(pathOf(router), AppRoutes.saved);
    expect(find.text('Look removed'), findsOneWidget);
    expect(outfits.byId(1), isNull);
    expect(outfits.wearEvents(outfitId: 1).length, 1);
    await drainToast(tester);
  });

  testWidgets('F08_A20 saved-detail for an unknown id shows the missing '
      'state', (tester) async {
    await pumpApp(tester, AppRoutes.savedDetail(999));
    expect(find.text('Saved Outfit'), findsOneWidget);
    expect(find.text('This outfit is no longer saved.'), findsOneWidget);
    final router = await pumpApp(tester, AppRoutes.savedDetail(999));
    await tapText(tester, 'Back to my looks');
    expect(pathOf(router), AppRoutes.saved);
  });

  testWidgets('F08_A21 wear-detail renders the journal entry', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    final eventId = outfits.state.wearLog.first.id;
    final timestamp = outfits.state.wearLog.first.timestamp;
    await pumpApp(tester, AppRoutes.wearDetail(eventId, outfitId: 1));
    for (final t in [
      'Wear Journal',
      'YOUR OUTFIT DIARY',
      'Everyday Essential · Everyday',
      'Worn pieces',
      '4 ITEMS',
      'View saved look',
      'Remove this wear entry',
      DateFormat('EEEE, MMMM d').format(timestamp),
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
  });

  testWidgets('F08_A22 unknown event id falls back to the outfit\'s first '
      'event; no match shows unavailable', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    await pumpApp(tester, AppRoutes.wearDetail(99999, outfitId: 1));
    expect(find.text('Wear Journal'), findsOneWidget);

    await pumpApp(tester, AppRoutes.wearDetail(99999));
    expect(find.text('Wear History'), findsOneWidget);
    expect(find.text('Wear entry unavailable'), findsOneWidget);
  });

  testWidgets('F08_A23 remove-wear modal and confirming adjusts counts', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    outfits.logWear(1);
    final eventId = outfits.state.wearLog.first.id;
    // logWear's cross-feature call into WardrobeCubit.adjustWears happens
    // after the (fire-and-forget) repository Future resolves, not
    // synchronously inline (F16-A18) — flush the microtask queue before
    // reading the "before" baseline so it reflects the already-applied +1,
    // matching this test's original (pre-F16) assumption.
    await tester.pump(Duration.zero);
    final before = wardrobe.itemOrFallback('white-shirt').wears;

    await pumpApp(tester, AppRoutes.wearDetail(eventId, outfitId: 1));
    await tapText(tester, 'Remove this wear entry');
    expect(find.text('Remove wear entry?'), findsOneWidget);
    expect(find.text('This will update your wear counts.'), findsOneWidget);
    await tapText(tester, 'Remove entry');
    expect(find.text('Wear entry removed'), findsOneWidget);
    expect(outfits.byId(1)!.worn, 0);
    // removeWear's cross-feature call into WardrobeCubit.adjustWears
    // happens after the (fire-and-forget) repository Future resolves, not
    // synchronously inline (F16-A19) — flush the microtask queue before
    // asserting on it; this does not change what is asserted, only when.
    await tester.pump(Duration.zero);
    expect(wardrobe.itemOrFallback('white-shirt').wears, before - 1);
    await drainToast(tester);
  });

  testWidgets('F08_A23b removeWear never drops wears below zero', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.removeWear(123456); // no matching event: no-op, no crash
    expect(outfits.state.wearLog, isEmpty);
  });

  testWidgets('F08_A24 View saved look opens the outfit, or toasts when it '
      'was deleted', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    var outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    final eventId = outfits.state.wearLog.first.id;

    final router = await pumpApp(
      tester,
      AppRoutes.wearDetail(eventId, outfitId: 1),
    );
    await tapText(tester, 'View saved look');
    expect(pathOf(router), startsWith(AppRoutes.savedDetailPath));

    final router2 = await pumpApp(tester, AppRoutes.saved);
    outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(2);
    final event2 = outfits.state.wearLog.first.id;
    outfits.delete(2);
    await pumpApp(tester, AppRoutes.wearDetail(event2, outfitId: 2));
    await tapText(tester, 'View saved look');
    expect(find.text('Original outfit was removed'), findsOneWidget);
    expect(pathOf(router2), AppRoutes.saved);
    await drainToast(tester);
  });

  testWidgets('F08_A25 a wear event whose items were deleted renders '
      'fallback names without throwing', (tester) async {
    await pumpApp(tester, AppRoutes.saved);
    final outfits = cubitOf<OutfitsCubit>(tester);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    outfits.logWear(1);
    final eventId = outfits.state.wearLog.first.id;
    wardrobe.removeItem('white-shirt');

    await pumpApp(tester, AppRoutes.wearDetail(eventId, outfitId: 1));
    expect(find.text('Wear Journal'), findsOneWidget);
    expect(find.text('white shirt'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F08_A26 header back targets', (tester) async {
    var router = await pumpApp(tester, AppRoutes.savedDetail(1));
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.saved);

    final outfits = cubitOf<OutfitsCubit>(tester);
    outfits.logWear(1);
    final eventId = outfits.state.wearLog.first.id;
    router = await pumpApp(tester, AppRoutes.wearDetail(eventId, outfitId: 1));
    await tester.tap(find.text('‹').first);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.saved);
  });
}
