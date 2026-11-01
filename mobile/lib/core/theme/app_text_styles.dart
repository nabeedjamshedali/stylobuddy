import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography. DM Sans (body) and Manrope (headings) are bundled variable
/// fonts declared in pubspec, so nothing is fetched at runtime.
abstract final class AppTextStyles {
  static TextStyle _style(
    String family, {
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color ?? AppColors.ink,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle dmSans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(
    'DMSans',
    size: size,
    weight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle manrope({
    double size = 14,
    FontWeight weight = FontWeight.w800,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style(
    'Manrope',
    size: size,
    weight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
