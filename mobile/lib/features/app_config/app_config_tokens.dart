import 'package:flutter/painting.dart';

import '../../core/theme/app_colors.dart';

/// Colours and spacing for the forced-update screen and notice banners
/// (F25). Derived from the app palette; no prototype screen exists for them.
abstract final class AppConfigTokens {
  static const bannerBackground = AppColors.dark;
  static const bannerInk = AppColors.white;
  static const bannerActionInk = AppColors.white;
  static const bannerPadding = EdgeInsets.fromLTRB(16, 10, 8, 10);
  static const bannerTextSize = 12.5;
  static const bannerActionSize = 12.5;
  static const bannerDismissSize = 15.0;
  static const bannerMaxLines = 3;
  static const bannerGap = 8.0;
  static const bannerDivider = AppColors.green;

  static const updateBackground = AppColors.white;
  static const updatePadding = EdgeInsets.fromLTRB(28, 24, 28, 28);
  static const updateTitleSize = 24.0;
  static const updateBodySize = 14.0;
  static const updateBodyInk = AppColors.muted;
  static const updateErrorInk = Color(0xFFB3261E);
  static const updateErrorSize = 12.5;
  static const updateGapLarge = 28.0;
  static const updateGapSmall = 12.0;
}
