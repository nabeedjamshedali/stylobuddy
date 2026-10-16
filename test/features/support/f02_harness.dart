import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';

/// Pumps the whole app at 390x844 starting on [location].
Future<GoRouter> pumpApp(WidgetTester tester, String location) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = createAppRouter(initialLocation: location);
  await tester.pumpWidget(StyloBuddyApp(router: router));
  await tester.pumpAndSettle();
  return router;
}

String pathOf(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation;

/// Lets a pending AppToast (2200 ms) expire so no timer outlives the test.
Future<void> drainToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

const navLabels = ['Home', 'Wardrobe', 'AI Stylist', 'Saved', 'Profile'];
