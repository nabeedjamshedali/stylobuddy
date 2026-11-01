import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/backend/analytics_service.dart';
import 'shared/backend/app_platform.dart';
import 'shared/backend/firebase_analytics_sink.dart';
import 'shared/backend/firebase_remote_config_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // F25: Analytics and Remote Config. Neither is awaited here: the Remote
  // Config fetch runs inside AppConfigCubit.load() after the first frame.
  runApp(
    StyloBuddyApp(
      analytics: AnalyticsService(
        FirebaseAnalyticsSink(FirebaseAnalytics.instance),
      ),
      remoteConfig: FirebaseRemoteConfigService(FirebaseRemoteConfig.instance),
      installedVersion: readInstalledVersion,
      openStore: openStoreListing,
    ),
  );
}
