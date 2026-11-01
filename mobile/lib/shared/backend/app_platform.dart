import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store listing for the update button (F25). Android only for now: iOS
/// needs an App Store id that does not exist yet (F25 §3).
abstract final class StoreListing {
  /// `applicationId` in `android/app/build.gradle.kts`.
  static const androidPackageId = 'com.stylobuddy.stylobuddy';

  static final Uri marketUri = Uri.parse(
    'market://details?id=$androidPackageId',
  );

  static final Uri playStoreWebUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$androidPackageId',
  );
}

/// Opens the Play Store app on the listing, falling back to the web
/// listing. Returns whether either opened. Never throws. Always `false` off
/// Android.
Future<bool> openStoreListing() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
  for (final uri in [StoreListing.marketUri, StoreListing.playStoreWebUri]) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('openStoreListing: $uri failed: $error');
    }
  }
  return false;
}

/// The running build's `versionName` (e.g. `1.0.0`), or `null` if the
/// platform cannot report it. Never throws.
Future<String?> readInstalledVersion() async {
  try {
    final version = (await PackageInfo.fromPlatform()).version.trim();
    return version.isEmpty ? null : version;
  } catch (error) {
    if (kDebugMode) debugPrint('readInstalledVersion failed: $error');
    return null;
  }
}
