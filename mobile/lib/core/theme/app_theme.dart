import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        primary: AppColors.green,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'DMSans',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'DMSans',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'DMSans'),
      dividerColor: AppColors.line,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: AppTextStyles.manrope(size: 18),
      ),
    );
  }
}
