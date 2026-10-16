import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/shared/widgets/app_toast.dart';
import 'package:stylobuddy/shared/widgets/garment_image.dart';
import 'package:stylobuddy/shared/widgets/look_board.dart';
import 'package:stylobuddy/shared/widgets/screen_head.dart';
import 'package:stylobuddy/shared/widgets/section_title.dart';

GoRouter _twoPageRouter(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/a',
          builder: (_, _) => const Scaffold(
              body: ScreenHead(title: 'Title A', fallbackRoute: '/b')),
        ),
        GoRoute(
          path: '/b',
          builder: (_, _) => const Scaffold(body: Text('page b')),
        ),
      ],
    );

void main() {
  testWidgets('ScreenHead back goes to fallback when no history',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp.router(routerConfig: _twoPageRouter('/a')));
    expect(find.text('Title A'), findsOneWidget);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
  });

  testWidgets('ScreenHead back pops when history exists', (tester) async {
    final router = _twoPageRouter('/b');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    unawaited(router.push('/a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(find.text('page b'), findsOneWidget);
    expect(find.text('Title A'), findsNothing);
  });

  testWidgets('AppToast shows then disappears after 2200 ms', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));
    AppToast.show(ctx, 'Saved!');
    await tester.pump();
    expect(find.text('Saved!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('Saved!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Saved!'), findsNothing);
  });

  testWidgets('LookBoard renders one GarmentImage per id', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LookBoard(ids: ['white-shirt', 'navy-chinos']),
      ),
    ));
    expect(find.byType(GarmentImage), findsNWidgets(2));
  });

  testWidgets('SectionTitle renders link with arrow', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SectionTitle(
            title: 'Recent',
            linkLabel: 'View all',
            onLink: () => tapped = true),
      ),
    ));
    await tester.tap(find.text('View all →'));
    expect(tapped, isTrue);
  });
}
