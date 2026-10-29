import 'dart:async';

import 'package:stylobuddy/shared/backend/remote_config_service.dart';
import 'package:stylobuddy/shared/models/app_config.dart';

/// Scriptable [RemoteConfigService] that counts calls.
class FakeRemoteConfig implements RemoteConfigService {
  FakeRemoteConfig({
    this.initial = AppConfig.defaults,
    this.fetched,
    this.refreshThrows = false,
    this.refreshNeverCompletes = false,
  });

  AppConfig initial;
  AppConfig? fetched;
  bool refreshThrows;
  bool refreshNeverCompletes;
  int initializeCalls = 0;
  int refreshCalls = 0;

  @override
  Future<AppConfig> initialize() async {
    initializeCalls++;
    return initial;
  }

  @override
  Future<AppConfig?> refresh() {
    refreshCalls++;
    if (refreshNeverCompletes) return Completer<AppConfig?>().future;
    if (refreshThrows) return Future.error(Exception('offline'));
    return Future.value(fetched);
  }
}
