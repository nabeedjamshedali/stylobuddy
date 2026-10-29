import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

/// [AnalyticsSink] backed by Firebase Analytics (F25). Constructed only in
/// `lib/main.dart`; everything else talks to `AnalyticsService`.
class FirebaseAnalyticsSink implements AnalyticsSink {
  const FirebaseAnalyticsSink(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) =>
      _analytics.logEvent(
        name: name,
        parameters: parameters.isEmpty ? null : parameters,
      );

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);
}
