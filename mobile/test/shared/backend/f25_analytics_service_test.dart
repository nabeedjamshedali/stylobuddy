import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/shared/backend/analytics_service.dart';

import '../../support/recording_analytics_sink.dart';

class _ThrowingSink implements AnalyticsSink {
  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) =>
      throw StateError('sync boom');

  @override
  Future<void> logScreenView(String screenName) =>
      throw StateError('sync boom');
}

class _FailingFutureSink implements AnalyticsSink {
  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) =>
      Future<void>.error(StateError('async boom'));

  @override
  Future<void> logScreenView(String screenName) =>
      Future<void>.error(StateError('async boom'));
}

/// Calls every AnalyticsService method once.
void _callEverything(AnalyticsService service) {
  service
    ..screenView('/saved-detail?id=3')
    ..onboardingStarted()
    ..onboardingCompleted(occasionCount: 2)
    ..onboardingSkipped(OnboardingSkipPoint.welcome)
    ..onboardingSkipped(OnboardingSkipPoint.intro, slide: 3)
    ..signedIn(SignInMethod.google)
    ..guestStarted()
    ..outfitGenerated(mode: OutfitGenerationMode.automatic, resultCount: 3)
    ..outfitGenerated(mode: OutfitGenerationMode.match, resultCount: 2)
    ..wardrobeItemsAdded(source: 'camera', itemCount: 3, photoCount: 1)
    ..wardrobeItemsAdded(source: 'Alex secret closet', itemCount: 1, photoCount: 0)
    ..outfitSaved(source: OutfitSaveSource.generated, itemCount: 4)
    ..outfitSaved(source: OutfitSaveSource.builder, itemCount: 2)
    ..paywallViewed();
}

void main() {
  test(
    'F25_A01 event and parameter catalogs are exact and use valid Firebase names',
    () {
      expect(AnalyticsEvents.all, {
        'onboarding_start',
        'onboarding_complete',
        'onboarding_skip',
        'login',
        'guest_start',
        'outfit_generated',
        'wardrobe_items_added',
        'outfit_saved',
        'paywall_view',
      });
      expect(AnalyticsParams.all, {
        'occasion_count',
        'skip_from',
        'slide',
        'method',
        'mode',
        'result_count',
        'source',
        'item_count',
        'photo_count',
      });
      final valid = RegExp(r'^[a-z][a-z0-9_]{0,39}$');
      for (final name in {...AnalyticsEvents.all, ...AnalyticsParams.all}) {
        expect(valid.hasMatch(name), isTrue, reason: name);
        for (final reserved in ['firebase_', 'google_', 'ga_']) {
          expect(name.startsWith(reserved), isFalse, reason: name);
        }
      }
    },
  );

  test('F25_A02 each typed method logs exactly the documented name and parameters', () {
    final r = recordingAnalytics();
    final s = r.service;

    void expectOne(void Function() call, String name, Map<String, Object> params) {
      r.sink.clear();
      call();
      expect(r.sink.calls, hasLength(1));
      expect(r.sink.calls.single.isScreenView, isFalse);
      expect(r.sink.calls.single.name, name);
      expect(r.sink.calls.single.parameters, params);
    }

    expectOne(s.onboardingStarted, 'onboarding_start', {});
    expectOne(
      () => s.onboardingCompleted(occasionCount: 2),
      'onboarding_complete',
      {'occasion_count': 2},
    );
    expectOne(
      () => s.onboardingSkipped(OnboardingSkipPoint.welcome),
      'onboarding_skip',
      {'skip_from': 'welcome'},
    );
    expectOne(
      () => s.onboardingSkipped(OnboardingSkipPoint.welcome, slide: 4),
      'onboarding_skip',
      {'skip_from': 'welcome'},
    );
    expectOne(
      () => s.onboardingSkipped(OnboardingSkipPoint.intro, slide: 3),
      'onboarding_skip',
      {'skip_from': 'intro', 'slide': 3},
    );
    expectOne(() => s.signedIn(SignInMethod.google), 'login', {'method': 'google'});
    expectOne(s.guestStarted, 'guest_start', {});
    expectOne(
      () => s.outfitGenerated(mode: OutfitGenerationMode.match, resultCount: 2),
      'outfit_generated',
      {'mode': 'match', 'result_count': 2},
    );
    expectOne(
      () => s.outfitSaved(source: OutfitSaveSource.builder, itemCount: 4),
      'outfit_saved',
      {'source': 'builder', 'item_count': 4},
    );
    expectOne(s.paywallViewed, 'paywall_view', {});
  });

  test('F25_A03 wardrobeItemsAdded passes camera/gallery through and clamps anything else to other', () {
    final r = recordingAnalytics();
    for (final source in ['camera', 'gallery']) {
      r.sink.clear();
      r.service.wardrobeItemsAdded(source: source, itemCount: 3, photoCount: 1);
      expect(r.sink.calls.single.name, 'wardrobe_items_added');
      expect(r.sink.calls.single.parameters, {
        'source': source,
        'item_count': 3,
        'photo_count': 1,
      });
    }
    for (final source in ['Camera', '', 'my closet', 'gallery ']) {
      r.sink.clear();
      r.service.wardrobeItemsAdded(source: source, itemCount: 2, photoCount: 0);
      final params = r.sink.calls.single.parameters;
      expect(params['source'], 'other', reason: source);
      expect(params['item_count'], isA<int>());
      expect(params['photo_count'], isA<int>());
    }
  });

  test('F25_A04 privacy: every logged key is catalogued and every value is an int or a fixed wire string', () {
    final r = recordingAnalytics();
    _callEverything(r.service);
    const wireStrings = {
      'welcome',
      'intro',
      'google',
      'automatic',
      'match',
      'camera',
      'gallery',
      'other',
      'generated',
      'builder',
    };
    expect(r.sink.events, isNotEmpty);
    for (final call in r.sink.events) {
      for (final entry in call.parameters.entries) {
        expect(AnalyticsParams.all, contains(entry.key), reason: '$call');
        for (final banned in ['gender', 'name', 'email', 'uid']) {
          expect(entry.key.contains(banned), isFalse, reason: '$call');
        }
        expect(entry.key == 'id' || entry.key.endsWith('_id'), isFalse);
        final value = entry.value;
        expect(
          value is int || (value is String && wireStrings.contains(value)),
          isTrue,
          reason: '$call',
        );
      }
    }
  });

  test('F25_A05 screenNameFor normalizes paths and drops query and fragment', () {
    expect(screenNameFor('/home'), 'home');
    expect(screenNameFor('/saved-detail?id=3'), 'saved_detail');
    expect(screenNameFor('/wear-detail?id=1&outfitId=2'), 'wear_detail');
    expect(screenNameFor('/not-found'), 'not_found');
    expect(screenNameFor(''), 'unknown');
    expect(screenNameFor('/'), 'unknown');
    expect(screenNameFor('/Home'), 'unknown');
    expect(screenNameFor('/a/b'), 'unknown');
    expect(screenNameFor('home'), 'unknown');
    expect(screenNameFor('/home#x'), 'home');
  });

  test('F25_A06 screenView logs one screen view with the normalized name and no event', () {
    final r = recordingAnalytics();
    r.service.screenView('/saved-detail?id=3');
    expect(r.sink.calls, hasLength(1));
    expect(r.sink.calls.single.isScreenView, isTrue);
    expect(r.sink.calls.single.name, 'saved_detail');
    expect(r.sink.events, isEmpty);
  });

  test('F25_A07 a throwing or failing sink never breaks the caller', () async {
    final uncaught = <Object>[];
    await runZonedGuarded(() async {
      _callEverything(AnalyticsService(_ThrowingSink()));
      _callEverything(AnalyticsService(_FailingFutureSink()));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }, (error, _) => uncaught.add(error));
    expect(uncaught, isEmpty);
  });

  testWidgets('F25_A08 analyticsOf returns the provided service, or a no-op one when none is provided', (
    tester,
  ) async {
    final provided = AnalyticsService(RecordingAnalyticsSink());
    late AnalyticsService insideProvider;
    late AnalyticsService withoutProvider;
    await tester.pumpWidget(
      Column(
        textDirection: TextDirection.ltr,
        children: [
          RepositoryProvider<AnalyticsService>.value(
            value: provided,
            child: Builder(
              builder: (context) {
                insideProvider = analyticsOf(context);
                return const SizedBox();
              },
            ),
          ),
          Builder(
            builder: (context) {
              withoutProvider = analyticsOf(context);
              return const SizedBox();
            },
          ),
        ],
      ),
    );
    expect(identical(insideProvider, provided), isTrue);
    expect(withoutProvider.sink, isA<NoopAnalyticsSink>());
  });
}
