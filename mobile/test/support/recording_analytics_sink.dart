import 'package:stylobuddy/shared/backend/analytics_service.dart';

/// One call that reached an [AnalyticsSink] (F25 tests).
class RecordedAnalyticsCall {
  const RecordedAnalyticsCall.event(this.name, this.parameters)
    : isScreenView = false;

  const RecordedAnalyticsCall.screen(this.name)
    : parameters = const {},
      isScreenView = true;

  final String name;
  final Map<String, Object> parameters;
  final bool isScreenView;

  @override
  String toString() =>
      isScreenView ? 'screen:$name' : 'event:$name$parameters';
}

/// Records every call, in order.
class RecordingAnalyticsSink implements AnalyticsSink {
  final calls = <RecordedAnalyticsCall>[];

  List<RecordedAnalyticsCall> get events =>
      calls.where((c) => !c.isScreenView).toList();

  List<String> get eventNames => events.map((c) => c.name).toList();

  List<String> get screens =>
      calls.where((c) => c.isScreenView).map((c) => c.name).toList();

  /// `screen:<name>` / `event:<name>` labels in call order.
  List<String> get timeline => [
    for (final c in calls) c.isScreenView ? 'screen:${c.name}' : c.name,
  ];

  List<RecordedAnalyticsCall> named(String name) =>
      events.where((c) => c.name == name).toList();

  void clear() => calls.clear();

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {
    calls.add(RecordedAnalyticsCall.event(name, Map.of(parameters)));
  }

  @override
  Future<void> logScreenView(String screenName) async {
    calls.add(RecordedAnalyticsCall.screen(screenName));
  }
}

/// A recording sink wrapped in the service feature code uses.
({RecordingAnalyticsSink sink, AnalyticsService service}) recordingAnalytics() {
  final sink = RecordingAnalyticsSink();
  return (sink: sink, service: AnalyticsService(sink));
}
