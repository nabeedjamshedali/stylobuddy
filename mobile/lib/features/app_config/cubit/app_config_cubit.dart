import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/backend/remote_config_service.dart';
import '../../../shared/models/app_config.dart';
import 'app_config_state.dart';

/// Startup Remote Config load, forced-update gate, update nudge and
/// maintenance notice (F25 §2.2-2.3). Created once per app process by
/// `StyloBuddyApp` (above the uid-keyed subtree), so it survives sign-in and
/// sign-out.
class AppConfigCubit extends Cubit<AppConfigState> {
  AppConfigCubit({
    required this._remoteConfig,
    Future<String?> Function()? installedVersion,
    Future<bool> Function()? openStore,
    this._fetchTimeout = AppConfigCubit.fetchTimeout,
  }) : _installedVersion = installedVersion ?? _unknownVersion,
       _openStore = openStore ?? _cannotOpenStore,
       super(const AppConfigState());

  /// Upper bound on the startup fetch; on expiry the activated values stay.
  static const fetchTimeout = Duration(seconds: 8);

  final RemoteConfigService _remoteConfig;
  final Future<String?> Function() _installedVersion;
  final Future<bool> Function() _openStore;
  final Duration _fetchTimeout;
  bool _loadStarted = false;

  static Future<String?> _unknownVersion() async => null;
  static Future<bool> _cannotOpenStore() async => false;

  /// Runs once per Cubit: reads the installed version, emits the activated
  /// values from `initialize()` (so a previously fetched floor applies
  /// immediately), then emits the fetched values if `refresh()` succeeds
  /// within [fetchTimeout]. Never throws; a failed or slow fetch keeps the
  /// activated values.
  Future<void> load() async {
    if (_loadStarted) return;
    _loadStarted = true;

    final installed = await _readInstalledVersion();
    final activated = await _initialize();
    if (isClosed) return;
    emit(state.copyWith(config: activated, installedVersion: installed));

    final fetched = await _refresh();
    if (isClosed) return;
    emit(state.copyWith(config: fetched ?? state.config, loaded: true));
  }

  /// "Update now" / "Update": opens the store listing.
  Future<void> openStore() async {
    bool launched;
    try {
      launched = await _openStore();
    } catch (error) {
      _log('openStore failed', error);
      launched = false;
    }
    if (isClosed) return;
    emit(state.copyWith(storeLaunchFailed: !launched));
  }

  void dismissUpdateNudge() => emit(state.copyWith(updateNudgeDismissed: true));

  void dismissMaintenance() => emit(state.copyWith(maintenanceDismissed: true));

  Future<String?> _readInstalledVersion() async {
    try {
      return await _installedVersion();
    } catch (error) {
      _log('installed version unreadable', error);
      return null;
    }
  }

  Future<AppConfig> _initialize() async {
    try {
      return await _remoteConfig.initialize();
    } catch (error) {
      _log('initialize failed', error);
      return AppConfig.defaults;
    }
  }

  Future<AppConfig?> _refresh() async {
    try {
      return await _remoteConfig.refresh().timeout(_fetchTimeout);
    } on TimeoutException {
      _log('refresh timed out', _fetchTimeout);
      return null;
    } catch (error) {
      _log('refresh failed', error);
      return null;
    }
  }

  static void _log(String message, Object detail) {
    if (kDebugMode) {
      debugPrint('AppConfigCubit: $message: $detail');
    }
  }
}
