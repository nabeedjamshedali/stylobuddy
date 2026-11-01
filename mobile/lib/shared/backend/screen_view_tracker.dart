import 'package:go_router/go_router.dart';

import 'analytics_service.dart';

/// Logs a `screen_view` for every distinct router location (F25 §2.1).
///
/// Listens to [GoRouter.routerDelegate] rather than registering a
/// `NavigatorObserver`: observers on `GoRouter.observers` only see the root
/// navigator and miss every route inside a `ShellRoute`, while the delegate
/// notifies on every `go`, `push` and `pop`. Consecutive duplicates collapse
/// (`a -> a` logs once, `a -> b -> a` logs three times). Arriving on
/// `/premium` (the F13 paywall) also logs `paywall_view`.
class ScreenViewTracker {
  ScreenViewTracker(this._router, this._analytics);

  final GoRouter _router;
  final AnalyticsService _analytics;
  String? _lastScreen;
  bool _attached = false;

  static const _notFoundLocation = '/not-found';
  static const _paywallScreen = 'premium';

  void attach() {
    if (_attached) return;
    _attached = true;
    _router.routerDelegate.addListener(_onRouteChanged);
    _onRouteChanged();
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    _router.routerDelegate.removeListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final location = _currentLocation();
    if (location == null) return;
    final screen = screenNameFor(location);
    if (screen == _lastScreen) return;
    _lastScreen = screen;
    _analytics.screenView(location);
    if (screen == _paywallScreen) _analytics.paywallViewed();
  }

  String? _currentLocation() {
    final configuration = _router.routerDelegate.currentConfiguration;
    if (configuration.isError) return _notFoundLocation;
    if (configuration.isEmpty) return null;
    return configuration.last.matchedLocation;
  }
}
