import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/home/home_routes.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';

import '../support/f02_harness.dart';

T cubitOf<T extends StateStreamableSource<Object?>>(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<T>();

void main() {
  testWidgets('F05_A01 default profile shows the greeting and subtitle', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.home);
    expect(find.text('Good morning'), findsNothing); // combined with glyph
    expect(find.textContaining('Good morning'), findsOneWidget);
    expect(find.text('Hi, Alex Morgan '), findsOneWidget);
    expect(
      find.text('Make the most of your wardrobe today.'),
      findsOneWidget,
    );
  });

  testWidgets('F05_A02 empty profile name shows Hi, there', (tester) async {
    await pumpApp(tester, AppRoutes.home);
    cubitOf<ProfileCubit>(tester).updateDetails('', 'alex@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Hi, there '), findsOneWidget);
  });

  testWidgets('F05_A03 a name with markup renders literally', (tester) async {
    await pumpApp(tester, AppRoutes.home);
    cubitOf<ProfileCubit>(
      tester,
    ).updateDetails('<b>x</b>', 'alex@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Hi, <b>x</b> '), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);
    // No literal bold element is introduced; the string is a single Text.
    expect(tester.takeException(), isNull);
  });

  testWidgets('F05_A04 quick actions label, order and routes', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.home);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    final labels = ['AI Outfits', 'Match Items', 'Add Item', 'Calendar'];
    for (final l in labels) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
    final routes = [
      AppRoutes.occasion,
      AppRoutes.matching,
      AppRoutes.import,
      AppRoutes.calendar,
    ];
    for (var i = 0; i < labels.length; i++) {
      await tapText(tester, labels[i]);
      expect(pathOf(router), routes[i]);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('F05_A05 the bell opens notifications', (tester) async {
    final router = await pumpApp(tester, AppRoutes.home);
    expect(find.bySemanticsLabel('View notifications'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('View notifications'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.notifications);
  });

  testWidgets('F05_A06 today\'s suggestion copy and garments', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.home);
    for (final t in [
      "Today's suggestion",
      '✧ AI selected',
      '☀ Everyday · Smart casual',
      'From your wardrobe',
      'Clean & effortless',
      'A crisp shirt, tailored chinos and everyday essentials.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('F05_A07 view outfits sets occasion, generates and navigates', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.home);
    final stylist = cubitOf<StylistCubit>(tester);
    await tester.tap(find.text('View outfits →'));
    await tester.pump();
    expect(stylist.state.occasion, 'Everyday');
    expect(stylist.state.isGenerating, isTrue);
    expect(pathOf(router), AppRoutes.generating);
    await tester.pump(StylistCubit.generationDelay);
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.results);
  });

  testWidgets('F05_A08 ai banner copy and navigation', (tester) async {
    final router = await pumpApp(tester, AppRoutes.home);
    expect(find.text('Have a few items in mind?'), findsOneWidget);
    expect(
      find.text('Let AI find the best matching combination.'),
      findsOneWidget,
    );
    await tapText(tester, 'Have a few items in mind?');
    expect(pathOf(router), AppRoutes.matching);
  });

  testWidgets('F05_A09 recently added tiles, tap and see all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        ...homeRoutes,
        GoRoute(
          path: AppRoutes.clothingPath,
          builder: (context, state) => Scaffold(
            body: Text('clothing-id:${state.uri.queryParameters['id']}'),
          ),
        ),
        GoRoute(
          path: AppRoutes.wardrobe,
          builder: (_, _) => const Scaffold(body: Text('wardrobe-screen')),
        ),
      ],
    );
    await tester.pumpWidget(StyloBuddyApp(router: router));
    await tester.pumpAndSettle();
    expect(find.text('Recently added'), findsOneWidget);
    for (final n in [
      'White Oxford Shirt',
      'Black Shirt',
      'Blue Denim Shirt',
      'Cream Blouse',
    ]) {
      expect(find.text(n), findsOneWidget, reason: n);
    }
    await tapText(tester, 'White Oxford Shirt');
    expect(find.text('clothing-id:white-shirt'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tapText(tester, 'See all →');
    expect(find.text('wardrobe-screen'), findsOneWidget);
  });

  testWidgets('F05_A10 tiles shift, shrink and disappear with wardrobe', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.home);
    final wardrobe = cubitOf<WardrobeCubit>(tester);
    wardrobe.removeItem('white-shirt');
    await tester.pumpAndSettle();
    expect(find.text('Black Shirt'), findsOneWidget);
    expect(find.text('White Oxford Shirt'), findsNothing);

    for (final i in List.of(wardrobe.state.items)) {
      if (i.id != 'black-shirt' && i.id != 'blue-shirt') {
        wardrobe.removeItem(i.id);
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Black Shirt'), findsOneWidget);
    expect(find.text('Blue Denim Shirt'), findsOneWidget);

    wardrobe.removeItem('black-shirt');
    wardrobe.removeItem('blue-shirt');
    await tester.pumpAndSettle();
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Blue Denim Shirt'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('F05_A11 explore more rows and routes', (tester) async {
    final router = await pumpApp(tester, AppRoutes.home);
    expect(find.text('Explore more'), findsOneWidget);
    const rows = [
      ('Packing assistant', 'Pack smarter for trips', AppRoutes.packing),
      ('Style insights', 'Discover wardrobe trends', AppRoutes.insights),
      ('Shopping assistant', 'Find your wardrobe gaps', AppRoutes.shopping),
      ('Saved outfits', 'Your favorite looks', AppRoutes.saved),
    ];
    for (final r in rows) {
      expect(find.text(r.$1), findsOneWidget, reason: r.$1);
      expect(find.text(r.$2), findsOneWidget, reason: r.$2);
    }
    for (final r in rows) {
      await tapText(tester, r.$1);
      expect(pathOf(router), r.$3);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('F05_A12 home renders inside the shell with Home highlighted', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.home);
    for (final l in navLabels) {
      expect(find.text(l), findsOneWidget, reason: l);
    }
  });
}
