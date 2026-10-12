import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentDeep,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        headlineMedium: AppTextStyles.headline,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.button,
      ),
    );
  }
}
