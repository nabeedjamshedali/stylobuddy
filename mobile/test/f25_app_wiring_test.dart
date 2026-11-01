import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';
import 'package:stylobuddy/features/profile/widgets/pf_premium_banner.dart';
import 'package:stylobuddy/shared/backend/analytics_service.dart';
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';
import 'package:stylobuddy/shared/backend/remote_config_service.dart';
import 'package:stylobuddy/shared/models/app_config.dart';

import 'support/fake_remote_config.dart';
import 'support/recording_analytics_sink.dart';

/// F25 integration: the real StyloBuddyApp with a recording analytics sink
/// and scripted Remote Config, no Firebase app initialized.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required RecordingAnalyticsSink sink,
  String location = '/welcome',
  RemoteConfigService? remoteConfig,
  Future<String?> Function()? installedVersion,
  Future<bool> Function()? openStore,
  Stream<String?>? uidStream,
  FakeFirebaseFirestore? firestore,
  bool overrideRouter = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    StyloBuddyApp(
      router: overrideRouter ? router : null,
      analytics: AnalyticsService(sink),
      remoteConfig: remoteConfig,
      installedVersion: installedVersion,
      openStore: openStore,
      uidStream: uidStream,
      firestoreOverride: firestore,
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void _expectNoGender(RecordingAnalyticsSink sink) {
  for (final call in sink.calls) {
    for (final entry in call.parameters.entries) {
      expect(entry.key.contains('gender'), isFalse, reason: '$call');
      expect(entry.value, isNot(anyOf('male', 'female')), reason: '$call');
    }
  }
}

void main() {
  setUp(PendingOnboardingSelections.clear);
  tearDown(PendingOnboardingSelections.clear);

  testWidgets(
    'F25_A40 onboarding walk logs screen views and funnel events in order, never the gender',
    (tester) async {
      final sink = RecordingAnalyticsSink();
      await _pump(tester, sink: sink);
      expect(sink.timeline, ['screen:welcome']);

      await _tapText(tester, 'Get Started');
      await tester.tap(find.byKey(const Key('gender-card-male')));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Continue');
      await _tapText(tester, 'Get Started');
      for (var i = 0; i < 3; i++) {
        await _tapText(tester, 'Continue');
      }
      await _tapText(tester, 'Create My Wardrobe');

      expect(sink.timeline, [
        'screen:welcome',
        'onboarding_start',
        'screen:gender',
        'screen:intro',
        'onboarding_complete',
        'screen:personalize',
      ]);
      expect(sink.named('onboarding_complete').single.parameters, {
        'occasion_count': 0,
      });
      _expectNoGender(sink);
    },
  );

  testWidgets(
    'F25_A41 Skip introduction and Skip for now log their events before the next screen',
    (tester) async {
      final sink = RecordingAnalyticsSink();
      await _pump(tester, sink: sink);
      await _tapText(tester, 'Skip introduction');
      await _tapText(tester, 'Skip for now');
      expect(sink.timeline, [
        'screen:welcome',
        'onboarding_skip',
        'screen:auth',
        'guest_start',
        'screen:home',
      ]);
      expect(sink.named('onboarding_skip').single.parameters, {
        'skip_from': 'welcome',
      });
    },
  );

  testWidgets(
    'F25_A42 the Premium banner logs premium + paywall_view; screen views survive a uid flip without duplicates',
    (tester) async {
      final sink = RecordingAnalyticsSink();
      final uid = StreamController<String?>();
      addTearDown(uid.close);
      final router = await _pump(
        tester,
        sink: sink,
        location: '/profile',
        uidStream: uid.stream,
        firestore: FakeFirebaseFirestore(),
      );
      expect(sink.screens, ['profile']);

      await tester.ensureVisible(find.byType(PfPremiumBanner));
      await tester.tap(find.byType(PfPremiumBanner));
      await tester.pumpAndSettle();
      expect(sink.timeline.sublist(1), ['screen:premium', 'paywall_view']);

      router.go('/home');
      await tester.pumpAndSettle();
      uid.add('uid-1');
      await tester.pumpAndSettle();
      sink.clear();
      router.go('/saved');
      await tester.pumpAndSettle();
      expect(sink.screens, ['saved'], reason: 'exactly one tracker attached');
    },
  );

  testWidgets(
    'F25_A42 app-built routers: a sign-in subtree attaches a fresh tracker that logs home',
    (tester) async {
      final sink = RecordingAnalyticsSink();
      final uid = StreamController<String?>();
      addTearDown(uid.close);
      await _pump(
        tester,
        sink: sink,
        uidStream: uid.stream,
        firestore: FakeFirebaseFirestore(),
        overrideRouter: false,
      );
      expect(sink.screens, ['welcome']);
      uid.add('uid-1');
      await tester.pumpAndSettle();
      expect(sink.screens, ['welcome', 'home']);
    },
  );

  testWidgets(
    'F25_A43 a cached min_supported_version above the installed version blocks the app; Update now opens the store',
    (tester) async {
      var storeCalls = 0;
      await _pump(
        tester,
        sink: RecordingAnalyticsSink(),
        remoteConfig: FakeRemoteConfig(
          initial: AppConfig.defaults.copyWith(minSupportedVersion: '9.0.0'),
        ),
        installedVersion: () async => '1.0.0',
        openStore: () async {
          storeCalls++;
          return true;
        },
      );
      expect(find.byKey(const Key('update-required-view')), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
      await tester.tap(find.text('Update now'));
      await tester.pumpAndSettle();
      expect(storeCalls, 1);
      expect(find.byKey(const Key('update-required-view')), findsOneWidget);
    },
  );

  testWidgets(
    'F25_A30 Android Back under the forced-update screen does not pop the hidden app stack',
    (tester) async {
      final router = await _pump(
        tester,
        sink: RecordingAnalyticsSink(),
        remoteConfig: FakeRemoteConfig(
          initial: AppConfig.defaults.copyWith(minSupportedVersion: '9.0.0'),
        ),
        installedVersion: () async => '1.0.0',
      );
      expect(find.byKey(const Key('update-required-view')), findsOneWidget);

      unawaited(router.push('/personalize'));
      await tester.pumpAndSettle();
      String here() =>
          router.routerDelegate.currentConfiguration.last.matchedLocation;
      expect(here(), '/personalize');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(here(), '/personalize', reason: 'Back must not pop the hidden app');
      expect(find.byKey(const Key('update-required-view')), findsOneWidget);
    },
  );

  testWidgets(
    'F25_A43 default config renders Welcome unchanged; a maintenance message shows a banner above a working app',
    (tester) async {
      final router = await _pump(tester, sink: RecordingAnalyticsSink());
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byKey(const Key('update-required-view')), findsNothing);
      expect(find.byKey(const Key('maintenance-banner')), findsNothing);
      expect(find.byKey(const Key('update-nudge-banner')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      final router2 = await _pump(
        tester,
        sink: RecordingAnalyticsSink(),
        remoteConfig: FakeRemoteConfig(
          initial: AppConfig.defaults.copyWith(maintenanceMessage: 'Back at 9'),
        ),
      );
      expect(find.byKey(const Key('maintenance-banner')), findsOneWidget);
      expect(find.text('Back at 9'), findsOneWidget);
      await _tapText(tester, 'Get Started');
      expect(
        router2.routerDelegate.currentConfiguration.last.matchedLocation,
        '/gender',
      );
      expect(router, isNot(same(router2)));
    },
  );
}
