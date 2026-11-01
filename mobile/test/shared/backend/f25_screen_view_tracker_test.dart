import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/shared/backend/analytics_service.dart';
import 'package:stylobuddy/shared/backend/screen_view_tracker.dart';

import '../../support/recording_analytics_sink.dart';

GoRouter _router() {
  GoRoute page(String path) => GoRoute(
    path: path,
    builder: (context, state) => Scaffold(body: Text(path)),
  );
  return GoRouter(
    initialLocation: '/home',
    errorBuilder: (context, state) => const Scaffold(body: Text('error')),
    routes: [
      page('/home'),
      // A shell route, like the real app's, to prove nested navigators are seen.
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          page('/saved-detail'),
          page('/premium'),
          page('/plan'),
          page('/purchase'),
          page('/subscription'),
        ],
      ),
    ],
  );
}

Future<({GoRouter router, ScreenViewTracker tracker, RecordingAnalyticsSink sink})>
_pump(WidgetTester tester) async {
  final router = _router();
  final sink = RecordingAnalyticsSink();
  final tracker = ScreenViewTracker(router, AnalyticsService(sink))..attach();
  addTearDown(() {
    tracker.detach();
    router.dispose();
  });
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return (router: router, tracker: tracker, sink: sink);
}

void main() {
  testWidgets(
    'F25_A10 go/push/pop log screen views in order, duplicates collapse, unknown routes log not_found, detach stops logging',
    (tester) async {
      final t = await _pump(tester);
      expect(t.sink.screens, ['home']);

      t.router.go('/home');
      await tester.pumpAndSettle();
      expect(t.sink.screens, ['home']);

      t.router.push('/saved-detail?id=1');
      await tester.pumpAndSettle();
      t.router.pop();
      await tester.pumpAndSettle();
      expect(t.sink.screens, ['home', 'saved_detail', 'home']);

      t.router.go('/no-such-page');
      await tester.pumpAndSettle();
      expect(t.sink.screens.last, 'not_found');

      t.tracker.detach();
      t.sink.clear();
      t.router.go('/plan');
      await tester.pumpAndSettle();
      expect(t.sink.calls, isEmpty);
    },
  );

  testWidgets(
    'F25_A11 paywall_view fires once per arrival on /premium and never for /plan, /purchase or /subscription',
    (tester) async {
      final t = await _pump(tester);
      int paywalls() => t.sink.named('paywall_view').length;

      t.router.go('/premium');
      await tester.pumpAndSettle();
      expect(paywalls(), 1);

      t.router.push('/plan');
      await tester.pumpAndSettle();
      expect(paywalls(), 1);

      t.router.pop();
      await tester.pumpAndSettle();
      expect(paywalls(), 2);

      for (final path in ['/plan', '/purchase', '/subscription']) {
        t.router.go(path);
        await tester.pumpAndSettle();
      }
      expect(paywalls(), 2);
      expect(t.sink.screens, [
        'home',
        'premium',
        'plan',
        'premium',
        'plan',
        'purchase',
        'subscription',
      ]);
    },
  );
}
