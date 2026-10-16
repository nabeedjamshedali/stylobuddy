import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';
import 'package:stylobuddy/core/router/app_routes.dart';

const _navLabels = ['Home', 'Wardrobe', 'AI Stylist', 'Saved', 'Profile'];

void main() {
  group('AppRoutes.tabFor', () {
    test('groups routes like the prototype render()', () {
      expect(AppRoutes.tabFor('/match-select'), AppRoutes.stylist);
      expect(AppRoutes.tabFor('/edit-item'), AppRoutes.wardrobe);
      expect(AppRoutes.tabFor('/wardrobe'), AppRoutes.wardrobe);
      expect(AppRoutes.tabFor('/wear-detail'), AppRoutes.saved);
      expect(AppRoutes.tabFor('/premium'), AppRoutes.profile);
      expect(AppRoutes.tabFor('/calendar'), AppRoutes.home);
    });

    test('ignores query strings', () {
      expect(
        AppRoutes.tabFor(AppRoutes.clothing('white-shirt')),
        AppRoutes.wardrobe,
      );
      expect(AppRoutes.tabFor(AppRoutes.savedDetail(3)), AppRoutes.saved);
    });

    test('helpers build id routes', () {
      expect(AppRoutes.clothing('x'), '/clothing?id=x');
      expect(AppRoutes.savedDetail(2), '/saved-detail?id=2');
      expect(AppRoutes.wearDetail(5), '/wear-detail?id=5');
    });
  });

  group('app shell', () {
    testWidgets('shows five nav labels at /home', (tester) async {
      await tester.pumpWidget(
        StyloBuddyApp(router: createAppRouter(initialLocation: '/home')),
      );
      await tester.pumpAndSettle();
      for (final label in _navLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('shows no nav at /welcome', (tester) async {
      await tester.pumpWidget(StyloBuddyApp(router: createAppRouter()));
      await tester.pumpAndSettle();
      for (final label in _navLabels) {
        expect(find.text(label), findsNothing);
      }
    });

    testWidgets('tapping a tab navigates', (tester) async {
      final router = createAppRouter(initialLocation: '/home');
      await tester.pumpWidget(StyloBuddyApp(router: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/saved');
    });

    testWidgets('system back on a non-home tab goes to /home', (tester) async {
      final router = createAppRouter(initialLocation: '/wardrobe');
      await tester.pumpWidget(StyloBuddyApp(router: router));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
    });

    testWidgets('system back on a pushed drill-down pops normally', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: '/wardrobe');
      await tester.pumpWidget(StyloBuddyApp(router: router));
      await tester.pumpAndSettle();
      unawaited(router.push('/edit-item'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/edit-item',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/wardrobe',
      );
    });

    testWidgets(
      'system back after a flow-reset go() lands on the tab root, not '
      'an app exit',
      (tester) async {
        // Reproduces e.g. edit_item_view/notifications_view: push into a
        // drill-down flow, then `context.go` back to a non-tab-root screen
        // (flattening the stack to one entry with nothing left to pop).
        final router = createAppRouter(initialLocation: '/settings');
        await tester.pumpWidget(StyloBuddyApp(router: router));
        await tester.pumpAndSettle();
        unawaited(router.push('/notifications'));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/notifications',
        );
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.matches.length, 1);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Did not exit the app: landed on settings' tab root (/profile),
        // not stranded and not popped out of the app.
        expect(router.routeInformationProvider.value.uri.path, '/profile');
      },
    );

    testWidgets('placeholder outside the shell has a Material ancestor', (
      tester,
    ) async {
      await tester.pumpWidget(
        StyloBuddyApp(router: createAppRouter(initialLocation: '/no-such')),
      );
      await tester.pumpAndSettle();
      expect(
        find.ancestor(
          of: find.text('Design preview only'),
          matching: find.byType(Material),
        ),
        findsWidgets,
      );
    });

    testWidgets('on /home system back is not intercepted', (tester) async {
      await tester.pumpWidget(
        StyloBuddyApp(router: createAppRouter(initialLocation: '/home')),
      );
      await tester.pumpAndSettle();
      final scope = tester.widget<PopScope>(
        find.byWidgetPredicate((w) => w is PopScope).first,
      );
      expect(scope.canPop, isTrue);
    });

    testWidgets('unknown location shows the generic preview', (tester) async {
      await tester.pumpWidget(
        StyloBuddyApp(
          router: createAppRouter(initialLocation: '/nope-not-real'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Design preview only'), findsOneWidget);
    });
  });
}
