import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Where analytics calls end up (F25). Firebase in production
/// (`firebase_analytics_sink.dart`), [NoopAnalyticsSink] everywhere else, a
/// recording fake in tests. Feature code never talks to a sink directly; it
/// calls the typed [AnalyticsService] methods.
abstract interface class AnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object> parameters);

  Future<void> logScreenView(String screenName);
}

/// Does nothing. The default for every test and for any context that has no
/// [AnalyticsService] provided above it.
class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}

/// F25 event names. Every name the app can log is listed here.
abstract final class AnalyticsEvents {
  static const onboardingStart = 'onboarding_start';
  static const onboardingComplete = 'onboarding_complete';
  static const onboardingSkip = 'onboarding_skip';
  static const login = 'login';
  static const guestStart = 'guest_start';
  static const outfitGenerated = 'outfit_generated';
  static const wardrobeItemsAdded = 'wardrobe_items_added';
  static const outfitSaved = 'outfit_saved';
  static const paywallView = 'paywall_view';

  static const all = <String>{
    onboardingStart,
    onboardingComplete,
    onboardingSkip,
    login,
    guestStart,
    outfitGenerated,
    wardrobeItemsAdded,
    outfitSaved,
    paywallView,
  };
}

/// F25 parameter keys. Every key the app can log is listed here.
abstract final class AnalyticsParams {
  static const occasionCount = 'occasion_count';
  static const skipFrom = 'skip_from';
  static const slide = 'slide';
  static const method = 'method';
  static const mode = 'mode';
  static const resultCount = 'result_count';
  static const source = 'source';
  static const itemCount = 'item_count';
  static const photoCount = 'photo_count';

  static const all = <String>{
    occasionCount,
    skipFrom,
    slide,
    method,
    mode,
    resultCount,
    source,
    itemCount,
    photoCount,
  };
}

/// Where onboarding was skipped from. Wire value: [Enum.name].
enum OnboardingSkipPoint { welcome, intro }

/// Real sign-in providers. Only Google is wired (email/password is a demo
/// flow and is deliberately not logged as a sign-in).
enum SignInMethod { google }

/// Which stylist engine produced the outfits.
enum OutfitGenerationMode { automatic, match }

/// Where a newly saved outfit came from.
enum OutfitSaveSource { generated, builder }

/// The import sources `wardrobeItemsAdded` passes through verbatim; anything
/// else is logged as `other`.
const _importSources = {'camera', 'gallery'};
const _otherSource = 'other';

final _screenPath = RegExp(r'^/[a-z0-9-]+$');

/// Maps a router location to the `screen_view` name: `/saved-detail?id=3`
/// becomes `saved_detail`. Query and fragment are dropped (ids never leave
/// the device); anything that is not a single lowercase path segment becomes
/// `unknown`.
String screenNameFor(String location) {
  var path = location;
  final cut = path.indexOf(RegExp('[?#]'));
  if (cut >= 0) path = path.substring(0, cut);
  if (!_screenPath.hasMatch(path)) return 'unknown';
  return path.substring(1).replaceAll('-', '_');
}

/// The only analytics API feature code uses (F25 §2.1).
///
/// Privacy by construction: every method takes enums or integers, so free
/// text (names, emails, outfit names, item names, gender) cannot be logged.
/// Every method is fire-and-forget and never throws: a sink failure is
/// swallowed (debug-only log) so analytics can never break a user action.
class AnalyticsService {
  const AnalyticsService(this.sink);

  const AnalyticsService.noop() : sink = const NoopAnalyticsSink();

  final AnalyticsSink sink;

  /// `screen_view` for a router location (see [screenNameFor]).
  void screenView(String location) {
    final name = screenNameFor(location);
    _guard('screen_view', () => sink.logScreenView(name));
  }

  void onboardingStarted() => _event(AnalyticsEvents.onboardingStart, const {});

  void onboardingCompleted({required int occasionCount}) => _event(
    AnalyticsEvents.onboardingComplete,
    {AnalyticsParams.occasionCount: occasionCount},
  );

  /// [slide] is the 1-based slide number and is only logged for
  /// [OnboardingSkipPoint.intro].
  void onboardingSkipped(OnboardingSkipPoint from, {int? slide}) => _event(
    AnalyticsEvents.onboardingSkip,
    {
      AnalyticsParams.skipFrom: from.name,
      if (from == OnboardingSkipPoint.intro && slide != null)
        AnalyticsParams.slide: slide,
    },
  );

  void signedIn(SignInMethod method) =>
      _event(AnalyticsEvents.login, {AnalyticsParams.method: method.name});

  void guestStarted() => _event(AnalyticsEvents.guestStart, const {});

  void outfitGenerated({
    required OutfitGenerationMode mode,
    required int resultCount,
  }) => _event(AnalyticsEvents.outfitGenerated, {
    AnalyticsParams.mode: mode.name,
    AnalyticsParams.resultCount: resultCount,
  });

  /// [source] is `ImportState.source`; only `camera`/`gallery` pass through,
  /// anything else is logged as `other`.
  void wardrobeItemsAdded({
    required String source,
    required int itemCount,
    required int photoCount,
  }) => _event(AnalyticsEvents.wardrobeItemsAdded, {
    AnalyticsParams.source: _importSources.contains(source)
        ? source
        : _otherSource,
    AnalyticsParams.itemCount: itemCount,
    AnalyticsParams.photoCount: photoCount,
  });

  void outfitSaved({required OutfitSaveSource source, required int itemCount}) =>
      _event(AnalyticsEvents.outfitSaved, {
        AnalyticsParams.source: source.name,
        AnalyticsParams.itemCount: itemCount,
      });

  void paywallViewed() => _event(AnalyticsEvents.paywallView, const {});

  void _event(String name, Map<String, Object> parameters) =>
      _guard(name, () => sink.logEvent(name, parameters));

  void _guard(String name, Future<void> Function() call) {
    try {
      unawaited(
        call().catchError((Object error, StackTrace stackTrace) {
          _log(name, error);
        }),
      );
    } catch (error) {
      _log(name, error);
    }
  }

  static void _log(String name, Object error) {
    if (kDebugMode) {
      debugPrint('AnalyticsService: $name failed: $error');
    }
  }
}

/// The [AnalyticsService] provided above [context] (`StyloBuddyApp` provides
/// one), or a no-op service when none is.
AnalyticsService analyticsOf(BuildContext context) {
  try {
    // `context.read` throws ProviderNotFoundException when absent
    // (RepositoryProvider.of would rethrow it as a FlutterError).
    return context.read<AnalyticsService>();
  } on ProviderNotFoundException {
    return const AnalyticsService.noop();
  }
}
