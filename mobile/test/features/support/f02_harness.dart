import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';

/// Pumps the whole app at 390x844 starting on [location].
///
/// With [fresh] the previous tree is torn down first, so a test that pumps
/// the app more than once gets a new StyloBuddyApp state (new router, new
/// cubits). Default `false`: some suites deliberately keep state across
/// re-pumps (e.g. F08 saved tests).
Future<GoRouter> pumpApp(
  WidgetTester tester,
  String location, {
  bool fresh = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = createAppRouter(initialLocation: location);
  if (fresh) await tester.pumpWidget(const SizedBox());
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

/// F24: `/intro` needs a gender (a fresh shell landing on `/intro` redirects
/// to `/gender`, F24-A20), so F02/F24 tests reach it through the UI:
/// `/welcome` -> Get Started -> [gender] card -> Continue. Lands on slide 1.
Future<GoRouter> pumpIntro(WidgetTester tester, {String gender = 'male'}) async {
  final router = await pumpApp(tester, '/welcome', fresh: true);
  await tapText(tester, 'Get Started');
  await tester.tap(find.byKey(Key('gender-card-$gender')));
  await tester.pumpAndSettle();
  await tapText(tester, 'Continue');
  return router;
}

/// Reaches `/personalize` inside the same onboarding shell as [pumpIntro]
/// (intro 'Skip'), so `‹`/system back to `/intro` keeps the chosen gender.
Future<GoRouter> pumpPersonalize(
  WidgetTester tester, {
  String gender = 'male',
}) async {
  final router = await pumpIntro(tester, gender: gender);
  await tapText(tester, 'Skip');
  return router;
}

const navLabels = ['Home', 'Wardrobe', 'AI Stylist', 'Saved', 'Profile'];
